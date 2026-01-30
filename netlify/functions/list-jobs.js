const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

exports.handler = async () => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Content-Type": "application/json",
  };

  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/print_jobs?select=id&order=id.asc`,
      {
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
      }
    );

    if (!res.ok) {
      throw new Error(`Supabase select failed: ${res.status}`);
    }

    const rows = await res.json();
    const jobs = rows.map((r) => r.id);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ jobs }),
    };
  } catch (error) {
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ jobs: [] }),
    };
  }
};
