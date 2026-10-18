import * as gradients from "./momentGradients";
import { MOMENT_GRADIENTS, MOMENT_GRADIENT_KEYS, DEFAULT_GRADIENT_KEY, gradientFor } from "./momentGradients";

// The app's list, in its order (moments_model.dart MomentGradients.presets)
// and the backend's (lib/momentGradients.js) -- one list on three clients.
const APP_KEYS = [
  "gradient_sunset", "gradient_ocean", "gradient_forest", "gradient_purple",
  "gradient_fire", "gradient_midnight", "gradient_candy", "gradient_sky",
  "gradient_neon", "gradient_coral", "gradient_gold", "gradient_nightclub",
  "gradient_arctic", "gradient_peach", "gradient_lavender", "gradient_mint",
  "gradient_rose", "gradient_slate", "gradient_ember", "gradient_lagoon",
];

it("offers exactly the app's 20 gradients, in the app's order", () => {
  expect(MOMENT_GRADIENT_KEYS).toEqual(APP_KEYS);
  expect(Object.keys(MOMENT_GRADIENTS)).toEqual(APP_KEYS);
});

it("uses the app's colours, top-left to bottom-right", () => {
  expect(MOMENT_GRADIENTS.gradient_sunset).toBe("linear-gradient(135deg, #ff512f, #dd2476)");
  expect(MOMENT_GRADIENTS.gradient_forest).toBe("linear-gradient(135deg, #11998e, #38ef7d)");
  expect(MOMENT_GRADIENTS.gradient_nightclub).toBe("linear-gradient(135deg, #8e2de2, #ff6fd8)");
  expect(MOMENT_GRADIENTS.gradient_lagoon).toBe("linear-gradient(135deg, #43c6ac, #191654)");
});

it("defaults to purple for unknown, empty or missing keys", () => {
  expect(DEFAULT_GRADIENT_KEY).toBe("gradient_purple");
  expect(gradientFor("gradient_nope")).toBe(MOMENT_GRADIENTS.gradient_purple);
  expect(gradientFor("")).toBe(MOMENT_GRADIENTS.gradient_purple);
  expect(gradientFor(undefined)).toBe(MOMENT_GRADIENTS.gradient_purple);
});

it("no longer exports the stale 8-key backend list", () => {
  expect((gradients as any).BACKEND_VALID_GRADIENTS).toBeUndefined();
});
