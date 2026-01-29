const nodemailer = require("nodemailer");

exports.handler = async (event) => {
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: "Method Not Allowed" };
  }

  try {
    const { imageData } = JSON.parse(event.body);

    if (!imageData) {
      return { statusCode: 400, body: JSON.stringify({ error: "이미지 데이터가 없습니다" }) };
    }

    // base64 데이터에서 헤더 제거
    const base64Image = imageData.replace(/^data:image\/\w+;base64,/, "");

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_APP_PASSWORD,
      },
    });

    await transporter.sendMail({
      from: process.env.GMAIL_USER,
      to: process.env.PRINTER_EMAIL,
      subject: "Photo Print",
      text: "셀프 포토 프린트",
      attachments: [
        {
          filename: `photo_${Date.now()}.png`,
          content: base64Image,
          encoding: "base64",
          contentType: "image/png",
        },
      ],
    });

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ success: true }),
    };
  } catch (error) {
    console.error("Print error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "인쇄 요청에 실패했습니다" }),
    };
  }
};
