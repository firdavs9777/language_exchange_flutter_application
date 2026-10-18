import "@testing-library/jest-dom";
import React from "react";
import { render } from "@testing-library/react";
import { MemoryRouter, matchRoutes } from "react-router-dom";
import fs from "fs";
import path from "path";
import FooterMain from "./FooterMain";
import { routes } from "../../router/routes";

// Importing `routes` below pulls in App.tsx -> src/utils/i18n.ts, which calls
// `i18n.use(initReactI18next)` at module load time. A bare
// `{ useTranslation: ... }` mock replaces the whole react-i18next module, so
// `initReactI18next` becomes undefined and i18next throws before any test
// runs ("You are passing an undefined module!") -- the same trap documented
// in src/components/home/parts/staticSections.test.tsx. Passing through a
// harmless 3rdParty plugin keeps that init call happy while still stubbing
// `t` for FooterMain itself.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (k: string) => k }),
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

it("every internal link leads to a real route, never the catch-all", () => {
  const { container } = render(
    <MemoryRouter>
      <FooterMain />
    </MemoryRouter>
  );
  const hrefs = Array.from(container.querySelectorAll("a[href^='/']")).map((a) => a.getAttribute("href")!);
  expect(hrefs.length).toBeGreaterThan(4);
  for (const href of hrefs) {
    const pathOnly = href.split("#")[0] || "/";
    const matches = matchRoutes(routes, pathOnly);
    expect({ href, matched: matches ? matches[matches.length - 1].route.path : null }).not.toEqual({ href, matched: "*" });
    expect(matches).not.toBeNull();
  }
});

it("links to the download, communities and landing pages", () => {
  const { container } = render(<MemoryRouter><FooterMain /></MemoryRouter>);
  const hrefs = Array.from(container.querySelectorAll("a[href^='/']")).map((a) => a.getAttribute("href"));
  expect(hrefs).toContain("/download");
  expect(hrefs).toContain("/communities");
  expect(hrefs).toContain("/support");
  expect(hrefs).toContain("/meet");
  expect(hrefs).toContain("/learn-korean");
  expect(hrefs).not.toContain("/pricing");
  expect(hrefs).not.toContain("/contact");
});

it("every locale carries the new footer link labels", () => {
  const dir = path.join(__dirname, "../../utils/locales");
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".json"))) {
    const links = JSON.parse(fs.readFileSync(path.join(dir, file), "utf8")).footer.links;
    expect({ file, communities: typeof links.communities, download: typeof links.download })
      .toEqual({ file, communities: "string", download: "string" });
  }
});

// REACT_APP_GA_MEASUREMENT_ID is empty here (and in every environment that has
// not been given one), so there is no analytics to withdraw and the footer
// stays exactly as it was. FooterMain.consent.test.tsx covers the other case.
it("offers no privacy choices control while there is no measurement id", () => {
  const { container } = render(<MemoryRouter><FooterMain /></MemoryRouter>);
  expect(container.querySelector("[data-testid='footer-privacy-choices']")).toBeNull();
});
