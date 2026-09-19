// api/gemini.js
//
// Same purpose as api/chat.js, but talks to Google AI Studio (Gemini) instead
// of Anthropic. Kept as a SEPARATE endpoint (/api/gemini) rather than
// replacing chat.js, so you can use either provider — or offer a fallback
// between them — without losing the Anthropic integration.
//
// Gemini's request/response shape is different from Anthropic's, so this
// function translates both directions:
//   - our {system, messages:[{role,content}]} request  -> Gemini's shape
//   - Gemini's response                                  -> the same
//     {content:[{type:"text", text}]} shape askSahayogAI() already expects,
//     so the frontend needs almost no changes to use this instead of /api/chat.

module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return res.status(500).json({
      error: "Server is missing GEMINI_API_KEY. Add it in your hosting provider's environment variable settings."
    });
  }

  const { system, messages } = req.body || {};
  if (!messages) {
    return res.status(400).json({ error: "Request must include a 'messages' array." });
  }

  // Anthropic-style {role:"user"|"assistant", content:"..."} -> Gemini-style
  // {role:"user"|"model", parts:[{text:"..."}]}
  const contents = messages.map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }]
  }));

  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash"; // override via GEMINI_MODEL env var
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

  try {
    const geminiResponse = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey
      },
      body: JSON.stringify({
        systemInstruction: system ? { parts: [{ text: system }] } : undefined,
        contents: contents
      })
    });

    const data = await geminiResponse.json();

    if (!geminiResponse.ok) {
      return res.status(geminiResponse.status).json({ error: "Gemini API error", details: data });
    }

    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || "";

    // Normalized to match what askSahayogAI() in landing.html already parses —
    // so the frontend can call /api/gemini instead of /api/chat with no other changes.
    return res.status(200).json({ content: [{ type: "text", text: text }] });
  } catch (err) {
    return res.status(500).json({ error: "Could not reach Gemini.", details: String(err) });
  }
}
