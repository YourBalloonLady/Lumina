export async function onRequestPost({ request, env }) {
  try {
    const body = await request.json().catch(() => ({}));
    const message = String(body.message || "").slice(0, 2000);
    const product = String(body.product || "").slice(0, 200);

    const system = `
You are Lumina Weight's Research Info Assistant.
Rules:
- Educational information only. Not medical advice.
- Do NOT provide dosing, protocols, “how to use”, injection guidance, reconstitution, mixing volumes, stacks/cycles, sourcing, or purchasing advice.
- If asked for any of the above, refuse briefly and suggest speaking to a licensed clinician.
- You can explain: what it is, mechanism at a high level, research status, typical study context, common risks/side effects at a high level, contraindication themes, and red-flag symptoms.
- Keep it clear and concise.`;

    const catalogHint = product
      ? `User selected product: ${product}. Provide high-level info only, following the rules.`
      : `No product selected. Encourage selecting a product.`;

    const payload = {
      model: "gpt-4.1-mini",
      input: [
        { role: "system", content: system },
        { role: "system", content: catalogHint },
        { role: "user", content: message }
      ],
      max_output_tokens: 350
    };

    const r = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.OPENAI_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    if (!r.ok) {
      const detail = await r.text();
      return new Response(JSON.stringify({ error: "AI request failed", detail }), {
        status: 500,
        headers: { "Content-Type": "application/json" }
      });
    }

    const data = await r.json();
    const reply = data.output_text || "No response.";

    return new Response(JSON.stringify({ reply }), {
      headers: { "Content-Type": "application/json" }
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: "Bad request", detail: String(e) }), {
      status: 400,
      headers: { "Content-Type": "application/json" }
    });
  }
}
