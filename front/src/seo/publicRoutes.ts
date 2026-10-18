import { SEO_PAGES } from "./pages";

/** Indexed pages; written to the sitemap. */
export const SITEMAP_PATHS: string[] = SEO_PAGES.map((p) => p.path);

/** Everything written to build/<path>/index.html. Dynamic routes never appear here. */
export const PRERENDER_PATHS: string[] = [...SITEMAP_PATHS, "/404"];

/**
 * Paths that used to be prerendered and no longer are. The deploy copies
 * build/ over the live folder without deleting anything, so the old
 * build/<path>/index.html stays on the server and nginx's `$uri/index.html`
 * would keep serving it -- along with the stale JS it references.
 * buildNginxRoutesConf pins each of these to the SPA shell instead.
 *
 * /communities: members-only since 2026-10-16 (src/seo/pages.ts).
 */
export const WITHDRAWN_PRERENDER_PATHS: string[] = ["/communities"];
