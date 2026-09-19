// /api/chat.js
//
// A serverless function that proxies chat requests to the Anthropic API.
// This is the ONE piece that must run on a server, not in the browser —
// it's the only place your real API key ever exists.
//
// Works on Vercel out of the box (any file under /api/ becomes an endpoint
// at /api/<filename>). For Netlify, see the note in README.md — the code
// below is the same, only the file location and a couple of lines differ.

module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    res.status(500).json({
      error: "Server is missing ANTHROPIC_API_KEY. Set it in your hosting provider's environment variables (see README.md)."
    });
    return;
  }

  try {
    const { system, messages } = req.body || {};

    if (!messages || !Array.isArray(messages)) {
      res.status(400).json({ error: "Request body must include a messages array." });
      return;
    }

    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01"
      },
      body: JSON.stringify({
        model: "claude-sonnet-5",   // a real production model id — see README for other options
        max_tokens: 400,
        system: system || "",
        messages: messages
      })
    });

    const data = await anthropicRes.json();
    res.status(anthropicRes.status).json(data);
  } catch (err) {
    res.status(500).json({ error: "Request to Anthropic failed.", detail: String(err) });
  }
};
