const { getStore } = require("@netlify/blobs");

exports.handler = async () => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Content-Type": "application/json",
  };

  try {
    const store = getStore("print-jobs");
    const { blobs } = await store.list();
    const jobs = blobs.map((b) => b.key);

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
