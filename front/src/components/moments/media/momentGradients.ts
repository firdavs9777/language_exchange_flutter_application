// Text/gradient moment background presets (Package 3, Task 4).
// Mirrors the gradient keys used by the Flutter app so text moments render
// identically across platforms.

export const MOMENT_GRADIENTS: Record<string, string> = {
  gradient_sunset: 'linear-gradient(135deg, #ff9966, #ff5e8f)',
  gradient_ocean: 'linear-gradient(135deg, #2193b0, #6dd5ed)',
  gradient_forest: 'linear-gradient(135deg, #134e13, #4caf50)',
  gradient_purple: 'linear-gradient(135deg, #8e2de2, #c724b1)',
  gradient_fire: 'linear-gradient(135deg, #cb2d3e, #ff9a44)',
  gradient_midnight: 'linear-gradient(135deg, #0f2027, #3a3d8f)',
  gradient_candy: 'linear-gradient(135deg, #ff6fb0, #9b5de5)',
  gradient_sky: 'linear-gradient(135deg, #a1c4fd, #5ee7df)',
  gradient_neon: 'linear-gradient(135deg, #ff00cc, #00e0ff)',
  gradient_coral: 'linear-gradient(135deg, #ff7e5f, #ffb88c)',
  gradient_gold: 'linear-gradient(135deg, #f7971e, #ffd200)',
  gradient_nightclub: 'linear-gradient(135deg, #3a0ca3, #10002b)',
  gradient_arctic: 'linear-gradient(135deg, #b0e0ff, #eaf6ff)',
};

export const DEFAULT_GRADIENT_KEY = 'gradient_purple';

// The subset the backend enum currently accepts on create. The composer
// should only offer these; the renderer itself tolerates all keys above
// (and anything the backend adds later) via `gradientFor`.
export const BACKEND_VALID_GRADIENTS = [
  'gradient_sunset',
  'gradient_ocean',
  'gradient_forest',
  'gradient_purple',
  'gradient_fire',
  'gradient_midnight',
  'gradient_candy',
  'gradient_sky',
];

/** Resolve a gradient preset key to its CSS gradient, falling back to the default. */
export const gradientFor = (key?: string): string => {
  if (key && MOMENT_GRADIENTS[key]) {
    return MOMENT_GRADIENTS[key];
  }
  return MOMENT_GRADIENTS[DEFAULT_GRADIENT_KEY];
};
