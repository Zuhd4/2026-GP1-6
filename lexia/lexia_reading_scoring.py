"""Lexia difficulty-weighted page and three-page book reading assessment.

Loads precomputed word weights from word_weights.json (no online Analyzer calls).
ASR transcripts are estimates of speech, not verified reading performance.
"""

from __future__ import annotations

from dataclasses import dataclass
import json
import math
from pathlib import Path
import re

WORD_WEIGHTS = {"Easy": 1.0, "Medium": 1.5, "Hard": 2.0}
INSERTION_PENALTY = 0.5
WEIGHTS_PATH = Path(__file__).resolve().parent / "word_weights.json"
TOKEN_PATTERN = re.compile(r"[a-z]+(?:'[a-z]+)?", re.IGNORECASE)


def tokenize(text: str) -> list[str]:
    """Ignore punctuation/case while keeping apostrophes in words."""
    return TOKEN_PATTERN.findall(text.lower().replace("’", "'"))


def load_word_weights(path: Path = WEIGHTS_PATH) -> dict[str, dict]:
    """Load and validate precomputed data; fail rather than invent word scores."""
    try:
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Cannot load Lexia word weights from {path}: {exc}") from exc
    if not isinstance(data, dict) or not data:
        raise ValueError("word_weights.json must contain a nonempty word dictionary")
    for word, entry in data.items():
        if not isinstance(word, str) or not word or not isinstance(entry, dict):
            raise ValueError(f"Malformed word weights entry: {word!r}")
        level = entry.get("difficulty")
        score = entry.get("total_score")
        weight = entry.get("weight")
        if level not in WORD_WEIGHTS or isinstance(score, bool) or not isinstance(score, (int, float)):
            raise ValueError(f"Invalid difficulty or total_score for {word!r}")
        expected_level = "Easy" if score <= 5 else "Medium" if score <= 10 else "Hard"
        if level != expected_level or isinstance(weight, bool) or not isinstance(weight, (int, float)) or weight != WORD_WEIGHTS[level]:
            raise ValueError(f"Difficulty/weight mismatch for {word!r}")
    return data


# Loaded once when the server starts; no calls to Flask Analyzer or Render.
WORD_DATA = load_word_weights()


def analyze_word(word: str) -> dict:
    """Return existing precomputed word score or fail for an unknown story word."""
    key = word.strip().lower()
    if key not in WORD_DATA:
        raise KeyError(f"Word {key!r} is absent from word_weights.json; update the JSON before scoring")
    return WORD_DATA[key]


@dataclass(frozen=True)
class _Cell:
    edits: int
    matched_weight: float
    operations: tuple


def _best(candidates: list[_Cell]) -> _Cell:
    # Minimum Levenshtein edits first; when tied, preserve the most weighted matches.
    # Final tie-break prefers a deterministic traversal/order.
    return min(candidates, key=lambda c: (c.edits, -c.matched_weight))


