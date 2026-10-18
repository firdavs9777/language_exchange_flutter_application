import path from "path";
import resolveConfig from "tailwindcss/resolveConfig";
import { BANANA, BRAND, BRAND_DEEP, BRAND_LIGHT, INK_100, INK_200, INK_500, INK_900, WHITE } from "./paint";

// Same idiom as src/design/tokens.test.ts: require() with an absolute path,
// because CRA's ModuleScopePlugin forbids importing from outside src/.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const tailwindConfig = require(path.resolve(__dirname, "../../../../tailwind.config.js"));
const colors = (resolveConfig(tailwindConfig) as any).theme.colors;

// The illustrations cannot paint with a Tailwind class, so they carry the
// palette as literals. This is the leash on that: every colour the promo art
// uses is the colour the rest of the site uses, or this fails.
it("paints the promo art from the site's own palette", () => {
  expect(BRAND).toBe(colors.brand.DEFAULT);
  expect(BRAND_LIGHT).toBe(colors.brand.light);
  expect(BRAND_DEEP).toBe(colors.brand.deep);
  expect(BANANA).toBe(colors.banana.DEFAULT);
  expect(WHITE).toBe(colors.surface.DEFAULT);
  expect(INK_100).toBe(colors.ink[100]);
  expect(INK_200).toBe(colors.ink[200]);
  expect(INK_500).toBe(colors.ink[500]);
  expect(INK_900).toBe(colors.ink[900]);
});
