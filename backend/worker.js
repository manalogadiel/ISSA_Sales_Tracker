/**
 * Cloudflare Worker: Receipt Scanner Proxy for ISSA Sales Tracker
 *
 * Hides your Google Gemini API key from client applications.
 * Accepts receipt image data, forwards it to Gemini 1.5 Flash Vision,
 * and returns structured JSON with extracted inventory items.
 *
 * Cloudflare Environment Variable Required:
 * - GEMINI_API_KEY: Your Google AI Studio API key (stored as a secret)
 */

export default {
  async fetch(request, env, ctx) {
    // 1. Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Content-Type": "application/json",
    };

    // Only allow POST
    if (request.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed. Send a POST request." }),
        { status: 405, headers: corsHeaders }
      );
    }

    // Check for API key in environment
    const apiKey = env.GEMINI_API_KEY;
    if (!apiKey) {
      return new Response(
        JSON.stringify({
          error:
            "GEMINI_API_KEY is not configured in Cloudflare Worker environment variables.",
        }),
        { status: 500, headers: corsHeaders }
      );
    }

    try {
      const body = await request.json();
      const { imageBase64, mimeType = "image/jpeg", catalog = [] } = body;

      if (!imageBase64) {
        return new Response(
          JSON.stringify({ error: "Missing required 'imageBase64' field." }),
          { status: 400, headers: corsHeaders }
        );
      }

      // 2. Prepare the Prompt for Gemini 1.5 Flash
      const catalogListStr = catalog.length > 0
        ? catalog.map((c) => `- ${c}`).join("\n")
        : [
            "- Garlic Pork Longganisa",
            "- Sweet Pork Longganisa",
            "- Sweet & Spicy Pork Longganisa",
            "- Chicken Longganisa",
            "- Spicy Chicken Longganisa",
            "- Chicken Hamonado",
            "- Pork Tapa",
            "- Pork Hamonado",
            "- Pork Tocino",
          ].join("\n");

      const promptText = `You are a precise receipt parser for a Philippine meat business.
Analyze this receipt image and extract purchased meat products matching the ALLOWED CATALOG below.

ALLOWED CATALOG:
${catalogListStr}

EXTRACTION RULES:
1. ONLY extract items that match one of the products in the ALLOWED CATALOG (match flexibly even if receipt has minor typos, abbreviations, or fold creases, but map to the EXACT catalog product name).
2. For each item:
   - "productName": Exact product name from the allowed catalog.
   - "quantity": Quantity in kg as a float (e.g. 5.0, 2.0). If receipt says "3000 x" or "3.000", convert to 3.0 kg. If missing, default to 1.0.
   - "costPrice": The UNIT price per kg in Philippine Pesos (₱) as a float (e.g. 235.0). DO NOT return the line subtotal amount; return the unit rate.
3. Ignore store headers, dates, cashier names, transaction IDs, tax, total amounts, cash, and change lines.
4. If an item on the receipt is NOT in the allowed catalog, do NOT include it.
5. Return ONLY a valid JSON array of objects with keys: productName, quantity, costPrice.`;

      // 3. Call Gemini 1.5 Flash API
      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

      const geminiPayload = {
        contents: [
          {
            parts: [
              { text: promptText },
              {
                inline_data: {
                  mime_type: mimeType,
                  data: imageBase64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          response_mime_type: "application/json",
          temperature: 0.1,
        },
      };

      const geminiResponse = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(geminiPayload),
      });

      if (!geminiResponse.ok) {
        const errorText = await geminiResponse.text();
        return new Response(
          JSON.stringify({
            error: `Gemini API error: ${geminiResponse.statusText}`,
            details: errorText,
          }),
          { status: geminiResponse.status, headers: corsHeaders }
        );
      }

      const geminiData = await geminiResponse.json();
      const rawOutputText =
        geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;

      if (!rawOutputText) {
        return new Response(
          JSON.stringify({ error: "Gemini did not return any text content." }),
          { status: 500, headers: corsHeaders }
        );
      }

      // Parse JSON from Gemini output
      let parsedItems = [];
      try {
        parsedItems = JSON.parse(rawOutputText);
      } catch (e) {
        // Fallback cleanup if markdown formatting was included
        const cleaned = rawOutputText
          .replace(/```json/g, "")
          .replace(/```/g, "")
          .trim();
        parsedItems = JSON.parse(cleaned);
      }

      return new Response(
        JSON.stringify({
          success: true,
          model: "gemini-1.5-flash",
          items: parsedItems,
        }),
        { status: 200, headers: corsHeaders }
      );
    } catch (err) {
      return new Response(
        JSON.stringify({
          error: "Internal Worker Error",
          message: err.message,
        }),
        { status: 500, headers: corsHeaders }
      );
    }
  },
};