def score_page(
    reference_text: str,
    recognized_text: str,
    *,
    word_weights: dict[str, float] | None = None,
    insertion_penalty: float = INSERTION_PENALTY,
    ignore_immediate_repetitions: bool = True,
) -> dict:
    """Score one page; return per-word matches and separate error counts.

    By default, adjacent repeated spoken words are treated as zero-penalty
    repetitions *during alignment*. This preserves legitimately repeated words
    in the reference text (e.g. "go go") while ignoring extra repetitions.
    This is only a transcript heuristic; audio may be needed for corrections.
    """
    weights = WORD_WEIGHTS if word_weights is None else word_weights
    if insertion_penalty < 0 or any(x <= 0 for x in weights.values()):
        raise ValueError("Weights must be positive and insertion penalty nonnegative")
    expected = tokenize(reference_text)
    heard_original = tokenize(recognized_text)
    if not expected:
        raise ValueError("Reference page has no English words to score")

    # Keep all recognized tokens: pre-removing duplicates would incorrectly
    # erase intended repeats in the original story (e.g. "no no").
    heard = heard_original

    per_word = []
    for word in expected:
        result = analyze_word(word)
        level = result["difficulty"]
        if level not in weights:
            raise ValueError(f"Unknown word difficulty '{level}' for {word}")
        per_word.append({
            "word": word,
            "difficulty": level,
            "difficulty_score": result.get("total_score"),
            "weight": float(result["weight"] if word_weights is None else weights[level]),
        })

    m, n = len(expected), len(heard)
    dp: list[list[_Cell]] = [[_Cell(0, 0.0, ()) for _ in range(n + 1)] for _ in range(m + 1)]
    for i in range(1, m + 1):
        previous = dp[i - 1][0]
        dp[i][0] = _Cell(previous.edits + 1, previous.matched_weight,
                         previous.operations + (("deletion", i - 1, None),))
    for j in range(1, n + 1):
        previous = dp[0][j - 1]
        repeated = ignore_immediate_repetitions and j > 1 and heard[j - 1] == heard[j - 2]
        kind = "repetition" if repeated else "insertion"
        dp[0][j] = _Cell(previous.edits + (0 if repeated else 1), previous.matched_weight,
                         previous.operations + ((kind, None, j - 1),))

    for i in range(1, m + 1):
        for j in range(1, n + 1):
            prev = dp[i - 1][j - 1]
            same = expected[i - 1] == heard[j - 1]
            diagonal = _Cell(prev.edits + (0 if same else 1),
                             prev.matched_weight + (per_word[i - 1]["weight"] if same else 0),
                             prev.operations + ((("correct" if same else "substitution"), i - 1, j - 1),))
            above = dp[i - 1][j]
            deleted = _Cell(above.edits + 1, above.matched_weight,
                            above.operations + (("deletion", i - 1, None),))
            left = dp[i][j - 1]
            repeated = ignore_immediate_repetitions and j > 1 and heard[j - 1] == heard[j - 2]
            kind = "repetition" if repeated else "insertion"
            inserted = _Cell(left.edits + (0 if repeated else 1), left.matched_weight,
                             left.operations + ((kind, None, j - 1),))
            dp[i][j] = _best([diagonal, deleted, inserted])

    rows = []
    counts = {"correct": 0, "substitution": 0, "deletion": 0, "insertion": 0, "repetition": 0}
    earned = 0.0
    repeats_ignored = []
    for operation, i, j in dp[m][n].operations:
        counts[operation] += 1
        if operation == "repetition":
            repeats_ignored.append(heard[j])
        ref = per_word[i] if i is not None else None
        weight = ref["weight"] if ref is not None else None
        if operation == "correct":
            earned += weight
        rows.append({
            "operation": operation,
            "expected": ref["word"] if ref else None,
            "recognized": heard[j] if j is not None else None,
            "difficulty": ref["difficulty"] if ref else None,
            "difficulty_score": ref["difficulty_score"] if ref else None,
            "weight": weight,
            "earned": weight if operation == "correct" else 0.0,
        })

    total = sum(w["weight"] for w in per_word)
    insertion_deduction = insertion_penalty * counts["insertion"]
    earned_after_penalties = max(0.0, min(total, earned - insertion_deduction))
    percentage = round(100 * earned_after_penalties / total, 2)
    return {
        "reference_text": reference_text,
        "recognized_text": recognized_text,
        "page_score_percent": percentage,
        "weighted_correct_points": earned,
        "weighted_total_points": total,
        "earned_points": earned_after_penalties,
        "available_points": total,
        "insertion_penalty_per_word": insertion_penalty,
        "total_insertion_deduction": insertion_deduction,
        "standard_word_accuracy_percent": round(100 * counts["correct"] / m, 2),
        "counts": counts,
        "ignored_immediate_repetitions": repeats_ignored,
        "alignment": rows,
        "note": "Transcript-based practice feedback, subject to ASR errors; self-corrections not reliably detected.",
    }


def score_book(page_results: list[dict]) -> dict:
    """Aggregate the best result for each of exactly three pages of one book.

    Each entry must be a result from score_page() for a different page.
    Callers must choose the best attempt per page and ensure pages 1, 2, 3
    belong to the same book; this function cannot verify page identities.
    """
    if not isinstance(page_results, (list, tuple)) or len(page_results) != 3:
        raise ValueError("A book score requires exactly three page results")

    page_summaries = []
    for page_number, page in enumerate(page_results, start=1):
        if not isinstance(page, dict):
            raise ValueError(f"Page {page_number} must be a scoring result dictionary")
        try:
            earned = page["earned_points"]
            available = page["available_points"]
        except KeyError as exc:
            raise ValueError(f"Page {page_number} is missing {exc.args[0]!r}; use score_page() results") from exc
        if any(isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v) for v in (earned, available)):
            raise ValueError(f"Page {page_number} has invalid points")
        if available <= 0 or earned < 0 or earned > available:
            raise ValueError(f"Page {page_number} has inconsistent earned/available points")
        page_summaries.append({
            "page_number": page_number,
            "earned_points": earned,
            "available_points": available,
            "page_score_percent": round(100 * earned / available, 2),
        })

    earned_total = sum(p["earned_points"] for p in page_summaries)
    available_total = sum(p["available_points"] for p in page_summaries)
    return {
        "book_score_percent": round(100 * earned_total / available_total, 2),
        "earned_points": earned_total,
        "available_points": available_total,
        "pages_scored": 3,
        "pages": page_summaries,
    }


if __name__ == "__main__":
    book_1 = ["Mo is a cow", "Mo can fly", "Mo flies to the moon"]
    page_results = [score_page(sentence, sentence) for sentence in book_1]
    print(json.dumps(score_book(page_results), indent=2))
