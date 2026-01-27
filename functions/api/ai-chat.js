export async function onRequestPost({ request, env }) {
  try {
    const body = await request.json();
    const userMessage = body.message;

    if (!userMessage) {
      return new Response(
        JSON.stringify({ error: "No message provided" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const res = await fetch(env.CF_AI_BASE_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.CF_AI_GATEWAY_TOKEN}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "openai/gpt-4.1-mini",
        messages: [
          {
            role: "system",
            content:
              "You are Lumina AI. Provide research-context information only. No dosing, no medical advice, no instructions."
          },
          {
            role: "user",
            content: userMessage
          }
        ]
      })
    });

    const data = await res.json();

    return new Response(
      JSON.stringify({ reply: data.choices?.[0]?.message?.content || "No reply" }),
      { headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
}
