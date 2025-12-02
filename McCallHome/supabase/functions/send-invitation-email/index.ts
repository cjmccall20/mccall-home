import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface InvitationEmailRequest {
  invitation_id: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { invitation_id }: InvitationEmailRequest = await req.json()

    if (!invitation_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'invitation_id is required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
    const APP_URL = Deno.env.get('APP_URL') || 'https://mccallhome.app'

    if (!RESEND_API_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'Resend API key not configured' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
      )
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Fetch invitation details
    const { data: invitation, error: inviteError } = await supabase
      .from('household_invitations')
      .select(`
        id,
        email,
        token,
        expires_at,
        household:households(name),
        inviter:users!invited_by(name)
      `)
      .eq('id', invitation_id)
      .single()

    if (inviteError || !invitation) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invitation not found' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 404 }
      )
    }

    const householdName = invitation.household?.name || 'a household'
    const inviterName = invitation.inviter?.name || 'Someone'
    const inviteLink = `${APP_URL}/invite?token=${invitation.token}`
    const deepLink = `mccallhome://invite?token=${invitation.token}`

    // Build email HTML
    const emailHtml = buildInvitationEmailHtml({
      householdName,
      inviterName,
      inviteLink,
      deepLink,
      expiresAt: new Date(invitation.expires_at),
    })

    // Send email via Resend
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'McCall Home <noreply@mccallhome.app>',
        to: [invitation.email],
        subject: `${inviterName} invited you to join ${householdName} on McCall Home`,
        html: emailHtml,
      }),
    })

    if (!response.ok) {
      const errorData = await response.text()
      return new Response(
        JSON.stringify({ success: false, error: `Failed to send email: ${errorData}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
      )
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

function buildInvitationEmailHtml(data: {
  householdName: string
  inviterName: string
  inviteLink: string
  deepLink: string
  expiresAt: Date
}): string {
  const { householdName, inviterName, inviteLink, deepLink, expiresAt } = data

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
      background-color: #f5f5f5;
    }
    .container {
      background: white;
      border-radius: 12px;
      padding: 40px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .logo {
      text-align: center;
      margin-bottom: 30px;
    }
    .logo-icon {
      font-size: 48px;
    }
    h1 {
      color: #1a73e8;
      text-align: center;
      margin-bottom: 10px;
    }
    .subtitle {
      text-align: center;
      color: #666;
      margin-bottom: 30px;
    }
    .message {
      background: #f8f9fa;
      border-radius: 8px;
      padding: 20px;
      margin: 20px 0;
    }
    .btn-container {
      text-align: center;
      margin: 30px 0;
    }
    .btn {
      display: inline-block;
      padding: 14px 32px;
      background: #1a73e8;
      color: white !important;
      text-decoration: none;
      border-radius: 8px;
      font-weight: 600;
      font-size: 16px;
    }
    .btn:hover {
      background: #1557b0;
    }
    .alt-link {
      text-align: center;
      margin-top: 20px;
      font-size: 14px;
      color: #666;
    }
    .alt-link a {
      color: #1a73e8;
    }
    .expires {
      text-align: center;
      font-size: 13px;
      color: #999;
      margin-top: 20px;
    }
    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #e0e0e0;
      text-align: center;
      font-size: 12px;
      color: #999;
    }
    .features {
      margin: 30px 0;
    }
    .feature {
      display: flex;
      align-items: center;
      margin: 12px 0;
    }
    .feature-icon {
      margin-right: 12px;
      font-size: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <div class="logo-icon">🏠</div>
    </div>

    <h1>You're Invited!</h1>
    <p class="subtitle">${inviterName} wants you to join their household</p>

    <div class="message">
      <p>Hi there!</p>
      <p><strong>${inviterName}</strong> has invited you to join <strong>${householdName}</strong> on McCall Home, the household management app.</p>
    </div>

    <div class="features">
      <p style="font-weight: 600; margin-bottom: 12px;">With McCall Home, you can:</p>
      <div class="feature">
        <span class="feature-icon">📅</span>
        <span>Plan meals together as a family</span>
      </div>
      <div class="feature">
        <span class="feature-icon">🛒</span>
        <span>Share grocery lists automatically</span>
      </div>
      <div class="feature">
        <span class="feature-icon">✅</span>
        <span>Track household tasks and to-dos</span>
      </div>
      <div class="feature">
        <span class="feature-icon">🍳</span>
        <span>Store and share recipes</span>
      </div>
    </div>

    <div class="btn-container">
      <a href="${deepLink}" class="btn">Accept Invitation</a>
    </div>

    <p class="alt-link">
      Button not working? <a href="${inviteLink}">Click here</a> or copy this link:<br>
      <code style="font-size: 12px; word-break: break-all;">${inviteLink}</code>
    </p>

    <p class="expires">
      This invitation expires on ${expiresAt.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      })}
    </p>

    <div class="footer">
      <p>McCall Home - Your Household Hub</p>
      <p>If you didn't expect this invitation, you can safely ignore this email.</p>
    </div>
  </div>
</body>
</html>
  `
}
