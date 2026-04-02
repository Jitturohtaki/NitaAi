# NitaAI (AI) — Intent Classifier

Detects user intent and returns a category:

- `grocery`
- `food`
- `transport`
- `unknown`

## Setup

Set your Gemini API key:

- PowerShell: `setx GEMINI_API_KEY "YOUR_KEY_HERE"`

Optional:

- `GEMINI_MODEL` (default: `gemini-1.5-flash`)

## Run

From `apps/nitaai_ai/`:

- Interactive: `python chatbot.py`
- One-shot: `python chatbot.py "Book me an Uber to the airport"`

