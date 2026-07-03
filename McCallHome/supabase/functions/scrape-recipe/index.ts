import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { isTikTokUrl, fetchTikTokCaption, extractHashtags } from "./tiktok.ts"
import { extractFirstJsonObject } from "./parsing.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FirecrawlResponse {
  success: boolean
  data?: {
    markdown?: string
    metadata?: {
      title?: string
      description?: string
    }
  }
  error?: string
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

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { url } = await req.json()

    if (!url) {
      return new Response(
        JSON.stringify({ success: false, error: 'URL is required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    const FIRECRAWL_API_KEY = Deno.env.get('FIRECRAWL_API_KEY')
    const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')

    if (!ANTHROPIC_API_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'Anthropic API key not configured' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
      )
    }

    let recipe: ScrapedRecipe | null

    if (isTikTokUrl(url)) {
      // TikTok: the recipe lives in the video caption, not the page body
      console.log('Fetching TikTok caption:', url)
      const { caption, canonicalUrl } = await fetchTikTokCaption(url)

      if (!caption) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "We couldn't read this TikTok's caption. Double-check the link, or try again in a minute.",
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

      console.log('Parsing caption with Claude...')
      recipe = await parseWithClaude(caption, canonicalUrl, ANTHROPIC_API_KEY, 'caption')

      if (!recipe) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "We couldn't find a written recipe in this TikTok's caption. If the recipe is only spoken in the video, try a link where it's written out in the caption.",
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

      // Hashtags usually name the dish; merge them into tags
      const hashtags = extractHashtags(caption)
      if (hashtags.length > 0) {
        recipe.tags = [...new Set([...recipe.tags, ...hashtags])].slice(0, 10)
      }
    } else {
      if (!FIRECRAWL_API_KEY) {
        return new Response(
          JSON.stringify({ success: false, error: 'Firecrawl API key not configured' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
        )
      }

      // Step 1: Scrape the page with Firecrawl
      console.log('Scraping URL:', url)
      const firecrawlResponse = await fetch('https://api.firecrawl.dev/v1/scrape', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${FIRECRAWL_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          url: url,
          formats: ['markdown'],
        }),
      })

      const firecrawlData: FirecrawlResponse = await firecrawlResponse.json()

      if (!firecrawlData.success || !firecrawlData.data?.markdown) {
        return new Response(
          JSON.stringify({ success: false, error: 'Failed to scrape URL' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }

      // Step 2: Send to Claude for parsing
      console.log('Parsing with Claude...')
      recipe = await parseWithClaude(firecrawlData.data.markdown, url, ANTHROPIC_API_KEY, 'page')

      if (!recipe) {
        return new Response(
          JSON.stringify({ success: false, error: 'Could not parse recipe from page' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }
    }

    return new Response(
      JSON.stringify({ success: true, recipe }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error instanceof Error ? error.message : String(error) }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

async function parseWithClaude(
  content: string,
  sourceUrl: string,
  apiKey: string,
  mode: 'page' | 'caption' = 'page',
): Promise<ScrapedRecipe | null> {
  // Truncate if too long (keep first ~15k chars to stay within context)
  const truncatedMarkdown = content.length > 15000
    ? content.substring(0, 15000) + '\n\n[Content truncated...]'
    : content

  const sourceGuidance = mode === 'caption'
    ? `CRITICAL: The input is a short social-media video caption (e.g. TikTok). Keep in mind:
1. Ingredients may be listed inline without a formal recipe card, often one per line or separated by commas
2. Quantities may be informal ("a splash of", "a handful") - set quantity to null and capture the phrasing in notes
3. Hashtags (#dinner #easyrecipe) are NOT ingredients or steps - ignore them for ingredients/steps, though they may hint at the dish name or protein
4. Emoji are decoration - ignore them
5. If the caption clearly contains NO ingredient list or cooking instructions (e.g. it only says "recipe below" or just names the dish), return {"error":"No recipe found"}`
    : `CRITICAL: Extract ALL ingredients from the recipe. Look carefully for:
1. Recipe card sections (often marked with "Recipe", "Ingredients", or structured data)
2. Ingredient lists with quantities and measurements
3. Nested or grouped ingredients (e.g., "For the sauce:", "For the crust:")`

  const systemPrompt = `You are a recipe data extractor. Your ONLY job is to output valid JSON. Do not include any explanation, greeting, or markdown formatting - ONLY output the raw JSON object.

${sourceGuidance}

Output format (copy this structure exactly):
{"title":"Recipe Title","ingredients":[{"name":"ingredient","quantity":2,"unit":"cups","notes":null}],"steps":[{"step_number":1,"instruction":"Step text"}],"prep_time":15,"cook_time":30,"base_servings":4,"dish_category":"entree","protein_type":"chicken","tags":["tag1"]}

INGREDIENT RULES (VERY IMPORTANT):
- Extract EVERY ingredient, even if quantities are unclear
- quantity: number (0.5 for half, 0.25 for quarter, 0.33 for third, etc.) or null if not specified
- unit: string ("cups", "tablespoons", "teaspoons", "pounds", "ounces", "cloves", "pieces", etc.) or null
- notes: preparation notes like "diced", "minced", "room temperature", "divided" or null
- Common conversions: "1/2" = 0.5, "1/4" = 0.25, "1/3" = 0.33, "2/3" = 0.67, "3/4" = 0.75
- If ingredient says "to taste" or "as needed", set quantity to null with notes indicating this
- Keep ingredient names simple (e.g., "garlic" not "fresh garlic cloves")

OTHER RULES:
- prep_time/cook_time: minutes as number, or null
- base_servings: number, default 4 (look for "Servings:", "Serves:", "Yield:", etc.)
- dish_category: "entree"|"side"|"appetizer"|"dessert"|"drink"|"breakfast"|"snack"|"other" (use "entree" for main dishes)
- protein_type: "beef"|"chicken"|"pork"|"lamb"|"turkey"|"shrimp"|"salmon"|"fish"|"vegetarian"|"other"
- Only include actual cooking steps, not tips or serving suggestions

If no recipe found: {"error":"No recipe found"}`

  const userPrompt = `Extract recipe JSON from this content. Output ONLY the JSON object, nothing else:\n\n${truncatedMarkdown}`

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-3-haiku-20240307',
        max_tokens: 4096,
        messages: [
          { role: 'user', content: userPrompt },
          { role: 'assistant', content: '{' } // Prefill to force JSON output
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
    const responseText = data.content?.[0]?.text

    if (!responseText) {
      console.error('No content in Claude response')
      return null
    }

    if (data.stop_reason === 'max_tokens') {
      throw new Error('This recipe is too long to parse - try a page with a shorter recipe')
    }

    // Prepend the "{" prefill, strip any markdown code fences, then parse
    // the first balanced JSON object so stray trailing text can't break us
    const defenced = ('{' + responseText).replace(/```(?:json)?/g, '').trim()
    const jsonStr = extractFirstJsonObject(defenced)

    if (!jsonStr) {
      console.error('No JSON object in Claude response')
      return null
    }

    const parsed = JSON.parse(jsonStr)

    if (parsed.error) {
      console.error('Claude could not parse recipe:', parsed.error)
      return null
    }

    // Validate and return the recipe
    return {
      title: parsed.title || 'Untitled Recipe',
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

  } catch (error) {
    console.error('Error calling Claude API:', error)
    throw error // Re-throw to get error details in response
  }
}
