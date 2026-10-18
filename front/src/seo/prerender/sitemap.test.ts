import { buildSitemap } from "./sitemap";
import { SITEMAP_PATHS, PRERENDER_PATHS } from "../publicRoutes";
import { SEO_PAGES } from "../pages";

it("lists exactly the indexed pages, never the 404", () => {
  const xml = buildSitemap(SITEMAP_PATHS, new Date("2026-09-22T10:00:00Z"));
  const locs = Array.from(xml.matchAll(/<loc>([^<]+)<\/loc>/g)).map((m) => m[1]);
  expect(locs).toEqual(SEO_PAGES.map((p) => (p.path === "/" ? "https://banatalk.com" : `https://banatalk.com${p.path}`)));
  expect(xml).not.toContain("/404");
  expect(xml).toContain("<lastmod>2026-09-22</lastmod>");
  expect(xml.startsWith('<?xml version="1.0" encoding="UTF-8"?>')).toBe(true);
});

it("prerenders every sitemap page plus the 404", () => {
  expect(PRERENDER_PATHS).toEqual([...SITEMAP_PATHS, "/404"]);
});
