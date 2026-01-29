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
    await store.delete(jobId);

    return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
  } catch (error) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: "삭제 실패" }) };
  }
};
