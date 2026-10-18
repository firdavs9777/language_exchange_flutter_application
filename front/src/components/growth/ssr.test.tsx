/**
 * @jest-environment node
 */
import React from "react";
import { renderToString } from "react-dom/server";
import PromoCarousel from "./PromoCarousel";
import StickyAppBanner from "./StickyAppBanner";

// The growth surfaces decide whether to show from the viewport, referrer and
// stored dismissals -- none of which exist at prerender time. They render
// nothing on the server and decide after mount, so prerendered HTML and the
// first client render agree.
it("PromoCarousel renders nothing without a DOM", () => {
  expect(renderToString(<PromoCarousel />)).toBe("");
});

it("StickyAppBanner renders nothing without a DOM", () => {
  expect(renderToString(<StickyAppBanner />)).toBe("");
});
