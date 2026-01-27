export async function onRequestPost({ request }) {
  return new Response(
    JSON.stringify({ ok: true, message: "POST route works" }),
    {
      headers: { "Content-Type": "application/json" }
    }
  );
}
