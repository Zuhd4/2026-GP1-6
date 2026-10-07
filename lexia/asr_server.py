import os
import re
import tempfile

import librosa
import torch

from flask import Flask, request, jsonify
from transformers import (
    AutoProcessor,
    AutoModelForSpeechSeq2Seq,
)


# ============================================================
# FLASK APP
# ============================================================

app = Flask(__name__)


# ============================================================
# MODEL
# ============================================================

# Fine-tuned Lexia model stored on Hugging Face.
MODEL_REPO_ID = os.environ.get(
    "MODEL_REPO_ID",
    "LexiaGP/lexia-kid-whisper-sentence-split-final-v1",
)

# When deployed to Google Cloud, we will store the Hugging Face
# token securely as an environment variable / secret.
#
# When running locally, if HF_TOKEN is not set, Hugging Face
# will use the token already saved by `hf auth login`.
HF_TOKEN = os.environ.get("HF_TOKEN")


print("Loading Lexia ASR model from Hugging Face...")
print("Model:", MODEL_REPO_ID)


# If an environment token exists, use it.
# Otherwise, use the token saved locally by `hf auth login`.
auth_token = HF_TOKEN if HF_TOKEN else True


# ------------------------------------------------------------
# LOAD PROCESSOR
# ------------------------------------------------------------

processor = AutoProcessor.from_pretrained(
    MODEL_REPO_ID,
    token=auth_token,
)


# ------------------------------------------------------------
# LOAD MODEL
# ------------------------------------------------------------

model = AutoModelForSpeechSeq2Seq.from_pretrained(
    MODEL_REPO_ID,
    token=auth_token,
)


# ------------------------------------------------------------
# DEVICE
# ------------------------------------------------------------

device = (
    "cuda"
    if torch.cuda.is_available()
    else "cpu"
)

model.to(device)
model.eval()


# Whisper generation settings.
model.generation_config.language = "english"
model.generation_config.task = "transcribe"
model.generation_config.forced_decoder_ids = None


print("✅ Lexia ASR model loaded from Hugging Face")
print("Device:", device)


# ============================================================
# HEALTH CHECK
# ============================================================

@app.route("/", methods=["GET"])
def health_check():
    return jsonify({
        "status": "ok",
        "service": "Lexia ASR",
        "model": MODEL_REPO_ID,
        "device": device,
    })


# ============================================================
# TEXT NORMALIZATION
# ============================================================

def normalize_text(text):

    text = str(text).lower().strip()

    # Remove punctuation.
    # We intentionally do NOT expand contractions.
    text = re.sub(
        r"[^\w\s]",
        "",
        text,
    )

    # Remove extra spaces.
    text = re.sub(
        r"\s+",
        " ",
        text,
    )

    return text


# ============================================================
# WORD ALIGNMENT
# ============================================================

def align_words(
    expected_text,
    recognized_text,
):

    expected = normalize_text(
        expected_text
    ).split()

    recognized = normalize_text(
        recognized_text
    ).split()

    n = len(expected)
    m = len(recognized)


    # --------------------------------------------------------
    # LEVENSHTEIN MATRIX
    # --------------------------------------------------------

    dp = [
        [0] * (m + 1)
        for _ in range(n + 1)
    ]


    for i in range(n + 1):
        dp[i][0] = i


    for j in range(m + 1):
        dp[0][j] = j


    # --------------------------------------------------------
    # FILL MATRIX
    # --------------------------------------------------------

    for i in range(
        1,
        n + 1,
    ):

        for j in range(
            1,
            m + 1,
        ):

            if (
                expected[i - 1]
                == recognized[j - 1]
            ):

                dp[i][j] = (
                    dp[i - 1][j - 1]
                )

            else:

                substitution = (
                    dp[i - 1][j - 1]
                    + 1
                )

                omission = (
                    dp[i - 1][j]
                    + 1
                )

                addition = (
                    dp[i][j - 1]
                    + 1
                )

                dp[i][j] = min(
                    substitution,
                    omission,
                    addition,
                )


    # --------------------------------------------------------
    # BACKTRACK
    # --------------------------------------------------------

    alignment = []

    i = n
    j = m


    while i > 0 or j > 0:

        # ----------------------------------------------------
        # CORRECT WORD
        # ----------------------------------------------------

        if (
            i > 0
            and j > 0
            and expected[i - 1]
            == recognized[j - 1]
            and dp[i][j]
            == dp[i - 1][j - 1]
        ):

            alignment.append({
                "type": "correct",
                "expected":
                    expected[i - 1],
                "recognized":
                    recognized[j - 1],
            })

            i -= 1
            j -= 1


        # ----------------------------------------------------
        # OMISSION
        # ----------------------------------------------------

        elif (
            i > 0
            and dp[i][j]
            == dp[i - 1][j] + 1
        ):

            alignment.append({
                "type": "omission",
                "expected":
                    expected[i - 1],
                "recognized":
                    None,
            })

            i -= 1


        # ----------------------------------------------------
        # SUBSTITUTION
        # ----------------------------------------------------

        elif (
            i > 0
            and j > 0
            and dp[i][j]
            == dp[i - 1][j - 1] + 1
        ):

            alignment.append({
                "type": "substitution",
                "expected":
                    expected[i - 1],
                "recognized":
                    recognized[j - 1],
            })

            i -= 1
            j -= 1


        # ----------------------------------------------------
        # ADDITION
        # ----------------------------------------------------

        else:

            alignment.append({
                "type": "addition",
                "expected":
                    None,
                "recognized":
                    recognized[j - 1],
            })

            j -= 1


    alignment.reverse()

    return alignment


