import path from "path";
import resolveConfig from "tailwindcss/resolveConfig";

// require() with an absolute path, not a relative import: CRA's webpack
// ModuleScopePlugin forbids importing from outside src/, and while Jest does
// not enforce that, keeping it a runtime require avoids the rule entirely.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const tailwindConfig = require(path.resolve(__dirname, "../../tailwind.config.js"));
const theme = (resolveConfig(tailwindConfig) as any).theme;

it("exposes the app's brand palette", () => {
  expect(theme.colors.brand.DEFAULT).toBe("#00BFA5");
  expect(theme.colors.brand.light).toBe("#5DF2D6");
  expect(theme.colors.brand.dark).toBe("#008E76");
  expect(theme.colors.banana.DEFAULT).toBe("#FFD54F");
  expect(theme.colors.banana.dark).toBe("#C9A415");
});

it("exposes the app's surface colours in both themes", () => {
  expect(theme.colors.surface.DEFAULT).toBe("#FFFFFF");
  expect(theme.colors.surface.dark).toBe("#1E1E1E");
  expect(theme.colors.canvas.DEFAULT).toBe("#F8F9FA");
  expect(theme.colors.cardbg.dark).toBe("#2C2C2C");
});

it("exposes the app's radii and shadows", () => {
  expect(theme.borderRadius.card).toBe("20px");
  expect(theme.borderRadius.chip).toBe("12px");
  expect(theme.borderRadius.sheet).toBe("24px");
  expect(theme.boxShadow.card).toBe("0 1px 4px rgba(0,0,0,0.04)");
  expect(theme.boxShadow.raised).toBe("0 2px 8px rgba(0,0,0,0.06)");
  expect(theme.boxShadow.float).toBe("0 4px 16px rgba(0,0,0,0.08)");
  expect(theme.boxShadow.brand).toBe("0 6px 16px rgba(0,191,165,0.30)");
});

// The guard. Overriding colors.teal replaces Tailwind's whole scale rather
// than merging into it, which would stop 327 teal-N usages across 49 files
// from emitting any CSS -- silently, with no build error. Same class of
// problem for the radius and shadow scales.
it("leaves Tailwind's own scales untouched", () => {
  expect(theme.colors.teal["500"]).toBe("#14b8a6");
  expect(theme.colors.teal["50"]).toBeDefined();
  expect(theme.colors.teal["900"]).toBeDefined();
  expect(theme.borderRadius.xl).toBe("0.75rem");
  expect(theme.borderRadius.lg).toBe("0.5rem");
  expect(theme.boxShadow.lg).toContain("10px 15px");
  expect(theme.colors.gray["500"]).toBe("#6b7280");
});
