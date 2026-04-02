from __future__ import annotations

import json
import os
import re
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any, Dict, Literal, Optional, Tuple

IntentCategory = Literal["grocery", "food", "transport", "unknown"]


@dataclass(frozen=True)
class IntentResult:
    category: IntentCategory
    confidence: float
    raw_model_text: str | None = None


class GeminiIntentClassifier:
    """
    Minimal intent classifier that uses the Gemini REST API directly (no SDK required).

    Env vars:
      - GEMINI_API_KEY (required)
      - GEMINI_MODEL (optional, default: gemini-1.5-flash)
    """

    def __init__(
        self,
        *,
        api_key: Optional[str] = None,
        model: Optional[str] = None,
        timeout_s: float = 20.0,
    ) -> None:
        self._api_key = api_key or os.getenv("GEMINI_API_KEY")
        if not self._api_key:
            raise ValueError("Missing GEMINI_API_KEY (set env var or pass api_key=...)")
        self._model = model or os.getenv("GEMINI_MODEL") or "gemini-1.5-flash"
        self._timeout_s = timeout_s

    def classify(self, user_text: str) -> IntentResult:
        user_text = (user_text or "").strip()
        if not user_text:
            return IntentResult(category="unknown", confidence=0.0, raw_model_text=None)

        model_text = self._call_gemini(user_text)
        parsed = _parse_classifier_json(model_text)
        if parsed is None:
            # Model might refuse / return non-JSON. Fall back to deterministic keywords.
            category, confidence = keyword_intent_fallback(user_text)
            return IntentResult(category=category, confidence=confidence, raw_model_text=model_text)

        category, confidence = parsed
        return IntentResult(category=category, confidence=confidence, raw_model_text=model_text)

    def _call_gemini(self, user_text: str) -> str:
        # Note: endpoint format may evolve over time; this matches the widely used Generative Language API.
        url = (
            f"https://generativelanguage.googleapis.com/v1beta/models/"
            f"{self._model}:generateContent?key={self._api_key}"
        )

        prompt = _build_prompt(user_text)
        payload = {
            "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.0,
                "maxOutputTokens": 128,
            },
        }

        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=self._timeout_s) as resp:
                body = resp.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            detail = ""
            try:
                detail = e.read().decode("utf-8", errors="replace")
            except Exception:
                detail = str(e)
            raise RuntimeError(f"Gemini API HTTP error {e.code}: {detail}") from e
        except urllib.error.URLError as e:
            raise RuntimeError(f"Gemini API request failed: {e}") from e

        return _extract_text_from_gemini_response(body)


def keyword_intent_fallback(user_text: str) -> Tuple[IntentCategory, float]:
    """
    Simple deterministic backup classifier.
    Returns (category, confidence).
    """
    t = user_text.lower()

    grocery = [
        "grocery",
        "groceries",
        "supermarket",
        "mart",
        "vegetables",
        "fruits",
        "milk",
        "eggs",
        "bread",
        "rice",
        "dal",
        "atta",
        "flour",
        "soap",
        "detergent",
        "toothpaste",
        "shopping list",
    ]
    food = [
        "food",
        "eat",
        "dinner",
        "lunch",
        "breakfast",
        "snack",
        "restaurant",
        "cafe",
        "pizza",
        "burger",
        "biryani",
        "order",
        "zomato",
        "swiggy",
        "delivery",
    ]
    transport = [
        "transport",
        "cab",
        "taxi",
        "uber",
        "ola",
        "auto",
        "rickshaw",
        "bus",
        "metro",
        "train",
        "flight",
        "ticket",
        "commute",
        "ride",
        "drop",
        "pickup",
    ]

    def has_any(keywords: list[str]) -> bool:
        return any(k in t for k in keywords)

    scores: Dict[IntentCategory, int] = {"grocery": 0, "food": 0, "transport": 0, "unknown": 0}
    scores["grocery"] = sum(1 for k in grocery if k in t)
    scores["food"] = sum(1 for k in food if k in t)
    scores["transport"] = sum(1 for k in transport if k in t)

    best = max(("grocery", "food", "transport"), key=lambda c: scores[c])  # type: ignore[index]
    best_score = scores[best]  # type: ignore[index]
    if best_score == 0:
        return ("unknown", 0.2)

    # Very lightweight "confidence" mapping.
    confidence = min(0.95, 0.55 + (best_score * 0.12))
    return (best, float(confidence))  # type: ignore[return-value]


def _build_prompt(user_text: str) -> str:
    return (
        "Classify the user's intent into ONE category.\n"
        "Allowed categories: grocery, food, transport.\n"
        "If none apply, use unknown.\n\n"
        "Return ONLY valid JSON (no markdown, no extra keys):\n"
        '{"category":"grocery|food|transport|unknown","confidence":0.0}\n\n'
        f"User message: {user_text}"
    )


def _extract_text_from_gemini_response(raw_json: str) -> str:
    try:
        data = json.loads(raw_json)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Gemini API returned non-JSON: {raw_json[:2000]}") from e

    # Common response shape:
    # { "candidates": [ { "content": { "parts": [ {"text": "..."} ] } } ] }
    try:
        candidates = data.get("candidates") or []
        if not candidates:
            raise KeyError("candidates")
        content = candidates[0].get("content") or {}
        parts = content.get("parts") or []
        if not parts:
            raise KeyError("content.parts")
        text = parts[0].get("text")
        if not isinstance(text, str):
            raise KeyError("content.parts[0].text")
        return text.strip()
    except Exception as e:
        raise RuntimeError(f"Unexpected Gemini response shape: {raw_json[:2000]}") from e


_JSON_OBJ_RE = re.compile(r"\{.*\}", re.DOTALL)


def _parse_classifier_json(model_text: str) -> Optional[Tuple[IntentCategory, float]]:
    if not model_text:
        return None

    # Strip code fences if the model returns them.
    cleaned = model_text.strip()
    cleaned = cleaned.removeprefix("```json").removeprefix("```").removesuffix("```").strip()

    m = _JSON_OBJ_RE.search(cleaned)
    if not m:
        return None

    try:
        obj = json.loads(m.group(0))
    except json.JSONDecodeError:
        return None

    category = obj.get("category")
    confidence = obj.get("confidence")

    if category not in ("grocery", "food", "transport", "unknown"):
        return None
    try:
        conf_f = float(confidence)
    except (TypeError, ValueError):
        return None

    conf_f = max(0.0, min(1.0, conf_f))
    return category, conf_f  # type: ignore[return-value]

