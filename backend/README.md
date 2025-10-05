# FlowLink Assistant Backend (OpenRouter Proxy)

A tiny Node/Express proxy that forwards chat requests to OpenRouter. Keeps the API key on the server and presents a simple `/assistant` endpoint for the Flutter app.

## Endpoints

- `GET /health` → `{ ok: true }`
- `POST /assistant` → `{ reply: string }`
  - Body (OpenAI-compatible):
    ```json
    {
      "messages": [ { "role": "user", "content": "hi" } ],
      "model": "openai/gpt-4o-mini" // optional; server will use OPENROUTER_MODEL if absent
    }
    ```

## Setup

1. Install Node.js 18+
2. Copy `.env.example` to `.env` and set required values:
   - `OPENROUTER_API_KEY=...` (from https://openrouter.ai/)
   - Optional: `OPENROUTER_MODEL`, `OPENROUTER_REFERER`, `OPENROUTER_TITLE`, `CORS_ORIGIN`, `PORT`
3. Install deps and run

```bash
cd backend
npm install
npm run dev
# Server at http://localhost:3000/assistant
```

## Configure Flutter

Run Flutter passing your local proxy URL:

```bash
flutter run -d edge \
  --dart-define=ASSISTANT_API_URL=http://localhost:3000/assistant \
  --dart-define=ASSISTANT_API_KEY=dev-placeholder \
  --dart-define=ASSISTANT_MODEL=openai/gpt-4o-mini \
  --dart-define=ASSISTANT_TITLE=FlowLink \
  --dart-define=ASSISTANT_REFERER=http://localhost
```

Note: The app sends a placeholder key; the server holds the real OpenRouter key.

## Production Notes

- Restrict CORS (`CORS_ORIGIN`) to your domains.
- Deploy to any Node host (Render, Fly.io, Vercel serverless, etc.).
- Be mindful of rate limits and billing in OpenRouter.
