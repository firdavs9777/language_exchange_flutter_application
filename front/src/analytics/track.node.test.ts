/**
 * @jest-environment node
 */
import { trackEvent } from "./track";

it("never sends during prerender (no window)", () => {
  (global as any).fetch = jest.fn();
  expect(() => trackEvent("page_view", { path: "/" })).not.toThrow();
  expect(global.fetch).not.toHaveBeenCalled();
});
