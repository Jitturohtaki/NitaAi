from __future__ import annotations

import json
import sys

from intent_classifier import GeminiIntentClassifier, keyword_intent_fallback


def detect_user_intent(user_message: str) -> dict:
    """
    Detect user intent using Gemini (preferred) with a keyword fallback.

    Returns a dict with:
      - category: grocery|food|transport|unknown
      - confidence: 0..1
      - source: gemini|keywords
    """
    try:
        classifier = GeminiIntentClassifier()
        result = classifier.classify(user_message)
        return {
            "category": result.category,
            "confidence": result.confidence,
            "source": "gemini",
        }
    except Exception:
        category, confidence = keyword_intent_fallback(user_message)
        return {"category": category, "confidence": confidence, "source": "keywords"}


def main() -> int:
    if len(sys.argv) > 1:
        user_message = " ".join(sys.argv[1:]).strip()
        print(json.dumps(detect_user_intent(user_message), indent=2))
        return 0

    print("Intent classifier (Ctrl+C to exit).")
    while True:
        try:
            user_message = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0

        if not user_message:
            continue
        print(json.dumps(detect_user_intent(user_message), indent=2))


if __name__ == "__main__":
    raise SystemExit(main())

