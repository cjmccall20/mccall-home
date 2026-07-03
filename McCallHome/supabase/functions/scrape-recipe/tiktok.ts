// TikTok caption extraction for the scrape-recipe function.
//
// TikTok video pages can't be scraped with Firecrawl (the recipe text is in
// the video caption, rendered client-side). Instead we read the caption via
// TikTok's public oEmbed API, falling back to the og:description meta tag on
// the raw HTML, and hand that text to the same Claude parsing step used for
// regular recipe pages.

const TIKTOK_HOSTS = ['tiktok.com', 'www.tiktok.com', 'm.tiktok.com']
const TIKTOK_SHORT_HOSTS = ['vm.tiktok.com', 'vt.tiktok.com']

const BROWSER_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

export function isTikTokUrl(rawUrl: string): boolean {
  const host = hostOf(rawUrl)
  if (!host) return false
  return TIKTOK_HOSTS.includes(host) || TIKTOK_SHORT_HOSTS.includes(host)
}

export function isTikTokShortLink(rawUrl: string): boolean {
  const host = hostOf(rawUrl)
  return host !== null && TIKTOK_SHORT_HOSTS.includes(host)
}

function hostOf(rawUrl: string): string | null {
  try {
    return new URL(rawUrl).hostname.toLowerCase()
  } catch {
    return null
  }
}

/** Follow vm./vt. share links to the canonical video URL. */
export async function resolveShortLink(rawUrl: string): Promise<string> {
  try {
    const response = await fetch(rawUrl, {
      method: 'HEAD',
      redirect: 'follow',
      headers: { 'User-Agent': BROWSER_UA },
    })
    // response.url is the final URL after redirects
    return response.url && isTikTokUrl(response.url) ? response.url : rawUrl
  } catch {
    return rawUrl
  }
}

/** Pull the og:description content out of a TikTok page's HTML. */
export function extractOgDescription(html: string): string | null {
  // Attribute order varies; match content=... on the og:description tag
  const patterns = [
    /<meta[^>]*property=["']og:description["'][^>]*content=["']([^"']*)["']/i,
    /<meta[^>]*content=["']([^"']*)["'][^>]*property=["']og:description["']/i,
  ]
  for (const pattern of patterns) {
    const match = html.match(pattern)
    if (match && match[1]) {
      const decoded = decodeHtmlEntities(match[1]).trim()
      if (decoded.length > 0) return decoded
    }
  }
  return null
}

export function decodeHtmlEntities(text: string): string {
  const named: Record<string, string> = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
  }
  return text
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(parseInt(dec, 10)))
    .replace(/&[a-zA-Z]+;|&#\d+;/g, (entity) => named[entity] ?? entity)
}

/** Hashtags often name the dish; surface them as candidate tags. */
export function extractHashtags(caption: string): string[] {
  const matches = caption.match(/#([\p{L}\p{N}_]+)/gu) ?? []
  const tags = matches.map((tag) => tag.slice(1).toLowerCase())
  return [...new Set(tags)]
}

export interface TikTokCaptionResult {
  caption: string | null
  canonicalUrl: string
}

/**
 * Fetch a TikTok video's caption. Tries oEmbed first (official, stable),
 * then falls back to scraping og:description from the page HTML.
 */
export async function fetchTikTokCaption(rawUrl: string): Promise<TikTokCaptionResult> {
  const canonicalUrl = isTikTokShortLink(rawUrl) ? await resolveShortLink(rawUrl) : rawUrl

  // oEmbed accepts both short and canonical links; try the URL as pasted
  // first, then the resolved one if they differ.
  const candidates = canonicalUrl === rawUrl ? [rawUrl] : [rawUrl, canonicalUrl]
  for (const candidate of candidates) {
    const caption = await fetchOEmbedTitle(candidate)
    if (caption) return { caption, canonicalUrl }
  }

  const caption = await fetchPageDescription(canonicalUrl)
  return { caption, canonicalUrl }
}

async function fetchOEmbedTitle(videoUrl: string): Promise<string | null> {
  try {
    const response = await fetch(
      `https://www.tiktok.com/oembed?url=${encodeURIComponent(videoUrl)}`,
      { headers: { 'User-Agent': BROWSER_UA } },
    )
    if (!response.ok) return null
    const data = await response.json()
    const title = typeof data?.title === 'string' ? data.title.trim() : ''
    return title.length > 0 ? title : null
  } catch {
    return null
  }
}

async function fetchPageDescription(videoUrl: string): Promise<string | null> {
  try {
    const response = await fetch(videoUrl, {
      redirect: 'follow',
      headers: { 'User-Agent': BROWSER_UA },
    })
    if (!response.ok) return null
    const html = await response.text()
    return extractOgDescription(html)
  } catch {
    return null
  }
}
