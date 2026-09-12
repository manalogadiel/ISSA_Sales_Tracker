/**
 * Cloudflare Worker: Receipt Scanner Proxy for ISSA Sales Tracker
 */

export default {
  async fetch(request, env, ctx) {
    /* 1. Handle CORS preflight */
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

    /* Check for API key in environment */
    const apiKey = env.GEMINI_API_KEY;

    /* Allow GET for quick health-check and model discovery */
    if (request.method === "GET") {
      const url = new URL(request.url);
      if (url.pathname.includes("/models") && apiKey) {
        try {
          const listRes = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`
          );
          const listData = await listRes.json();
          return new Response(JSON.stringify(listData, null, 2), {
            status: listRes.status,
            headers: corsHeaders,
          });
        } catch (err) {
          return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: corsHeaders,
          });
        }
      }

      return new Response(
        JSON.stringify({
          status: "ok",
          message: "ISSA Sales Tracker Gemini AI Proxy is operational",
          hasApiKey: !!apiKey,
        }),
        { status: 200, headers: corsHeaders }
      );
    }

    /* Only allow POST for scanning */
    if (request.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed. Send a POST request." }),
        { status: 405, headers: corsHeaders }
      );
    }
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

      /* 2. Prepare the Prompt for Gemini Flash Vision */
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

      /* 3. Call Gemini API (tries active flash vision models) */
      const candidateModels = [
        "gemini-3.6-flash",
        "gemini-3.5-flash",
        "gemini-flash-latest",
        "gemini-3.5-flash-lite",
      ];

      const geminiPayload = {
        contents: [
          {
            parts: [
              { text: promptText },
              {
                inlineData: {
                  mimeType: mimeType,
                  data: imageBase64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
          temperature: 0.1,
        },
      };

      let geminiResponse = null;
      let successfulModel = null;
      let modelErrors = [];

      for (const model of candidateModels) {
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
        const resp = await fetch(geminiUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(geminiPayload),
        });

        if (resp.ok) {
          geminiResponse = resp;
          successfulModel = model;
          break;
        } else {
          const errText = await resp.text();
          modelErrors.push({ model, status: resp.status, error: errText });
          if (resp.status === 404) {
            continue;
          } else if (resp.status === 429) {
            /* Quota exhausted or prepayment credit depleted */
            return new Response(
              JSON.stringify({
                error: `Gemini Quota Exceeded (429): Credits depleted or rate limit hit.`,
                details: errText,
              }),
              { status: 429, headers: corsHeaders }
            );
          } else if (resp.status === 401 || resp.status === 403) {
            /* Invalid API key or permission denied */
            return new Response(
              JSON.stringify({
                error: `Gemini Authentication Error (${model}): ${resp.statusText}`,
                details: errText,
              }),
              { status: resp.status, headers: corsHeaders }
            );
          }
        }
      }

      if (!geminiResponse) {
        return new Response(
          JSON.stringify({
            error: "No available Gemini model responded successfully.",
            details: JSON.stringify(modelErrors, null, 2),
          }),
          { status: 502, headers: corsHeaders }
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

      /* Parse JSON from Gemini output */
      let parsedItems = [];
      try {
        parsedItems = JSON.parse(rawOutputText);
      } catch (e) {
        /* Fallback cleanup if markdown formatting was included */
        const cleaned = rawOutputText
          .replace(/```json/g, "")
          .replace(/```/g, "")
          .trim();
        parsedItems = JSON.parse(cleaned);
      }

      return new Response(
        JSON.stringify({
          success: true,
          model: successfulModel || "gemini-3.6-flash",
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
