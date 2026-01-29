const { getStore } = require("@netlify/blobs");

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
    const store = getStore("print-jobs");
    const jobId = Date.now().toString();
    await store.set(jobId, event.body);

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
