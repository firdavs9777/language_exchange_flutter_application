// Text/gradient moment backgrounds -- the app's 20 presets, same keys, same
// colours, same order (app lib/providers/provider_models/moments_model.dart
// MomentGradients.presets; backend lib/momentGradients.js holds the same ids).
// The app paints topLeft -> bottomRight, which is CSS 135deg.
// A key this list doesn't know (a future preset) renders as the default.

const css = (from: string, to: string) => `linear-gradient(135deg, ${from}, ${to})`;

export const MOMENT_GRADIENT_KEYS: string[] = [
  "gradient_sunset",
  "gradient_ocean",
  "gradient_forest",
  "gradient_purple",
  "gradient_fire",
  "gradient_midnight",
  "gradient_candy",
  "gradient_sky",
  "gradient_neon",
  "gradient_coral",
  "gradient_gold",
  "gradient_nightclub",
  "gradient_arctic",
  "gradient_peach",
  "gradient_lavender",
  "gradient_mint",
  "gradient_rose",
  "gradient_slate",
  "gradient_ember",
  "gradient_lagoon",
];

export const MOMENT_GRADIENTS: Record<string, string> = {
  gradient_sunset: css("#ff512f", "#dd2476"),
  gradient_ocean: css("#2193b0", "#6dd5ed"),
  gradient_forest: css("#11998e", "#38ef7d"),
  gradient_purple: css("#8e2de2", "#4a00e0"),
  gradient_fire: css("#ff416c", "#ff4b2b"),
  gradient_midnight: css("#0f2027", "#2c5364"),
  gradient_candy: css("#d585ff", "#00ffee"),
  gradient_sky: css("#56ccf2", "#2f80ed"),
  gradient_neon: css("#00f260", "#0575e6"),
  gradient_coral: css("#ff6b6b", "#ee5a24"),
  gradient_gold: css("#f7971e", "#ffd200"),
  gradient_nightclub: css("#8e2de2", "#ff6fd8"),
  gradient_arctic: css("#e0eafc", "#cfdef3"),
  gradient_peach: css("#ffb347", "#ffcc33"),
  gradient_lavender: css("#9d50bb", "#6e48aa"),
  gradient_mint: css("#00b09b", "#96c93d"),
  gradient_rose: css("#f4c4f3", "#fc67fa"),
  gradient_slate: css("#485563", "#29323c"),
  gradient_ember: css("#cb356b", "#bd3f32"),
  gradient_lagoon: css("#43c6ac", "#191654"),
};

export const DEFAULT_GRADIENT_KEY = "gradient_purple";

/** Resolve a gradient preset key to its CSS gradient, falling back to the default. */
export const gradientFor = (key?: string): string => {
  if (key && MOMENT_GRADIENTS[key]) {
    return MOMENT_GRADIENTS[key];
  }
  return MOMENT_GRADIENTS[DEFAULT_GRADIENT_KEY];
};
