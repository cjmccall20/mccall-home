import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

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

    if (!FIRECRAWL_API_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'Firecrawl API key not configured' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
      )
    }

    if (!ANTHROPIC_API_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'Anthropic API key not configured' }),
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
    const recipe = await parseWithClaude(firecrawlData.data.markdown, url, ANTHROPIC_API_KEY)

    if (!recipe) {
      return new Response(
        JSON.stringify({ success: false, error: 'Could not parse recipe from page' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    return new Response(
      JSON.stringify({ success: true, recipe }),
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

async function parseWithClaude(markdown: string, sourceUrl: string, apiKey: string): Promise<ScrapedRecipe | null> {
  // Truncate markdown if too long (keep first ~15k chars to stay within context)
  const truncatedMarkdown = markdown.length > 15000
    ? markdown.substring(0, 15000) + '\n\n[Content truncated...]'
    : markdown

  const systemPrompt = `You are a recipe data extractor. Your ONLY job is to output valid JSON. Do not include any explanation, greeting, or markdown formatting - ONLY output the raw JSON object.

CRITICAL: Extract ALL ingredients from the recipe. Look carefully for:
1. Recipe card sections (often marked with "Recipe", "Ingredients", or structured data)
2. Ingredient lists with quantities and measurements
3. Nested or grouped ingredients (e.g., "For the sauce:", "For the crust:")

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
    const content = data.content?.[0]?.text

    if (!content) {
      console.error('No content in Claude response')
      return null
    }

    // Parse the JSON response
    // Prepend the "{" that we used as prefill, then handle markdown code blocks
    let jsonStr = '{' + content.trim()
    if (jsonStr.startsWith('{```json')) {
      jsonStr = jsonStr.slice(8)
    } else if (jsonStr.startsWith('{```')) {
      jsonStr = jsonStr.slice(4)
    }
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.slice(0, -3)
    }
    jsonStr = jsonStr.trim()

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
