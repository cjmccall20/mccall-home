import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const FEEDBACK_EMAIL = "coopermccall20@gmail.com";

interface FeedbackPayload {
  type: string;
  title: string;
  description: string;
  userName: string;
  userEmail: string;
  appVersion: string;
  iosVersion: string;
  deviceModel: string;
}

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const payload: FeedbackPayload = await req.json();
    const { type, title, description, userName, userEmail, appVersion, iosVersion, deviceModel } = payload;

    // Format the email
    const typeEmoji = {
      bug: "🐛",
      feature: "💡",
      praise: "🌟",
      general: "💬",
    }[type] || "💬";

    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
    .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #4F46E5 0%, #7C3AED 100%); color: white; padding: 24px; }
    .header h1 { margin: 0; font-size: 24px; }
    .content { padding: 24px; }
    .meta { background: #f8f9fa; border-radius: 8px; padding: 16px; margin-bottom: 20px; }
    .meta-row { display: flex; margin-bottom: 8px; }
    .meta-label { color: #666; width: 120px; }
    .meta-value { color: #333; font-weight: 500; }
    .description { background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; }
    .description h3 { margin-top: 0; color: #333; }
    .description p { color: #555; line-height: 1.6; white-space: pre-wrap; }
    .footer { padding: 16px 24px; background: #f8f9fa; border-top: 1px solid #e5e7eb; font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${typeEmoji} New ${type.charAt(0).toUpperCase() + type.slice(1)} Feedback</h1>
    </div>
    <div class="content">
      <div class="meta">
        <div class="meta-row">
          <span class="meta-label">From:</span>
          <span class="meta-value">${userName} (${userEmail})</span>
        </div>
        <div class="meta-row">
          <span class="meta-label">Type:</span>
          <span class="meta-value">${type.charAt(0).toUpperCase() + type.slice(1)}</span>
        </div>
        <div class="meta-row">
          <span class="meta-label">App Version:</span>
          <span class="meta-value">${appVersion}</span>
        </div>
        <div class="meta-row">
          <span class="meta-label">iOS Version:</span>
          <span class="meta-value">${iosVersion}</span>
        </div>
        <div class="meta-row">
          <span class="meta-label">Device:</span>
          <span class="meta-value">${deviceModel}</span>
        </div>
      </div>
      <div class="description">
        <h3>${title}</h3>
        <p>${description}</p>
      </div>
    </div>
    <div class="footer">
      Sent from McCall Home App
    </div>
  </div>
</body>
</html>
    `;

    // Send via Resend
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "McCall Home <feedback@resend.dev>",
        to: [FEEDBACK_EMAIL],
        reply_to: userEmail,
        subject: `[McCall Home] ${typeEmoji} ${type.charAt(0).toUpperCase() + type.slice(1)}: ${title}`,
        html: emailHtml,
      }),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Resend error:", result);
      return new Response(JSON.stringify({ error: result }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, id: result.id }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});
