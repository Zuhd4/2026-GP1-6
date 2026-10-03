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


app = Flask(__name__)


# ============================================================
# MODEL
# ============================================================

MODEL_DIR = os.path.join(
    os.path.dirname(__file__),
    "lexia_kid_whisper_sentence_split_final_v1",
)

print("Loading Lexia ASR model...")
print("Model path:", MODEL_DIR)


processor = AutoProcessor.from_pretrained(
    MODEL_DIR,
    local_files_only=True,
)

model = AutoModelForSpeechSeq2Seq.from_pretrained(
    MODEL_DIR,
    local_files_only=True,
)


device = "cuda" if torch.cuda.is_available() else "cpu"

model.to(device)
model.eval()

model.generation_config.language = "english"
model.generation_config.task = "transcribe"
model.generation_config.forced_decoder_ids = None

print("✅ Lexia ASR model loaded")
print("Device:", device)


# ============================================================
# TEXT NORMALIZATION
# ============================================================

def normalize_text(text):

    text = str(text).lower().strip()

    text = re.sub(
        r"[^\w\s]",
        "",
        text,
    )

    text = re.sub(
        r"\s+",
        " ",
        text,
    )

    return text


# ============================================================
# WORD ALIGNMENT
# ============================================================

def align_words(expected_text, recognized_text):

    expected = normalize_text(expected_text).split()
    recognized = normalize_text(recognized_text).split()

    n = len(expected)
    m = len(recognized)

    dp = [
        [0] * (m + 1)
        for _ in range(n + 1)
    ]

    for i in range(n + 1):
        dp[i][0] = i

    for j in range(m + 1):
        dp[0][j] = j


    for i in range(1, n + 1):

        for j in range(1, m + 1):

            if expected[i - 1] == recognized[j - 1]:

                dp[i][j] = dp[i - 1][j - 1]

            else:

                substitution = dp[i - 1][j - 1] + 1
                omission = dp[i - 1][j] + 1
                addition = dp[i][j - 1] + 1

                dp[i][j] = min(
                    substitution,
                    omission,
                    addition,
                )


    alignment = []

    i = n
    j = m


    while i > 0 or j > 0:

        # Correct
        if (
            i > 0
            and j > 0
            and expected[i - 1] == recognized[j - 1]
            and dp[i][j] == dp[i - 1][j - 1]
        ):

            alignment.append({
                "type": "correct",
                "expected": expected[i - 1],
                "recognized": recognized[j - 1],
            })

            i -= 1
            j -= 1


        # Omission
        elif (
            i > 0
            and dp[i][j] == dp[i - 1][j] + 1
        ):

            alignment.append({
                "type": "omission",
                "expected": expected[i - 1],
                "recognized": None,
            })

            i -= 1


        # Substitution
        elif (
            i > 0
            and j > 0
            and dp[i][j] == dp[i - 1][j - 1] + 1
        ):

            alignment.append({
                "type": "substitution",
                "expected": expected[i - 1],
                "recognized": recognized[j - 1],
            })

            i -= 1
            j -= 1


        # Addition
        else:

            alignment.append({
                "type": "addition",
                "expected": None,
                "recognized": recognized[j - 1],
            })

            j -= 1


    alignment.reverse()

    return alignment


# ============================================================
# PAGE SCORE
# ============================================================

def score_page(expected_text, recognized_text):

    alignment = align_words(
        expected_text,
        recognized_text,
    )

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
        normalize_text(expected_text).split()
    )

    errors = (
        substitutions
        + omissions
        + additions
    )


    if expected_words > 0:

        score = (
            1
            - errors / expected_words
        ) * 100

    else:

        score = 0


    score = max(
        0,
        min(100, score),
    )


    return {
        "score": round(score, 2),
        "correct": correct,
        "substitutions": substitutions,
        "omissions": omissions,
        "additions": additions,
        "expected_words": expected_words,
        "alignment": alignment,
    }


# ============================================================
# TRANSCRIBE AUDIO
# ============================================================

def transcribe_audio(audio_path):

    waveform, sr = librosa.load(
        audio_path,
        sr=16000,
        mono=True,
    )

    inputs = processor.feature_extractor(
        waveform,
        sampling_rate=sr,
        return_tensors="pt",
    )

    input_features = inputs.input_features.to(device)


    with torch.no_grad():

        predicted_ids = model.generate(
            input_features,
        )


    text = processor.tokenizer.batch_decode(
        predicted_ids,
        skip_special_tokens=True,
    )[0]


    return text.strip()


# ============================================================
# API
# ============================================================

@app.route(
    "/reading-assessment",
    methods=["POST"],
)
def reading_assessment():

    if "audio" not in request.files:

        return jsonify({
            "error": "No audio file provided."
        }), 400


    expected_text = request.form.get(
        "expected_text",
        "",
    ).strip()


    if not expected_text:

        return jsonify({
            "error": "Expected text is required."
        }), 400


    audio = request.files["audio"]


    temp_file = tempfile.NamedTemporaryFile(
        suffix=".wav",
        delete=False,
    )

    temp_path = temp_file.name
    temp_file.close()


    try:

        audio.save(temp_path)


        # ----------------------------------------
        # ASR
        # ----------------------------------------

        recognized_text = transcribe_audio(
            temp_path
        )


        # ----------------------------------------
        # Reading assessment
        # ----------------------------------------

        result = score_page(
            expected_text,
            recognized_text,
        )


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
                result["substitutions"],

            "omissions":
                result["omissions"],

            "additions":
                result["additions"],

            "expected_words":
                result["expected_words"],

            "alignment":
                result["alignment"],
        })


    finally:

        if os.path.exists(temp_path):
            os.remove(temp_path)


# ============================================================
# RUN SERVER
# ============================================================

if __name__ == "__main__":

  app.run(
    host="0.0.0.0",
    port=5001,
    debug=False,
)