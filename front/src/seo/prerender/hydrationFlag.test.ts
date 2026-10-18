import { markPrerendered, isPrerendered, clearPrerendered, documentIsPrerendered } from "./hydrationFlag";

afterEach(() => clearPrerendered());

it("is false until the page is known to be prerendered", () => {
  expect(isPrerendered()).toBe(false);
});

it("reports a prerendered page, then stops once hydration has committed", () => {
  markPrerendered();
  expect(isPrerendered()).toBe(true);
  clearPrerendered();
  expect(isPrerendered()).toBe(false);
});

// documentIsPrerendered() is the DOM-reading twin of the flag above, and it is
// load-bearing for two callers: index.tsx picks hydrateRoot vs createRoot with
// it, and src/utils/i18n.ts decides at *import* time whether to pin the first
// render to English with it. Both answers come from the same question.
it("reads a prerendered document straight off the DOM", () => {
  document.body.innerHTML = '<div id="root"></div>';
  expect(documentIsPrerendered()).toBe(false);

  document.body.innerHTML = '<div id="root"><h1>Say it badly.</h1></div>';
  expect(documentIsPrerendered()).toBe(true);
});

it("is false when there is no root element at all", () => {
  document.body.innerHTML = "";
  expect(documentIsPrerendered()).toBe(false);
});
