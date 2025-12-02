import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface MealPlanEntry {
  id: string
  meal_type: string
  recipe?: { name: string }
  restaurant?: { name: string }
  assigned_to?: string
  household_member?: { name: string }
}

interface HoneydewTask {
  id: string
  title: string
  description?: string
  due_date?: string
  assigned_to?: { name: string }
}

interface CalendarEvent {
  id: string
  title: string
  start_time: string
  end_time?: string
}

interface HouseholdSettings {
  household_id: string
  morning_email_enabled: boolean
  morning_email_time: string
  morning_email_recipients: string[]
  timezone: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

    if (!RESEND_API_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'Resend API key not configured' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
      )
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Get all households with morning email enabled
    const { data: settings, error: settingsError } = await supabase
      .from('household_settings')
      .select('*')
      .eq('morning_email_enabled', true)

    if (settingsError) {
      throw settingsError
    }

    const results: { household_id: string; success: boolean; error?: string }[] = []

    for (const householdSettings of settings || []) {
      try {
        const result = await sendMorningEmailForHousehold(
          supabase,
          householdSettings,
          RESEND_API_KEY
        )
        results.push(result)
      } catch (error) {
        results.push({
          household_id: householdSettings.household_id,
          success: false,
          error: error.message,
        })
      }
    }

    return new Response(
      JSON.stringify({ success: true, results }),
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

async function sendMorningEmailForHousehold(
  supabase: any,
  settings: HouseholdSettings,
  resendApiKey: string
): Promise<{ household_id: string; success: boolean; error?: string }> {
  const householdId = settings.household_id
  const recipients = settings.morning_email_recipients || []

  if (recipients.length === 0) {
    return { household_id: householdId, success: false, error: 'No recipients configured' }
  }

  // Get household name
  const { data: household } = await supabase
    .from('households')
    .select('name')
    .eq('id', householdId)
    .single()

  const householdName = household?.name || 'Your Household'

  // Get today's date in household timezone
  const today = new Date()
  const dateStr = today.toISOString().split('T')[0]

  // Fetch today's meals
  const { data: meals } = await supabase
    .from('meal_plan_entries')
    .select(`
      id,
      meal_type,
      recipe:recipes(name),
      restaurant:restaurants(name),
      assigned_to,
      household_member:household_members(name)
    `)
    .eq('household_id', householdId)
    .eq('date', dateStr)
    .order('meal_type')

  // Fetch today's tasks (due today or overdue)
  const { data: tasks } = await supabase
    .from('honeydew_tasks')
    .select(`
      id,
      title,
      description,
      due_date,
      assigned_to:household_members(name)
    `)
    .eq('household_id', householdId)
    .eq('is_completed', false)
    .or(`due_date.eq.${dateStr},due_date.lt.${dateStr}`)
    .order('due_date')

  // Fetch calendar events for today (if calendar is connected)
  const { data: calendarEvents } = await supabase
    .from('calendar_events')
    .select('*')
    .eq('household_id', householdId)
    .gte('start_time', `${dateStr}T00:00:00`)
    .lt('start_time', `${dateStr}T23:59:59`)
    .order('start_time')

  // Build email HTML
  const emailHtml = buildMorningEmailHtml({
    householdName,
    date: today,
    meals: meals || [],
    tasks: tasks || [],
    calendarEvents: calendarEvents || [],
  })

  // Send email via Resend
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${resendApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'McCall Home <noreply@mccallhome.app>',
      to: recipients,
      subject: `Good Morning from ${householdName} - ${formatDate(today)}`,
      html: emailHtml,
    }),
  })

  if (!response.ok) {
    const errorData = await response.text()
    return { household_id: householdId, success: false, error: `Resend error: ${errorData}` }
  }

  return { household_id: householdId, success: true }
}

function buildMorningEmailHtml(data: {
  householdName: string
  date: Date
  meals: MealPlanEntry[]
  tasks: HoneydewTask[]
  calendarEvents: CalendarEvent[]
}): string {
  const { householdName, date, meals, tasks, calendarEvents } = data

  const mealTypeOrder = { breakfast: 1, lunch: 2, dinner: 3 }
  const sortedMeals = [...meals].sort((a, b) =>
    (mealTypeOrder[a.meal_type] || 99) - (mealTypeOrder[b.meal_type] || 99)
  )

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
    h1 { color: #1a73e8; margin-bottom: 5px; }
    h2 { color: #5f6368; font-size: 18px; margin-top: 25px; border-bottom: 2px solid #e0e0e0; padding-bottom: 8px; }
    .date { color: #666; margin-bottom: 20px; }
    .meal { padding: 12px; margin: 8px 0; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #1a73e8; }
    .meal-type { font-weight: 600; color: #1a73e8; text-transform: capitalize; }
    .meal-name { margin-top: 4px; }
    .meal-chef { font-size: 14px; color: #666; margin-top: 4px; }
    .task { padding: 12px; margin: 8px 0; background: #fff3e0; border-radius: 8px; border-left: 4px solid #ff9800; }
    .task-title { font-weight: 600; }
    .task-assignee { font-size: 14px; color: #666; }
    .event { padding: 12px; margin: 8px 0; background: #e8f5e9; border-radius: 8px; border-left: 4px solid #4caf50; }
    .event-time { font-weight: 600; color: #4caf50; }
    .empty { color: #999; font-style: italic; padding: 12px; }
    .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0; font-size: 12px; color: #999; text-align: center; }
  </style>
</head>
<body>
  <h1>Good Morning!</h1>
  <p class="date">${formatDate(date)}</p>

  <h2>Today's Meals</h2>
  ${sortedMeals.length > 0 ? sortedMeals.map(meal => `
    <div class="meal">
      <div class="meal-type">${meal.meal_type}</div>
      <div class="meal-name">${meal.recipe?.name || meal.restaurant?.name || 'TBD'}</div>
      ${meal.household_member ? `<div class="meal-chef">Chef: ${meal.household_member.name}</div>` : ''}
    </div>
  `).join('') : '<p class="empty">No meals planned for today</p>'}

  <h2>Today's Tasks</h2>
  ${tasks.length > 0 ? tasks.map(task => `
    <div class="task">
      <div class="task-title">${task.title}</div>
      ${task.assigned_to ? `<div class="task-assignee">Assigned to: ${task.assigned_to.name}</div>` : ''}
    </div>
  `).join('') : '<p class="empty">No tasks due today</p>'}

  ${calendarEvents.length > 0 ? `
    <h2>Calendar</h2>
    ${calendarEvents.map(event => `
      <div class="event">
        <div class="event-time">${formatTime(event.start_time)}</div>
        <div>${event.title}</div>
      </div>
    `).join('')}
  ` : ''}

  <div class="footer">
    <p>Sent from McCall Home</p>
    <p>Manage your preferences in the app settings</p>
  </div>
</body>
</html>
  `
}

function formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

function formatTime(isoString: string): string {
  const date = new Date(isoString)
  return date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  })
}
