const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

exports.handler = async (event) => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json",
  };

  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  if (event.httpMethod !== "POST") {
    return { statusCode: 405, headers, body: "Method Not Allowed" };
  }

  try {
    const jobId = Date.now().toString();

    const res = await fetch(`${SUPABASE_URL}/rest/v1/print_jobs`, {
      method: "POST",
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ id: jobId, image_data: event.body }),
    });

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`Supabase insert failed: ${res.status} ${errText}`);
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ success: true, jobId }),
    };
  } catch (error) {
    console.error("Store error:", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "저장 실패" }),
    };
  }
};
