import React from "react";
import { renderToString } from "react-dom/server";
import { HelmetProvider } from "react-helmet-async";
import { MemoryRouter } from "react-router-dom";
import RouteMeta from "./RouteMeta";

// react-helmet-async infers server vs. client from `typeof document`, which is
// truthy under jsdom; without this it defers to a real DOM update and
// `ctx.helmet` stays null. Documented in the library's own README ("Usage in
// Jest").
HelmetProvider.canUseDOM = false;

// t returns "" so the English fallback path is exercised, exactly as a locale
// with a missing key would behave in production.
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

function headFor(path: string) {
  const ctx: any = {};
  renderToString(
    <HelmetProvider context={ctx}>
      <MemoryRouter initialEntries={[path]}>
        <RouteMeta />
      </MemoryRouter>
    </HelmetProvider>
  );
  const h = ctx.helmet;
  return [h.title.toString(), h.meta.toString(), h.link.toString()].join("\n");
}

it("renders the indexable tag set for the homepage", () => {
  const head = headFor("/");
  expect(head).toContain("<title data-rh=\"true\">BananaTalk: Free Language Exchange App with Native Speakers</title>");
  expect(head).toContain('name="description"');
  expect(head).toContain('rel="canonical" href="https://banatalk.com"');
  expect(head).toContain('property="og:url" content="https://banatalk.com"');
  expect(head).toContain('name="twitter:card" content="summary_large_image"');
  expect(head).toContain('name="robots" content="index, follow');
});

it("drops the trailing slash from the canonical", () => {
  expect(headFor("/privacy-policy/")).toContain('href="https://banatalk.com/privacy-policy"');
});

it("marks app-only routes noindex with a plain title", () => {
  const head = headFor("/chat");
  expect(head).toContain('name="robots" content="noindex, nofollow"');
  expect(head).toContain("<title data-rh=\"true\">BananaTalk</title>");
  expect(head).not.toContain('rel="canonical"');
});
