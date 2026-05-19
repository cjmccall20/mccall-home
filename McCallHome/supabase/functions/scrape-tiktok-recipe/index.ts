import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ScrapedRecipe {
  title: string
  ingredients: Array<{
    name: string
    quantity: number | null
    unit: string | null
    notes: string | null
  }>
  steps: Array<{
    step_number: number
    instruction: string
  }>
  prep_time: number | null
  cook_time: number | null
  base_servings: number
  dish_category: string | null
  protein_type: string | null
  tags: string[]
  source_url: string
}

interface TikWmSubtitle {
  language?: string
  language_code?: string
  source?: string
  url?: string
}

interface TikWmData {
  id?: string
  title?: string
  author?: { unique_id?: string; nickname?: string }
  music_info?: { title?: string; author?: string }
  subtitle_info?: TikWmSubtitle[]
  play?: string
  cover?: string
}

interface TikWmResponse {
  code: number
  msg?: string
  data?: TikWmData
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { url } = await req.json()

    if (!url || typeof url !== 'string') {
      return jsonError('URL is required', 400)
    }

    if (!isTikTokUrl(url)) {
      return jsonError('Not a TikTok URL', 400)
    }

    const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')
    if (!ANTHROPIC_API_KEY) {
      return jsonError('Anthropic API key not configured', 500)
    }

    // Step 1: Get TikTok metadata + subtitle URLs via TikWM
    console.log('Fetching TikTok metadata for:', url)
    const meta = await fetchTikTokMetadata(url)
    if (!meta) {
      return jsonError('Could not fetch TikTok video metadata. The link may be invalid or the video is private.', 400)
    }

    const caption = (meta.title ?? '').trim()

    // Step 2: Get transcript if available (TikTok auto-captions)
    let transcript = ''
    if (meta.subtitle_info && meta.subtitle_info.length > 0) {
      const subtitle = pickBestSubtitle(meta.subtitle_info)
      if (subtitle?.url) {
        try {
          console.log('Fetching subtitle:', subtitle.url)
          transcript = await fetchTranscript(subtitle.url)
        } catch (e) {
          console.error('Failed to fetch subtitle:', e)
        }
      }
    }

    if (!caption && !transcript) {
      return jsonError('No caption or transcript available for this TikTok. The recipe text could not be extracted.', 400)
    }

    // Step 3: Send to Claude for parsing
    const combined = buildSourceText(caption, transcript, meta)
    console.log('Parsing with Claude... (chars:', combined.length, ')')
    const recipe = await parseWithClaude(combined, url, ANTHROPIC_API_KEY)

    if (!recipe) {
      return jsonError('Could not extract a recipe from this TikTok video.', 400)
    }

    return new Response(
      JSON.stringify({ success: true, recipe }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return jsonError(error instanceof Error ? error.message : String(error), 500)
  }
})

function jsonError(message: string, status: number): Response {
  return new Response(
    JSON.stringify({ success: false, error: message }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status }
  )
}

function isTikTokUrl(url: string): boolean {
  try {
    const u = new URL(url)
    const host = u.hostname.toLowerCase()
    return host === 'tiktok.com'
      || host.endsWith('.tiktok.com')
      || host === 'vm.tiktok.com'
      || host === 'vt.tiktok.com'
  } catch {
    return false
  }
}

async function fetchTikTokMetadata(url: string): Promise<TikWmData | null> {
  // TikWM accepts both full and short TikTok URLs and resolves redirects internally.
  const endpoint = 'https://www.tikwm.com/api/'
  const form = new URLSearchParams()
  form.set('url', url)
  form.set('hd', '1')

  const res = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'Mozilla/5.0 (compatible; McCallHomeBot/1.0)',
    },
    body: form.toString(),
  })

  if (!res.ok) {
    console.error('TikWM HTTP error:', res.status, await res.text().catch(() => ''))
    return null
  }

  const json: TikWmResponse = await res.json()
  if (json.code !== 0 || !json.data) {
    console.error('TikWM error:', json.code, json.msg)
    return null
  }
  return json.data
}

function pickBestSubtitle(subs: TikWmSubtitle[]): TikWmSubtitle | null {
  if (subs.length === 0) return null
  // Prefer English ASR, then any ASR, then anything else
  const english = subs.find(s => (s.language_code ?? s.language ?? '').toLowerCase().startsWith('en'))
  if (english) return english
  const asr = subs.find(s => (s.source ?? '').toLowerCase().includes('asr'))
  if (asr) return asr
  return subs[0]
}

async function fetchTranscript(subtitleUrl: string): Promise<string> {
  const res = await fetch(subtitleUrl, {
    headers: { 'User-Agent': 'Mozilla/5.0' },
  })
  if (!res.ok) throw new Error(`Subtitle fetch failed: ${res.status}`)
  const text = await res.text()
  return cleanWebVtt(text)
}

function cleanWebVtt(vtt: string): string {
  // Strip WebVTT headers, cue numbers, timestamps; keep spoken lines.
  const lines = vtt.split(/\r?\n/)
  const out: string[] = []
  for (const raw of lines) {
    const line = raw.trim()
    if (!line) continue
    if (line.startsWith('WEBVTT')) continue
    if (line.startsWith('NOTE')) continue
    if (/^\d+$/.test(line)) continue // cue index
    if (/-->/.test(line)) continue // timestamp
    // Strip simple inline tags like <c> or <v Speaker>
    out.push(line.replace(/<[^>]+>/g, ''))
  }
  // Deduplicate consecutive identical lines (common in ASR captions that repeat across cues)
  const deduped: string[] = []
  for (const l of out) {
    if (deduped.length === 0 || deduped[deduped.length - 1] !== l) {
      deduped.push(l)
    }
  }
  return deduped.join(' ')
}

