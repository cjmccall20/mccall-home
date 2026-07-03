import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts"
import {
  isTikTokUrl,
  isTikTokShortLink,
  extractOgDescription,
  decodeHtmlEntities,
  extractHashtags,
} from "../scrape-recipe/tiktok.ts"
import { extractFirstJsonObject } from "../scrape-recipe/parsing.ts"

Deno.test("isTikTokUrl matrix", () => {
  const yes = [
    "https://www.tiktok.com/@chef/video/7301234567890123456",
    "https://tiktok.com/@chef/video/123",
    "https://m.tiktok.com/v/123.html",
    "https://vm.tiktok.com/ZM8abc123/",
    "https://vt.tiktok.com/ZS8abc123/",
    "http://www.tiktok.com/@a/video/1?is_from_webapp=1",
    "HTTPS://WWW.TIKTOK.COM/@Chef/video/1",
  ]
  const no = [
    "https://www.allrecipes.com/recipe/12345",
    "https://nottiktok.com/@chef/video/1",
    "https://tiktok.com.evil.com/x",
    "https://www.youtube.com/watch?v=abc",
    "not a url",
    "",
    "https://faketiktok.com/video",
  ]
  for (const url of yes) assertEquals(isTikTokUrl(url), true, url)
  for (const url of no) assertEquals(isTikTokUrl(url), false, url)
})

Deno.test("isTikTokShortLink", () => {
  assertEquals(isTikTokShortLink("https://vm.tiktok.com/ZM8abc/"), true)
  assertEquals(isTikTokShortLink("https://vt.tiktok.com/ZS8abc/"), true)
  assertEquals(isTikTokShortLink("https://www.tiktok.com/@a/video/1"), false)
  assertEquals(isTikTokShortLink("garbage"), false)
})

Deno.test("extractOgDescription attribute orders and entities", () => {
  const html1 = `<html><head><meta property="og:description" content="Creamy garlic pasta! 1 lb pasta &amp; 4 cloves garlic"/></head></html>`
  assertEquals(
    extractOgDescription(html1),
    "Creamy garlic pasta! 1 lb pasta & 4 cloves garlic",
  )

  const html2 = `<meta content="Recipe: 2 cups flour &#39;sifted&#39;" property="og:description">`
  assertEquals(extractOgDescription(html2), "Recipe: 2 cups flour 'sifted'")

  const html3 = `<meta property="og:title" content="something else">`
  assertEquals(extractOgDescription(html3), null)

  const html4 = `<meta property="og:description" content="">`
  assertEquals(extractOgDescription(html4), null)
})

Deno.test("decodeHtmlEntities", () => {
  assertEquals(decodeHtmlEntities("a &amp; b &lt;c&gt; &quot;d&quot;"), 'a & b <c> "d"')
  assertEquals(decodeHtmlEntities("&#x1F35D; noodles"), "\u{1F35D} noodles")
  assertEquals(decodeHtmlEntities("&#233;clair"), "éclair")
  assertEquals(decodeHtmlEntities("plain text"), "plain text")
})

Deno.test("extractHashtags", () => {
  assertEquals(
    extractHashtags("Best pasta ever!! #pasta #EasyRecipe #dinner #pasta"),
    ["pasta", "easyrecipe", "dinner"],
  )
  assertEquals(extractHashtags("no tags here"), [])
})

Deno.test("extractFirstJsonObject basics", () => {
  assertEquals(extractFirstJsonObject(`{"a":1}`), `{"a":1}`)
  assertEquals(extractFirstJsonObject(`junk before {"a":{"b":2}} junk after`), `{"a":{"b":2}}`)
  // braces inside strings must not confuse the counter
  assertEquals(
    extractFirstJsonObject(`{"step":"mix {well} until \\"done\\"}","n":1}`),
    `{"step":"mix {well} until \\"done\\"}","n":1}`,
  )
  // unbalanced (truncated) input
  assertEquals(extractFirstJsonObject(`{"a": [1, 2,`), null)
  assertEquals(extractFirstJsonObject(`no json at all`), null)
})

Deno.test("extractFirstJsonObject with fence-stripped realistic response", () => {
  const prefillPlusResponse = '{' + `"title":"Garlic Butter Shrimp","ingredients":[{"name":"shrimp","quantity":1,"unit":"lb","notes":null}],"steps":[{"step_number":1,"instruction":"Melt butter"}],"prep_time":10,"cook_time":10,"base_servings":4,"dish_category":"entree","protein_type":"shrimp","tags":[]}`
  const defenced = prefillPlusResponse.replace(/```(?:json)?/g, '').trim()
  const parsed = JSON.parse(extractFirstJsonObject(defenced)!)
  assertEquals(parsed.title, "Garlic Butter Shrimp")
  assertEquals(parsed.ingredients.length, 1)
})
