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
      `${SUPABASE_URL}/rest/v1/print_jobs?id=eq.${jobId}&select=image_data`,
      {
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
          Accept: "application/vnd.pgrst.object+json",
        },
      }
    );

    if (res.status === 406) {
      return { statusCode: 404, headers, body: JSON.stringify({ error: "Not found" }) };
    }

    if (!res.ok) {
      throw new Error(`Supabase select failed: ${res.status}`);
    }

    const row = await res.json();
    return { statusCode: 200, headers, body: row.image_data };
  } catch (error) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: "조회 실패" }) };
  }
};