function buildSourceText(caption: string, transcript: string, meta: TikWmData): string {
  const parts: string[] = []
  if (meta.author?.nickname || meta.author?.unique_id) {
    parts.push(`Creator: ${meta.author.nickname ?? meta.author.unique_id}`)
  }
  if (caption) {
    parts.push(`Caption / description:\n${caption}`)
  }
  if (transcript) {
    parts.push(`Spoken transcript (auto-captioned from the video):\n${transcript}`)
  }
  return parts.join('\n\n')
}

async function parseWithClaude(sourceText: string, sourceUrl: string, apiKey: string): Promise<ScrapedRecipe | null> {
  const truncated = sourceText.length > 15000
    ? sourceText.substring(0, 15000) + '\n\n[Content truncated...]'
    : sourceText

  const systemPrompt = `You are a recipe data extractor for TikTok cooking videos. Your ONLY job is to output valid JSON. Do not include any explanation, greeting, or markdown formatting - ONLY output the raw JSON object.

The input is the caption and (when available) the auto-generated spoken transcript of a TikTok cooking video. Recipes on TikTok are often loose - infer quantities from context where reasonable, and do your best to identify all ingredients and steps the creator mentions.

Output format (copy this structure exactly):
{"title":"Recipe Title","ingredients":[{"name":"ingredient","quantity":2,"unit":"cups","notes":null}],"steps":[{"step_number":1,"instruction":"Step text"}],"prep_time":15,"cook_time":30,"base_servings":4,"dish_category":"entree","protein_type":"chicken","tags":["tag1"]}

INGREDIENT RULES:
- Extract EVERY ingredient the creator mentions, even if quantities are unclear.
- quantity: number (0.5 for half, 0.25 for quarter, 0.33 for third, etc.) or null if not specified.
- unit: string ("cups", "tablespoons", "teaspoons", "pounds", "ounces", "cloves", "pieces", etc.) or null.
- notes: preparation notes like "diced", "minced", "room temperature", "divided" or null.
- Common conversions: "1/2" = 0.5, "1/4" = 0.25, "1/3" = 0.33, "2/3" = 0.67, "3/4" = 0.75.
- If ingredient says "to taste" or "as needed", set quantity to null with notes indicating this.
- Keep ingredient names simple (e.g., "garlic" not "fresh garlic cloves").

STEP RULES:
- Convert the spoken / written instructions into clean numbered cooking steps.
- Combine related sentences into single coherent steps.
- Strip TikTok filler ("guys", "so basically", "okay so", "let's go"). Keep the actual cooking action.

OTHER RULES:
- title: create a clean recipe title from the caption / hashtags. Strip emojis and TikTok-isms.
- prep_time/cook_time: minutes as number, or null.
- base_servings: number, default 4.
- dish_category: "entree"|"side"|"appetizer"|"dessert"|"drink"|"breakfast"|"snack"|"other".
- protein_type: "beef"|"chicken"|"pork"|"lamb"|"turkey"|"shrimp"|"salmon"|"fish"|"vegetarian"|"other".
- tags: include relevant hashtags from the caption (without the #), lowercased.

If no recipe found: {"error":"No recipe found"}`

  const userPrompt = `Extract recipe JSON from this TikTok content. Output ONLY the JSON object, nothing else:\n\n${truncated}`

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 4096,
      messages: [
        { role: 'user', content: userPrompt },
        { role: 'assistant', content: '{' },
      ],
      system: systemPrompt,
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    console.error('Claude API error:', response.status, errorText)
    throw new Error(`Claude API error: ${response.status} - ${errorText.substring(0, 200)}`)
  }

  const data = await response.json()
  const content = data.content?.[0]?.text
  if (!content) {
    console.error('No content in Claude response')
    return null
  }

  let jsonStr = '{' + content.trim()
  if (jsonStr.startsWith('{```json')) jsonStr = jsonStr.slice(8)
  else if (jsonStr.startsWith('{```')) jsonStr = jsonStr.slice(4)
  if (jsonStr.endsWith('```')) jsonStr = jsonStr.slice(0, -3)
  jsonStr = jsonStr.trim()

  const parsed = JSON.parse(jsonStr)
  if (parsed.error) {
    console.error('Claude could not parse recipe:', parsed.error)
    return null
  }

  return {
    title: parsed.title || 'Untitled TikTok Recipe',
    ingredients: Array.isArray(parsed.ingredients) ? parsed.ingredients : [],
    steps: Array.isArray(parsed.steps) ? parsed.steps : [],
    prep_time: typeof parsed.prep_time === 'number' ? parsed.prep_time : null,
    cook_time: typeof parsed.cook_time === 'number' ? parsed.cook_time : null,
    base_servings: typeof parsed.base_servings === 'number' ? parsed.base_servings : 4,
    dish_category: parsed.dish_category || null,
    protein_type: parsed.protein_type || null,
    tags: Array.isArray(parsed.tags) ? parsed.tags : [],
    source_url: sourceUrl,
  }
}
