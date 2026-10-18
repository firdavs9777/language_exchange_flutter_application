import { canonicalUrl } from "../pages";

export function buildSitemap(paths: string[], date: Date): string {
  const lastmod = date.toISOString().slice(0, 10);
  const urls = paths
    .map((p) => `  <url>\n    <loc>${canonicalUrl(p)}</loc>\n    <lastmod>${lastmod}</lastmod>\n  </url>`)
    .join("\n");
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`;
}