# ============================================================
# PAGE SCORE
# ============================================================

def score_page(
    expected_text,
    recognized_text,
):

    alignment = align_words(
        expected_text,
        recognized_text,
    )


    # --------------------------------------------------------
    # COUNT WORD TYPES
    # --------------------------------------------------------

    correct = sum(
        x["type"] == "correct"
        for x in alignment
    )

    substitutions = sum(
        x["type"] == "substitution"
        for x in alignment
    )

    omissions = sum(
        x["type"] == "omission"
        for x in alignment
    )

    additions = sum(
        x["type"] == "addition"
        for x in alignment
    )


    expected_words = len(
        normalize_text(
            expected_text
        ).split()
    )


    errors = (
        substitutions
        + omissions
        + additions
    )


    # --------------------------------------------------------
    # SCORE
    # --------------------------------------------------------

    if expected_words > 0:

        score = (
            1
            - errors / expected_words
        ) * 100

    else:

        score = 0


    # Keep score between 0 and 100.
    score = max(
        0,
        min(
            100,
            score,
        ),
    )


    return {
        "score":
            round(
                score,
                2,
            ),

        "correct":
            correct,

        "substitutions":
            substitutions,

        "omissions":
            omissions,

        "additions":
            additions,

        "expected_words":
            expected_words,

        "alignment":
            alignment,
    }


# ============================================================
# TRANSCRIBE AUDIO
# ============================================================

def transcribe_audio(
    audio_path,
):

    # --------------------------------------------------------
    # LOAD AUDIO
    # --------------------------------------------------------

    waveform, sr = librosa.load(
        audio_path,
        sr=16000,
        mono=True,
    )


    # --------------------------------------------------------
    # AUDIO → WHISPER FEATURES
    # --------------------------------------------------------

    inputs = processor.feature_extractor(
        waveform,
        sampling_rate=sr,
        return_tensors="pt",
    )


    input_features = (
        inputs
        .input_features
        .to(device)
    )


    # --------------------------------------------------------
    # WHISPER INFERENCE
    # --------------------------------------------------------

    with torch.no_grad():

        predicted_ids = model.generate(
            input_features,
        )


    # --------------------------------------------------------
    # TOKEN IDs → TEXT
    # --------------------------------------------------------

    text = (
        processor
        .tokenizer
        .batch_decode(
            predicted_ids,
            skip_special_tokens=True,
        )[0]
    )


    return text.strip()


# ============================================================
# READING ASSESSMENT API
# ============================================================

@app.route(
    "/reading-assessment",
    methods=["POST"],
)
def reading_assessment():

    # --------------------------------------------------------
    # CHECK AUDIO
    # --------------------------------------------------------

    if "audio" not in request.files:

        return jsonify({
            "error":
                "No audio file provided."
        }), 400


    # --------------------------------------------------------
    # GET EXPECTED TEXT
    # --------------------------------------------------------

    expected_text = request.form.get(
        "expected_text",
        "",
    ).strip()


    if not expected_text:

        return jsonify({
            "error":
                "Expected text is required."
        }), 400


    audio = request.files[
        "audio"
    ]


    # --------------------------------------------------------
    # CREATE TEMP WAV FILE
    # --------------------------------------------------------

    temp_file = (
        tempfile
        .NamedTemporaryFile(
            suffix=".wav",
            delete=False,
        )
    )

    temp_path = temp_file.name

    temp_file.close()


    try:

        # ----------------------------------------------------
        # SAVE AUDIO
        # ----------------------------------------------------

        audio.save(
            temp_path
        )


        print(
            "🎤 Audio received"
        )

        print(
            "Expected text:",
            expected_text,
        )


        # ----------------------------------------------------
        # ASR
        # ----------------------------------------------------

        recognized_text = (
            transcribe_audio(
                temp_path
            )
        )


        print(
            "Recognized text:",
            recognized_text,
        )


        # ----------------------------------------------------
        # READING ASSESSMENT
        # ----------------------------------------------------

        result = score_page(
            expected_text,
            recognized_text,
        )


        print(
            "Score:",
            result["score"],
        )


        # ----------------------------------------------------
        # SEND RESULT TO FLUTTER
        # ----------------------------------------------------

        return jsonify({

            "expected_text":
                expected_text,

            "recognized_text":
                recognized_text,

            "page_score":
                result["score"],

            "correct":
                result["correct"],

            "substitutions":
                result[
                    "substitutions"
                ],

            "omissions":
                result[
                    "omissions"
                ],

            "additions":
                result[
                    "additions"
                ],

            "expected_words":
                result[
                    "expected_words"
                ],

            "alignment":
                result[
                    "alignment"
                ],
        })


    except Exception as e:

        print(
            "❌ Reading assessment error:",
            str(e),
        )

        return jsonify({
            "error":
                str(e)
        }), 500


    finally:

        # ----------------------------------------------------
        # DELETE TEMP AUDIO
        # ----------------------------------------------------

        if os.path.exists(
            temp_path
        ):

            os.remove(
                temp_path
            )


# ============================================================
# RUN SERVER
# ============================================================

if __name__ == "__main__":

    # Locally:
    # defaults to port 5001.
    #
    # Google Cloud Run:
    # Google automatically provides the PORT environment
    # variable, so the exact same file works in the cloud.

    port = int(
        os.environ.get(
            "PORT",
            "5001",
        )
    )


    app.run(
        host="0.0.0.0",
        port=port,
        debug=False,
    )
