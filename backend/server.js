import express from 'express';
import cors from 'cors';
import 'dotenv/config';

const app = express();
const PORT = process.env.PORT || 3000;

// Allow CORS; in production, set CORS_ORIGIN to a comma-separated list of allowed origins
const corsOrigin = process.env.CORS_ORIGIN || '*';
const corsOptions = {
  origin: corsOrigin === '*' ? true : corsOrigin.split(',').map((s) => s.trim()),
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Title', 'HTTP-Referer'],
};
const corsMiddleware = cors(corsOptions);
app.use(corsMiddleware);
app.options('*', corsMiddleware);

// Lightweight request logger (method, url, content-type)
app.use((req, _res, next) => {
  try {
    const ct = req.headers['content-type'] || '';
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} (${ct})`);
  } catch {}
  next();
});

app.use(express.json({ limit: '1mb' }));

app.get('/health', (req, res) => res.json({ ok: true }));

// Helpful hint for accidental GETs to /assistant from browser
app.get('/assistant', (req, res) => {
  return res
    .status(405)
    .json({ error: 'Use POST /assistant with JSON body { messages: [...], model }' });
});

app.post('/assistant', async (req, res) => {
  try {
    const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY?.trim();
    if (!OPENROUTER_API_KEY) {
      return res.status(500).json({ error: 'Missing OPENROUTER_API_KEY' });
    }

    const { messages = [], model } = req.body || {};
    const useModel = (model && String(model)) || process.env.OPENROUTER_MODEL || 'openai/gpt-4o-mini';

    const r = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        ...(process.env.OPENROUTER_REFERER ? { 'HTTP-Referer': process.env.OPENROUTER_REFERER } : {}),
        ...(process.env.OPENROUTER_TITLE ? { 'X-Title': process.env.OPENROUTER_TITLE } : {}),
      },
      body: JSON.stringify({ model: useModel, messages }),
    });

    const data = await r.json();
    if (!r.ok) {
      return res.status(r.status).json({ error: data?.error || data });
    }

    const reply = data?.choices?.[0]?.message?.content ?? data?.reply ?? '';
    return res.json({ reply });
  } catch (err) {
    console.error('Assistant proxy error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
});

// Express JSON parse error handler for invalid JSON bodies
app.use((err, _req, res, next) => {
  if (err instanceof SyntaxError && 'status' in err && (err).status === 400) {
    console.error('Invalid JSON received:', err.message);
    return res.status(400).json({ error: 'Invalid JSON', details: err.message });
  }
  return next(err);
});

app.listen(PORT, () => {
  console.log(`Assistant proxy running on http://localhost:${PORT}/assistant`);
});

