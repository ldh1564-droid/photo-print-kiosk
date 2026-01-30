const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

exports.handler = async (event) => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Content-Type": "application/json",
  };

  const jobId = event.queryStringParameters?.id;
  if (!jobId) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: "Missing job ID" }) };
  }

  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/print_jobs?id=eq.${jobId}`,
      {
        method: "DELETE",
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
      }
    );

    if (!res.ok) {
      throw new Error(`Supabase delete failed: ${res.status}`);
    }

    return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
  } catch (error) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: "삭제 실패" }) };
  }
};
