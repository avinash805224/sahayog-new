# Sahayog — AI-Driven Scheme Matching for Marginalized Entrepreneurs

A prototype built for **Smart India Hackathon 2026**, Problem Statement **SIH26092**
(Ministry of Social Justice and Empowerment).

Sahayog is a bilingual (Hindi/English), voice-first platform that helps entrepreneurs
from marginalized backgrounds — women, rural, disabled, low-income, minority, and
tribal entrepreneurs — discover the government schemes they actually qualify for,
understand why, and get guided help applying.

This is a **static, front-end-only prototype** — plain HTML, CSS, and JavaScript,
no build step, no backend, no database. That means it's simple to run, host, and
share, but it also means the "AI chatbot," "scheme database," and "admin dashboard"
are illustrative demos, not production systems. See **Limitations** below for the
honest version of what's real vs. simulated.

---

## Project structure

```
.
├── index.html              Overview / cover page — start here
├── landing.html            Public-facing landing page (voice welcome, AI chat assistant)
├── app.html                The 12-step app flow: Assessment → ... → Channel Partner → Investment Planner → Revenue Explorer → ... → Dashboard
├── admin.html              A basic admin/scheme-management view (Scheme + Channel Partner management)
├── api/
│   ├── chat.js             Backend proxy to Anthropic (Claude) — keeps the API key server-side
│   ├── gemini.js           Backend proxy to Google AI Studio (Gemini) — alternative provider
│   ├── schemes.js          Reads scheme data from Supabase (optional — falls back to demo data)
│   └── partners.js         Reads Channel Partner data from Supabase (optional — falls back to demo data)
├── supabase/
│   └── schema.sql          Full database schema + seed data for Supabase (optional — see setup section below)
├── assets/
│   ├── scheme-match-logo.svg
│   └── scheme-match-logo-inclusive.svg
├── docs/
│   └── sahayog-chatbot-system-prompt.md   The chatbot's system prompt, as reference
├── .env.example            Template for your API keys — copy to .env.local, never commit the real one
├── .gitignore
├── package.json            Optional convenience: `npm start` runs a local static server
├── vercel.json             Explicit config so Vercel's serverless functions (api/*.js) run correctly
└── README.md                This file
```

Every page links to every other page via a small nav bar at the top, so once
hosted, the whole thing works as a normal multi-page website.

---

## Running it locally in VS Code

No installation or build step is required — these are plain HTML files.

**Option A — VS Code Live Server extension (recommended, easiest):**
1. Open this folder in VS Code (`File → Open Folder…`).
2. Install the **"Live Server"** extension (by Ritwick Dey) from the Extensions panel, if you don't have it.
3. Right-click `index.html` → **"Open with Live Server"**.
4. Your browser opens the site at something like `http://127.0.0.1:5500`.

**Option B — a quick local server via Node (if you have Node.js installed):**
```bash
npx serve .
```
Then open the URL it prints (usually `http://localhost:3000`).

**Option C — just double-click the files:**
You can open `index.html` directly in a browser (`file://…`). Most things will
work, but browsers restrict a few features (like the voice AI's live API call
and some autoplay audio) more strictly on `file://` pages than on a real server —
so Options A or B are recommended for the full experience.

---

## Pushing to GitHub

```bash
cd sahayog-prototype        # this folder
git init
git add .
git commit -m "Initial commit: Sahayog prototype"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo-name>.git
git push -u origin main
```

(Create the empty repository on GitHub first, via "New repository" — don't
initialize it with a README there, since this folder already has one.)

---

## Deploying it

Because this is a static site with no build step, any of these work with
minimal setup:

### Vercel (free, Git-connected) — recommended for this project

Vercel is the best fit here because it runs the `api/*.js` serverless
functions (for the AI chatbot) automatically, alongside the static pages,
with zero extra setup.

