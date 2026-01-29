const { getStore } = require("@netlify/blobs");

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
    const store = getStore("print-jobs");
    const data = await store.get(jobId);

    if (!data) {
      return { statusCode: 404, headers, body: JSON.stringify({ error: "Not found" }) };
    }

    return { statusCode: 200, headers, body: data };
  } catch (error) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: "조회 실패" }) };
  }
};
