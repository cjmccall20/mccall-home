import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Ingredient {
  name: string
  quantity: number | null
  unit: string | null
  notes: string | null
}

interface RecipeEntry {
  title: string
  servings: number
  ingredients: Ingredient[]
}

interface PantryStaple {
  name: string
  category: string
}

interface SmartGroceryItem {
  name: string
  quantity: number | null
  unit: string | null
  category: string
  is_pantry_check: boolean
  notes: string | null
}

interface GeneratedList {
  items: SmartGroceryItem[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { recipes, pantry_staples }: { recipes: RecipeEntry[], pantry_staples: PantryStaple[] } = await req.json()

    if (!recipes || recipes.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'No recipes provided' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')
    if (!ANTHROPIC_API_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'Anthropic API key not configured' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
      )
    }

    console.log('Generating smart grocery list for', recipes.length, 'recipes')
    const groceryList = await generateWithClaude(recipes, pantry_staples, ANTHROPIC_API_KEY)

    return new Response(
      JSON.stringify({ success: true, grocery_list: groceryList }),
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

async function generateWithClaude(recipes: RecipeEntry[], pantryStaples: PantryStaple[], apiKey: string): Promise<GeneratedList> {
  const recipesSummary = recipes.map(r => {
    const ingredients = r.ingredients.map(i => {
      let str = ''
      if (i.quantity) str += `${i.quantity} `
      if (i.unit) str += `${i.unit} `
      str += i.name
      if (i.notes) str += ` (${i.notes})`
      return str.trim()
    }).join('\n  - ')
    return `${r.title} (${r.servings} servings):\n  - ${ingredients}`
  }).join('\n\n')

  const staplesText = pantryStaples.length > 0
    ? `\n\nPANTRY STAPLES (items the household usually has on hand):\n${pantryStaples.map(s => `- ${s.name}`).join('\n')}`
    : ''

  const systemPrompt = `You are a smart grocery list generator. Your job is to take recipe ingredients and create an optimized shopping list.

RULES:
1. COMBINE like items (e.g., if multiple recipes need butter, combine into one entry)
2. KEEP RECIPE QUANTITIES - show the actual amount needed for the recipes (e.g., "1 cup buttermilk", "2 tbsp olive oil")
   - Do NOT convert to store quantities (don't change "1 cup milk" to "1 gallon milk")
   - Round up slightly for practicality (e.g., 0.75 lb → 1 lb)
3. CATEGORIZE items into store sections:
   - produce (fruits, vegetables, fresh herbs)
   - dairy (milk, cheese, eggs, butter, cream)
   - meat (all proteins - chicken, beef, pork, fish, etc.)
   - bakery (bread, rolls, tortillas)
   - pantry (canned goods, pasta, rice, oils, sauces)
   - frozen (frozen foods)
   - beverages (drinks)
   - other (anything else)
4. PANTRY CHECK - Mark these items as "is_pantry_check: true":
   - ALL items from the PANTRY STAPLES list provided (match semantically: "flour" matches "all purpose flour", "butter" matches "unsalted butter", etc.)
   - ALL spices and seasonings (salt, pepper, paprika, cumin, oregano, garlic powder, onion powder, chili powder, etc.)
   - Common baking staples (flour, sugar, baking powder, baking soda, vanilla extract)
   - Common oils and vinegars (olive oil, vegetable oil, vinegar)
   - Pantry check items are things the user should verify they have at home
5. Use PRACTICAL quantities:
   - "1 bunch cilantro" not "0.25 cups cilantro"
   - "1 head garlic" not "4 cloves garlic" (round up appropriately)
   - "1 lb chicken breast" not "0.8 lb chicken"

OUTPUT FORMAT - JSON only, no explanation:
{
  "items": [
    {"name": "Item Name", "quantity": 2, "unit": "lb", "category": "meat", "is_pantry_check": false, "notes": null},
    {"name": "Olive Oil", "quantity": null, "unit": null, "category": "pantry", "is_pantry_check": true, "notes": "verify stock"}
  ]
}

Sort items by category in this order: produce, bakery, dairy, meat, pantry, frozen, beverages, other.
Put pantry check items at the end within each category.`

  const userPrompt = `Generate an optimized grocery list from these recipes:

${recipesSummary}${staplesText}

Output ONLY the JSON object, no explanation.`

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
        { role: 'assistant', content: '{"items": [' }
      ],
      system: systemPrompt,
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    console.error('Claude API error:', response.status, errorText)
    throw new Error(`Claude API error: ${response.status}`)
  }

  const data = await response.json()
  const content = data.content?.[0]?.text

  if (!content) {
    throw new Error('No content in Claude response')
  }

  // Parse JSON (prepend the prefill we used)
  let jsonStr = '{"items": [' + content.trim()
  if (jsonStr.endsWith('```')) {
    jsonStr = jsonStr.slice(0, -3).trim()
  }

  try {
    const parsed = JSON.parse(jsonStr)
    console.log('Generated', parsed.items?.length || 0, 'grocery items')
    return parsed
  } catch (e) {
    console.error('Failed to parse JSON:', jsonStr.substring(0, 500))
    throw new Error('Failed to parse grocery list response')
  }
}
