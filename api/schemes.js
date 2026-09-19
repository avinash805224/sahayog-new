// api/schemes.js
//
// GET  — public, read-only, used by app.html. Uses the anon key, which
//        Row Level Security restricts to active=true rows only.
// POST/PUT/DELETE — admin writes, used by admin.html. These require the
//        SUPABASE_SERVICE_ROLE_KEY (bypasses RLS) AND a matching
//        x-admin-secret header, since the service-role key alone has no
//        concept of "who is calling" — the shared secret is what actually
//        gates write access. This is a basic guard suitable for a demo/
//        small-team admin tool, not a substitute for real user accounts
//        and roles (see README).
//
// If Supabase isn't configured at all, GET returns configured:false so the
// frontend can fall back to its built-in demo data, and writes return a
// clear 501 instead of crashing.

const { createClient } = require("@supabase/supabase-js");

function getServiceClient() {
  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceKey) return null;
  return createClient(url, serviceKey);
}

function isAuthorized(req) {
  const secret = process.env.ADMIN_SECRET;
  if (!secret) return false; // no secret configured = writes disabled by default
  return req.headers["x-admin-secret"] === secret;
}

module.exports = async function handler(req, res) {
  // ---------- READ (public) ----------
  if (req.method === "GET") {
    const url = process.env.SUPABASE_URL;
    const anonKey = process.env.SUPABASE_ANON_KEY;

    if (!url || !anonKey) {
      return res.status(200).json({
        configured: false,
        message: "Supabase is not configured yet — add SUPABASE_URL and SUPABASE_ANON_KEY to use real, admin-editable scheme data. Falling back to built-in demo schemes.",
        schemes: []
      });
    }

    try {
      const supabase = createClient(url, anonKey);
      const { data, error } = await supabase.from("schemes").select("*").eq("active", true);
      if (error) return res.status(200).json({ configured: true, error: error.message, schemes: [] });
      return res.status(200).json({ configured: true, schemes: data });
    } catch (err) {
      return res.status(500).json({ configured: true, error: String(err), schemes: [] });
    }
  }

  // ---------- WRITE (admin only) ----------
  if (["POST", "PUT", "DELETE"].includes(req.method)) {
    const supabase = getServiceClient();
    if (!supabase) {
      return res.status(501).json({ error: "Supabase is not configured (missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY). Admin writes need this — see README." });
    }
    if (!isAuthorized(req)) {
      return res.status(401).json({ error: "Missing or incorrect admin secret. Set ADMIN_SECRET in your environment and send it as the x-admin-secret header." });
    }

    try {
      if (req.method === "POST") {
        const { data, error } = await supabase.from("schemes").insert(req.body).select();
        if (error) return res.status(400).json({ error: error.message });
        return res.status(201).json({ scheme: data[0] });
      }

      if (req.method === "PUT") {
        const { id, ...updates } = req.body || {};
        if (!id) return res.status(400).json({ error: "Missing 'id' in request body." });
        const { data, error } = await supabase.from("schemes").update(updates).eq("id", id).select();
        if (error) return res.status(400).json({ error: error.message });
        return res.status(200).json({ scheme: data[0] });
      }

      if (req.method === "DELETE") {
        const id = req.query.id || (req.body && req.body.id);
        if (!id) return res.status(400).json({ error: "Missing 'id' (as a query param or in the body)." });
        // Soft delete — mark inactive rather than actually deleting, so
        // nothing referencing this scheme (matches, applications) breaks.
        const { error } = await supabase.from("schemes").update({ active: false }).eq("id", id);
        if (error) return res.status(400).json({ error: error.message });
        return res.status(200).json({ deactivated: id });
      }
    } catch (err) {
      return res.status(500).json({ error: String(err) });
    }
  }

  return res.status(405).json({ error: "Method not allowed" });
};
