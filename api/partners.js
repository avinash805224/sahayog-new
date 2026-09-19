// api/partners.js
//
// Same read/write split as api/schemes.js — see the comments there for the
// full explanation of the admin-secret guard and service-role key.

const { createClient } = require("@supabase/supabase-js");

function getServiceClient() {
  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceKey) return null;
  return createClient(url, serviceKey);
}

function isAuthorized(req) {
  const secret = process.env.ADMIN_SECRET;
  if (!secret) return false;
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
        message: "Supabase is not configured yet — add SUPABASE_URL and SUPABASE_ANON_KEY to use real, admin-editable partner data. Falling back to built-in demo partners.",
        partners: []
      });
    }

    try {
      const supabase = createClient(url, anonKey);
      const { data, error } = await supabase.from("partners").select("*").eq("active", true);
      if (error) return res.status(200).json({ configured: true, error: error.message, partners: [] });
      return res.status(200).json({ configured: true, partners: data });
    } catch (err) {
      return res.status(500).json({ configured: true, error: String(err), partners: [] });
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
        const { data, error } = await supabase.from("partners").insert(req.body).select();
        if (error) return res.status(400).json({ error: error.message });
        return res.status(201).json({ partner: data[0] });
      }

      if (req.method === "PUT") {
        const { id, ...updates } = req.body || {};
        if (!id) return res.status(400).json({ error: "Missing 'id' in request body." });
        const { data, error } = await supabase.from("partners").update(updates).eq("id", id).select();
        if (error) return res.status(400).json({ error: error.message });
        return res.status(200).json({ partner: data[0] });
      }

      if (req.method === "DELETE") {
        const id = req.query.id || (req.body && req.body.id);
        if (!id) return res.status(400).json({ error: "Missing 'id' (as a query param or in the body)." });
        const { error } = await supabase.from("partners").update({ active: false }).eq("id", id);
        if (error) return res.status(400).json({ error: error.message });
        return res.status(200).json({ deactivated: id });
      }
    } catch (err) {
      return res.status(500).json({ error: String(err) });
    }
  }

  return res.status(405).json({ error: "Method not allowed" });
};
