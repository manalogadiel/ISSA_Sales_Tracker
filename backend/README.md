# ☁️ ISSA Sales Tracker - Gemini AI Proxy (Cloudflare Worker)

This lightweight Cloudflare Worker sits between your Flutter app and the Google Gemini API. It ensures that **your Gemini API key is completely hidden** from users and decompiled APKs.

---

## 🚀 2-Minute Free Setup Guide

### Step 1: Create a Free Cloudflare Account
1. Go to [dash.cloudflare.com](https://dash.cloudflare.com/) and sign up for a free account (no credit card required).
2. On the left sidebar, click **Workers & Pages** $\rightarrow$ **Overview**.
3. Click **Create Application** $\rightarrow$ **Create Worker**.
4. Name it `issa-receipt-scanner` and click **Deploy**.

---

### Step 2: Paste the Worker Code
1. Click **Edit code** on your new Worker.
2. In the code editor on the left, delete everything and paste the entire contents of [`backend/worker.js`](./worker.js).
3. Click **Deploy** at the top right.

---

### Step 3: Add Your Gemini API Key Secret
1. Go back to your Worker settings page (click the back arrow or worker name).
2. Click the **Settings** tab $\rightarrow$ **Variables and Secrets**.
3. Under **Secrets**, click **Add**.
   - **Variable name:** `GEMINI_API_KEY`
   - **Value:** Paste your Google AI Studio API key (starts with `AIzaSy...`).
   - Click **Deploy** / **Save**.

---

### Step 4: Copy Your Worker URL & Paste into the App
1. Your Worker URL will look like:
   ```
   https://issa-receipt-scanner.<your-subdomain>.workers.dev
   ```
2. Open **ISSA Sales Tracker** app $\rightarrow$ Go to **Dashboard** $\rightarrow$ Tap the **Settings** gear icon.
3. Paste this URL into the **AI Scanner Proxy URL** field and tap **Test & Save**.

That's it! Your receipts will now be parsed with ultra-high accuracy using Gemini 1.5 Flash Vision, with 100% security and zero risk of key leakage.
