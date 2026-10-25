import os
import re
import tempfile

import librosa
import torch
from lexia_reading_scoring import (
    score_page as weighted_score_page,
    score_book,
)

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
        # NEW WEIGHTED READING ASSESSMENT
        # ----------------------------------------------------

        result = weighted_score_page(
            reference_text=expected_text,
            recognized_text=recognized_text,
            insertion_penalty=0.5,
            ignore_immediate_repetitions=True,
        )

        page_score = result["page_score_percent"]

        print(
            "New Weighted Page Score:",
            page_score,
        )

        print(
            "Reading Errors:",
            result["counts"],
        )

        print(
            "Ignored Repetitions:",
            result["ignored_immediate_repetitions"],
        )

               # ----------------------------------------------------
        # SEND RESULT TO FLUTTER
        # ----------------------------------------------------

        counts = result["counts"]

        alignment = []

        for item in result["alignment"]:

            operation = item["operation"]

            # Repeated words are ignored
            if operation == "repetition":
                continue

            # Convert new names to Flutter's old names
            if operation == "deletion":
                operation = "omission"

            elif operation == "insertion":
                operation = "addition"

            alignment.append({
                "type": operation,
                "expected": item["expected"],
                "recognized": item["recognized"],
                "difficulty": item["difficulty"],
                "weight": item["weight"],
                "earned": item["earned"],
            })

        return jsonify({

            "expected_text":
                expected_text,

            "recognized_text":
                recognized_text,

            "page_score":
                page_score,

            "correct":
                counts["correct"],

            "substitutions":
                counts["substitution"],

            "omissions":
                counts["deletion"],

            "additions":
                counts["insertion"],

            "expected_words":
                sum(
                    counts[key]
                    for key in (
                        "correct",
                        "substitution",
                        "deletion",
                    )
                ),

            "alignment":
                alignment,

            # Additional weighted scoring information

"weighted_correct_points":
    result["weighted_correct_points"],

"weighted_total_points":
    result["weighted_total_points"],

# Final earned points after insertion penalties
"earned_points":
    result["earned_points"],

# Maximum available points for this page
"available_points":
    result["available_points"],

"insertion_penalty":
    result["insertion_penalty_per_word"],

"ignored_repetitions":
    result["ignored_immediate_repetitions"],

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
# FINAL BOOK ASSESSMENT API
# ============================================================

@app.route("/book-assessment", methods=["POST"])
def book_assessment():

    try:
        data = request.get_json(silent=True)

        if not isinstance(data, dict):
            return jsonify({
                "error": "A JSON object is required."
            }), 400

        pages = data.get("pages")

        if not isinstance(pages, list) or len(pages) != 3:
            return jsonify({
                "error": "Exactly three page results are required."
            }), 400

        # Require one result for each page: 1, 2, and 3
        if not all(
            isinstance(page, dict)
            and type(page.get("page_number")) is int
            for page in pages
        ):
            return jsonify({
                "error": "Each page must have a valid page_number."
            }), 400

        page_numbers = [page["page_number"] for page in pages]

        if sorted(page_numbers) != [1, 2, 3]:
            return jsonify({
                "error": "Pages 1, 2, and 3 must each appear once."
            }), 400

        # Arrange pages in their correct order
        pages = sorted(
            pages,
            key=lambda page: page["page_number"]
        )

        # Calculate the final book score using the
        # shared scoring module.
        result = score_book(pages)

        print(
            "Final Book Score:",
            result["book_score_percent"]
        )

        return jsonify(result), 200

    except (ValueError, TypeError) as e:
        return jsonify({
            "error": str(e)
        }), 400

    except Exception as e:
        print("Book assessment error:", str(e))

        return jsonify({
            "error": "Unable to calculate book assessment."
        }), 500



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