**Option A — via the Vercel dashboard (no install needed):**
1. Push this repo to GitHub (above).
2. Go to [vercel.com](https://vercel.com) → **"Add New… → Project"**.
3. Import your GitHub repo.
4. Framework preset: Vercel should auto-detect "Other" — leave build command
   and output directory blank (this project has none; `vercel.json` already
   tells Vercel how to run the `api/` functions).
5. Click **Deploy**. You'll get a live URL like `https://your-repo.vercel.app`
   within about a minute.
6. To make the AI chatbot actually work live (optional — it falls back
   gracefully without this): go to **Project → Settings → Environment
   Variables**, add `ANTHROPIC_API_KEY` (and/or `GEMINI_API_KEY`), then
   **Deployments → ⋯ → Redeploy** so the new variable takes effect.

**Option B — via the Vercel CLI (if you have Node.js installed):**
```bash
npm install -g vercel
cd sahayog-prototype        # this folder
vercel login
vercel                      # deploys a preview
vercel --prod               # deploys to your production URL
```
Add environment variables either in the dashboard (step 6 above) or with:
```bash
vercel env add ANTHROPIC_API_KEY
```

### GitHub Pages (free, simplest — but no AI backend)
1. Push the repo to GitHub (above).
2. Go to the repo's **Settings → Pages**.
3. Under "Build and deployment", set **Source** to "Deploy from a branch",
   branch `main`, folder `/ (root)`.
4. Save. GitHub gives you a URL like `https://<username>.github.io/<repo-name>/`
   within a minute or two.

**Note:** GitHub Pages only serves static files — it cannot run `api/*.js`,
so the chatbot will always use its rule-based fallback there, never the live
AI. Use Vercel or Netlify if you want the real chatbot working.

### Netlify (free, drag-and-drop or Git-connected)
1. Go to [app.netlify.com](https://app.netlify.com) → **"Add new site" → "Deploy manually"**.
2. Drag this whole folder onto the page. Netlify hosts it instantly with a URL.
3. (Optional) Connect it to your GitHub repo instead, for auto-deploys on every push.
4. Netlify also supports the `api/` functions, but needs them in a
   `netlify/functions/` folder with slightly different syntax — if you want
   the chatbot live on Netlify specifically, ask and this can be adapted.

All three give you a live public URL in a couple of minutes, with no server to

manage.

---

## Adding a real backend API (making the AI chatbot fully live)

Right now, the AI chatbot on `landing.html` calls `/api/chat` — a backend
endpoint that's already written for you at `api/chat.js`. It just needs your
own Anthropic API key to actually work once deployed. Here's the process, step
by step.

### 1. Get an Anthropic API key
Go to [console.anthropic.com](https://console.anthropic.com/settings/keys),
sign in, and create a new API key. Copy it somewhere safe — you won't be able
to see it again after this.

### 2. Understand why this needs a backend at all
An API key is a secret. If you put it directly in `landing.html`'s JavaScript,
anyone who views the page source could steal and use it on your bill. That's
why `api/chat.js` exists: your browser calls *that* endpoint, and only
`api/chat.js` (running on the server, never sent to visitors) calls Anthropic
with the real key.

### 3. Never commit your real key to Git
`.env.example` shows the format. Copy it to `.env.local` for local testing:
```bash
cp .env.example .env.local
```
Then edit `.env.local` and paste your real key in. `.env.local` is already
listed in `.gitignore`, so Git will never pick it up.

### 4. Set the environment variable on your hosting provider
This is the step that actually matters for the live site — a local `.env.local`
file only affects your own machine, not what's deployed.

**On Vercel:**
1. Open your project on [vercel.com](https://vercel.com).
2. Go to **Settings → Environment Variables**.
3. Add a new variable: Name = `ANTHROPIC_API_KEY`, Value = your real key.
4. Save, then redeploy (Vercel usually prompts you to redeploy after adding a variable).

**On Netlify:**
1. Open your site on [app.netlify.com](https://app.netlify.com).
2. Go to **Site configuration → Environment variables**.
3. Add `ANTHROPIC_API_KEY` with your real key.
4. Netlify Functions work slightly differently from Vercel's `/api` convention —
   move `api/chat.js` into `netlify/functions/chat.js`, and change the export
   at the bottom to Netlify's format:
   ```js
   exports.handler = async (event) => {
     // same logic, but read event.body instead of req.body,
     // and return { statusCode, body: JSON.stringify(data) }
   };
   ```
   and update the frontend's fetch URL in `landing.html` from `/api/chat` to
   `/.netlify/functions/chat`.

**On GitHub Pages:** this won't work — GitHub Pages only serves static files,
it can't run a server-side function at all. If you want GitHub Pages for
simplicity, you'd need to host `api/chat.js` separately (e.g. as a small
Vercel or Cloudflare Worker project) and point `landing.html`'s fetch URL at
that separate service instead of `/api/chat`.

### 5. Redeploy and test
After setting the environment variable, trigger a new deployment (push a
commit, or use your provider's "redeploy" button). Open the live site,
open `landing.html`, type a message to the chatbot, and check your browser's
Network tab (F12 → Network) for the call to `/api/chat` — it should return a
`200` status with a real AI-generated reply.

### 6. If something goes wrong
- **`500` error, "missing ANTHROPIC_API_KEY"** → the environment variable
  isn't set on your host, or you forgot to redeploy after adding it.
- **`401` from Anthropic** → the key is invalid, expired, or has no credit —
  check the Anthropic console.
- **Still getting the fallback rule-based replies, no error shown** → the
  frontend's `try/catch` silently falls back on any failure by design (see
  `askSahayogAI()` in `landing.html`) — open the browser console to see the
  actual error instead of just the friendly fallback behavior.
- **Cost control**: every message sent to `/api/chat` costs a small amount on
  your Anthropic account. For a public demo, consider adding simple rate
  limiting (e.g. a max number of messages per visitor per day) inside
  `api/chat.js` before it calls Anthropic — this isn't included by default.

---

## Using Google AI Studio (Gemini) instead of, or alongside, Anthropic

The project also includes `api/gemini.js` — the same idea as `api/chat.js`,
but for Google's Gemini models via [Google AI Studio](https://aistudio.google.com).

**1. Get a key** — go to aistudio.google.com → "Get API key".

**2. Add it as an environment variable** named `GEMINI_API_KEY` — locally in
`.env.local` (see `.env.example`), and in your hosting provider's dashboard
the same way you did for `ANTHROPIC_API_KEY` (step 4 in the section above).

**3. Point the frontend at `/api/gemini` instead of `/api/chat`.** In
`landing.html`, find this line inside `askSahayogAI()`:
```js
var response = await fetch("/api/chat", {
```
and change it to:
```js
var response = await fetch("/api/gemini", {
```

That's it — no other frontend changes are needed. `api/gemini.js` translates
both directions: it converts the request into the shape Gemini expects, and
converts Gemini's response back into the exact shape the frontend already
parses, so swapping providers is a one-line change.

**Why a separate file instead of replacing `chat.js`?** Anthropic and Gemini
expect different request/response formats (message roles, system prompt
placement, response structure). Keeping them as two small, separate functions
is easier to read and safer to change than one function with branching logic
for two providers — and it means you can keep both available and switch
anytime without re-deploying new code, just by changing which endpoint the
frontend calls.

**Model choice**: `api/gemini.js` uses `gemini-2.0-flash` by default (fast and
inexpensive, good for a chat assistant). To use a different Gemini model,
change the `model` constant near the top of that file.

---

## Setting up Supabase (real, admin-editable scheme & partner data)

By default, the app runs entirely on the demo data built into `app.html` (6
sample schemes, 10 sample partners) — this works with zero setup. Supabase
is **optional**: it lets you replace that hardcoded data with a real
Postgres database, editable either from `admin.html` itself or Supabase's
own dashboard.

**1. Create a project** — go to [supabase.com](https://supabase.com) →
"New project" (free tier is fine).

**2. Run the schema** — open your project → **SQL Editor** → "New query" →
paste the entire contents of `supabase/schema.sql` from this repo → **Run**.
This creates all the tables (schemes, partners, profiles, matches, saved
schemes, applications, documents, notifications), sets up row-level security
so users only ever see their own data, and seeds the same 6 schemes and 10
partners already built into the app — so nothing changes visually until you
start editing rows yourself.

**3. Get your keys** — Project → **Settings → API**. You need two of them:
- **Project URL** and the **anon public** key — for reading data (safe to
  use in `api/schemes.js` / `api/partners.js`'s GET handlers; row-level
  security keeps this read-only and limited to active rows).
- **`service_role` key** — for admin writes only. This key bypasses row-level
  security entirely, so it's only ever used server-side, never sent to the
  browser, and gated behind the admin password described next.

**4. Choose an admin password** — this is not a Supabase setting, it's a
password you make up yourself, used only to protect the "write" endpoints
from strangers who might stumble onto `/api/schemes` or `admin.html`.

**5. Add all four as environment variables** — `SUPABASE_URL`,
`SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, and `ADMIN_SECRET` — the
same way you added `ANTHROPIC_API_KEY` earlier (locally in `.env.local`, and
in your hosting provider's dashboard for the live site).

**6. That's it** — `app.html` automatically tries `/api/schemes` and
`/api/partners` on load and swaps in real rows if Supabase responds. On
`admin.html`, a banner at the top shows the connection status; enter your
admin password in the box next to it to unlock real saving — from that point
on, adding, disabling, or removing a scheme or partner writes to the actual
database, not just this browser tab. Without the password (or without
Supabase configured at all), the admin page still works exactly as before —
changes just don't persist past a page refresh.

**A note on "Remove"**: nothing is ever hard-deleted from the database by
these endpoints — "Remove" and "Disable" both just set a row's `active`
column to `false` (a soft delete), so nothing that already references a
scheme or partner (a saved match, an in-progress application) silently
breaks. Re-adding a scheme with the same details creates a new row rather
than reviving the old one.

**What Supabase does *not* do here (yet)**: real user accounts. The
phone+OTP flow in `app.html` is still a UI simulation (see Limitations
below) — wiring it to Supabase Auth (which supports real phone-based OTP)
is a natural next step, using the `profiles` table already defined in
`supabase/schema.sql` to store each user's assessment answers. The admin
password described above is a basic shared-secret guard, not a real
authentication system — fine for one admin or a small trusted team, not a
substitute for per-user roles if this ever needs multiple admins with
different permissions.

---

## Limitations — what's real vs. simulated

Being upfront about this matters more than it looking finished:

- **Scheme data** shown throughout (6 sample schemes) is illustrative demo data,
  not a live government database — **unless you set up Supabase** (see above),
  in which case it's real, admin-editable data you control.
- **The AI chatbot** on `landing.html` calls a real Claude model *only when this
  page is viewed inside Claude.ai's artifact environment* (which securely
  provides the API access). Opened as a plain hosted website (GitHub Pages,
  Netlify, Vercel, etc.), that live call will fail — the code detects this and
  falls back to a simpler rule-based demo chatbot automatically, so nothing
  breaks. To make the AI chatbot work on a real deployed site, you need your
  own backend endpoint holding an Anthropic API key and proxying the request —
  never put a real API key in client-side code that ships to a browser.
  `docs/sahayog-chatbot-system-prompt.md` has the full system prompt to reuse
  when you build that backend.
- **The phone + OTP login** on `app.html` is a UI simulation only (demo OTP is
  `1234`) — there's no real SMS provider or backend session behind it.
- **The Investment Planner, Budget Calculator, and Revenue/Profit Simulator**
  on `app.html` do real arithmetic (the EMI, break-even, and allocation math
  is genuine), but the category-based allocation presets and revenue models
  are illustrative starting points, not financial advice — every screen that
  uses them says so explicitly.
- **The Admin Dashboard** (`admin.html`) now genuinely connects to Supabase
  when it's configured — a status banner shows whether it's connected, and
  entering the admin password unlocks real saving (see the Supabase section
  above). Without Supabase configured, or without the password entered, it
  still works exactly as before: changes live only in that browser tab and
  reset on refresh.
- **Multilingual support**: Hindi and English are fully translated throughout.
  Bengali, Marathi, Tamil, and Telugu appear in the language switcher so the
  mechanism is visibly extensible, but say plainly that full translation for
  those four isn't done yet, rather than silently showing broken/English text.
- **SMS/IVR channel**: described as a design note on the Overview page, not
  implemented — it needs real telecom infrastructure (an SMS gateway or IVR
  provider), which is outside the scope of a front-end prototype.

## License / attribution

Built as a hackathon prototype. Scheme data, success stories, and statistics
throughout are illustrative placeholders and should not be treated as real
government information — always verify against official sources before relying
on anything here.
