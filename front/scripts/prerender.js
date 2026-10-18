#!/usr/bin/env node
// Runs after `react-scripts build`. Renders each public route to static HTML
// so crawlers see content, and writes the sitemap from the same route list.
// Data fetches may fail (logged as warnings); rendering may not (the build
// fails). See docs/superpowers/specs/2026-09-22-reach-marketing-admin-design.md §4.2.
require("./register");

const fs = require("fs");
const path = require("path");
const { renderRoute } = require("../src/seo/prerender/renderRoute");
const { PRERENDER_PATHS, SITEMAP_PATHS, WITHDRAWN_PRERENDER_PATHS } = require("../src/seo/publicRoutes");
const { buildSitemap } = require("../src/seo/prerender/sitemap");
const { buildNginxRoutesConf } = require("../src/seo/prerender/nginxRoutes");
const { routes } = require("../src/router/routes");
const { injectIntoTemplate } = require("../src/seo/prerender/template");

const BUILD = path.join(__dirname, "..", "build");
const templatePath = path.join(BUILD, "index.html");
if (!fs.existsSync(templatePath)) {
  console.error("[prerender] build/index.html not found; run react-scripts build first");
  process.exit(1);
}
// Read once, before "/" overwrites build/index.html.
const template = fs.readFileSync(templatePath, "utf8");
// The untouched SPA shell. nginx falls back to it for app routes that have no
// prerendered page (/login, /settings, /admin/...). Falling back to index.html
// would hand React the prerendered homepage markup for a different route, and
// hydration would fail (React #418) on every one of those pages.
fs.writeFileSync(path.join(BUILD, "app.html"), template);

const fileFor = (route) => {
  if (route === "/") return path.join(BUILD, "index.html");
  if (route === "/404") return path.join(BUILD, "404.html");
  return path.join(BUILD, route.slice(1), "index.html");
};

(async () => {
  for (const route of PRERENDER_PATHS) {
    const out = await renderRoute(route, { log: (m) => console.warn(`[prerender] warning: ${m}`) });
    const file = fileFor(route);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, injectIntoTemplate(template, out));
    console.log(`[prerender] ${route} -> ${path.relative(BUILD, file)} (${out.status}, ${out.html.length} bytes)`);
  }
  fs.writeFileSync(path.join(BUILD, "sitemap.xml"), buildSitemap(SITEMAP_PATHS, new Date()));
  console.log(`[prerender] sitemap.xml (${SITEMAP_PATHS.length} urls)`);

  // The route allowlist nginx includes: anything outside it is a real 404
  // instead of a 200 with an empty SPA shell. See deploy/nginx.snippet.conf.
  const nginxConf = buildNginxRoutesConf(routes, WITHDRAWN_PRERENDER_PATHS);
  fs.writeFileSync(path.join(BUILD, "nginx.routes.conf"), nginxConf);
  const segments = (nginxConf.match(/\^\/\(([^)]*)\)/) || ["", ""])[1].split("|").filter(Boolean);
  console.log(`[prerender] nginx.routes.conf (${segments.length} route segments)`);
})().catch((err) => {
  console.error("[prerender] FAILED:", err);
  process.exit(1);
});
