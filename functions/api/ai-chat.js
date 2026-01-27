export async function onRequestPost({ request, env }) {
  try {
    const { message, product } = await request.json();

    if (!message) {
      return new Response(JSON.stringify({ error: "No message provided" }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }

    const model = env.CF_AI_MODEL || "openai/gpt-4.1-mini";

    const system = `
You are an educational information assistant.
You must NOT give dosing, cycle plans, injection instructions, sourcing, or medical advice.
If asked those, refuse and offer general safety guidance and "talk to a qualified clinician".
Keep answers clear, short, and factual.
If the user asks about "research peptides", respond at a high level: mechanism, research context, known risks/unknowns.
`.trim();

    const context = product ? `User is viewing product: ${product}` : "";

    const res = await fetch(`${env.CF_AI_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.CF_AI_GATEWAY_TOKEN}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: system },
          ...(context ? [{ role: "system", content: context }] : []),
          { role: "user", content: message }
        ]
      })
    });

    const data = await res.json();
    const reply = data?.choices?.[0]?.message?.content || "No response";

    return new Response(JSON.stringify({ reply }), {
      headers: { "Content-Type": "application/json" }
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: "AI request failed" }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
}
