import { loadGa, gaEvent, _resetGaForTests } from "./ga";
import { writeConsent, clearConsent, setGaDisabled } from "./consent";

beforeEach(() => {
  _resetGaForTests();
  clearConsent();
  setGaDisabled(false, "G-TEST123");
  document.head.querySelectorAll("script[data-ga]").forEach((s) => s.remove());
});

it("does nothing without a measurement id", () => {
  expect(loadGa("")).toBe(false);
  gaEvent("page_view", { page_path: "/" });
  expect(window.dataLayer).toBeUndefined();
});

it("injects gtag once and forwards events after load", () => {
  writeConsent("granted");
  expect(loadGa("G-TEST123")).toBe(true);
  expect(loadGa("G-TEST123")).toBe(false); // already loaded
  const script = document.head.querySelector("script[data-ga]") as HTMLScriptElement;
  expect(script.src).toContain("googletagmanager.com/gtag/js?id=G-TEST123");
  gaEvent("store_tap", { placement: "hero" });
  const layer = window.dataLayer as any[];
  expect(layer.some((args) => args[0] === "config" && args[1] === "G-TEST123")).toBe(true);
  expect(layer.some((args) => args[0] === "event" && args[1] === "store_tap")).toBe(true);
});

it("drops events while consent is anything but granted", () => {
  writeConsent("granted");
  loadGa("G-TEST123");
  const layer = window.dataLayer as any[];
  const events = () => layer.filter((args) => args[0] === "event").length;
  gaEvent("store_tap", { placement: "hero" });
  expect(events()).toBe(1);

  // Withdrawn mid-session: gtag stays loaded, but nothing more is sent.
  writeConsent("denied");
  gaEvent("store_tap", { placement: "hero" });
  expect(events()).toBe(1);

  clearConsent();
  gaEvent("page_view", { page_path: "/" });
  expect(events()).toBe(1);
});

it("refuses to load while the ga-disable flag is set", () => {
  writeConsent("granted");
  setGaDisabled(true, "G-TEST123");
  expect(loadGa("G-TEST123")).toBe(false);
  expect(document.head.querySelector("script[data-ga]")).toBeNull();
  expect(window.dataLayer).toBeUndefined();

  setGaDisabled(false, "G-TEST123");
  expect(loadGa("G-TEST123")).toBe(true);
});
