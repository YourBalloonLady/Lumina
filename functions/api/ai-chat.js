export async function onRequestPost({ request, env }) {
  try {
    const { message } = await request.json();

    if (!message) {
      return new Response("No message provided", { status: 400 });
    }

    const res = await fetch(`${env.CF_AI_BASE_URL}/chat/completions`, {
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
              "You are an informational assistant. You provide high-level educational information only. No medical advice. Research use only."
          },
          {
            role: "user",
            content: message
          }
        ]
      })
    });

    const data = await res.json();

    return new Response(
      JSON.stringify({
        reply: data.choices?.[0]?.message?.content || "No response"
      }),
      { headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ error: "AI request failed" }),
      { status: 500 }
    );
  }
}
