/**
 * The conversation wallpapers, as the app ships them.
 *
 * Names are the contract. The backend stores `conversation.theme.preset` as a
 * free string and pushes it to the other participant over `themeChanged`, so a
 * wallpaper chosen in the Flutter app has to mean the same thing here — these
 * names and colours are lifted verbatim from
 * `lib/pages/chat/wallpaper/wallpaper_picker_screen.dart` (`_getPresets` and
 * `_gradients`). The coin-gated `premium_*` pack
 * (`wallpaper/premium_wallpapers.dart`) is RENDER-ONLY here (PREMIUM_WALLPAPERS
 * below): the web sells no unlock, so the picker does not offer it, but a chat
 * an app user dressed in one paints it.
 *
 * The colours live here rather than in a chat component because the chat
 * folder is token-only now (src/components/chat/chatStyling.test.ts). They are
 * here for TWO reasons, and painting is not one of them: the picker's swatches
 * and the chat pane both paint from the `[data-chat-theme="…"]` rules in
 * src/index.css. These values are what the PUT body carries, so a wallpaper
 * set on the web renders on a phone whose app reads `backgroundColor` /
 * `gradientColors` off the saved theme. src/components/chat/chatTokens.test.ts
 * fails if the two lists drift apart.
 */

export interface ChatWallpaper {
  /** The preset name stored on the conversation. */
  name: string;
  /** English fallback; the key is `chatPage.wallpaper.<name>`. */
  label: string;
  /** Solid ground, spelled as the app spells it. */
  backgroundColor?: string;
  /** Gradient stops, in order, spelled as the app spells them. */
  gradientColors?: string[];
}

/** "Whatever the surface is" — no override, and what a new conversation has. */
export const DEFAULT_WALLPAPER = "default";

export const SOLID_WALLPAPERS: ChatWallpaper[] = [
  { name: "cream", label: "Cream", backgroundColor: "#f5e6d3" },
  { name: "blush", label: "Blush", backgroundColor: "#e8b4bc" },
  { name: "peach", label: "Peach", backgroundColor: "#e6a67c" },
  { name: "sage", label: "Sage", backgroundColor: "#4a5d4a" },
  { name: "ocean", label: "Ocean", backgroundColor: "#1e3a5f" },
  { name: "teal", label: "Teal", backgroundColor: "#115e59" },
  { name: "forest", label: "Forest", backgroundColor: "#1b4332" },
  { name: "rose", label: "Rose", backgroundColor: "#8b3a62" },
  { name: "wine", label: "Wine", backgroundColor: "#4a1942" },
  { name: "plum", label: "Plum", backgroundColor: "#5b2c6f" },
  { name: "navy", label: "Navy", backgroundColor: "#0a1628" },
  { name: "mocha", label: "Mocha", backgroundColor: "#4a3728" },
  { name: "slate", label: "Slate", backgroundColor: "#1e293b" },
  { name: "ember", label: "Ember", backgroundColor: "#3b1a1a" },
  { name: "deep_sea", label: "Deep sea", backgroundColor: "#0b2545" },
  { name: "charcoal", label: "Charcoal", backgroundColor: "#2d2d2d" },
  { name: "midnight", label: "Midnight", backgroundColor: "#1a1a2e" },
  { name: "dark", label: "Dark", backgroundColor: "#0d0d0d" },
];

export const GRADIENT_WALLPAPERS: ChatWallpaper[] = [
  { name: "gradient_sunset", label: "Sunset", gradientColors: ["#ff512f", "#dd2476"] },
  { name: "gradient_ocean", label: "Ocean", gradientColors: ["#2193b0", "#6dd5ed"] },
  {
    name: "gradient_aurora",
    label: "Aurora",
    gradientColors: ["#0f2027", "#203a43", "#2c5364"],
  },
  { name: "gradient_purple", label: "Cosmic", gradientColors: ["#667eea", "#764ba2"] },
  { name: "gradient_midnight", label: "Midnight", gradientColors: ["#232526", "#414345"] },
  { name: "gradient_forest", label: "Forest", gradientColors: ["#134e5e", "#71b280"] },
  { name: "gradient_rose", label: "Rose gold", gradientColors: ["#b76e79", "#e8b4b8"] },
  { name: "gradient_candy", label: "Candy", gradientColors: ["#ff9a9e", "#fecfef"] },
  { name: "gradient_neon", label: "Neon", gradientColors: ["#00f260", "#0575e6"] },
  { name: "gradient_fire", label: "Fire", gradientColors: ["#f12711", "#f5af19"] },
  { name: "gradient_winter", label: "Winter", gradientColors: ["#e6dada", "#274046"] },
  { name: "gradient_lavender", label: "Lavender", gradientColors: ["#ee9ca7", "#ffdde1"] },
];

export const CHAT_WALLPAPERS: ChatWallpaper[] = SOLID_WALLPAPERS.concat(
  GRADIENT_WALLPAPERS
);

export const PREMIUM_WALLPAPER_PREFIX = "premium_";

/**
 * The app's coin-unlocked Premium pack (lib/pages/chat/wallpaper/
 * premium_wallpapers.dart), colours verbatim, drawn top-left to bottom-right.
 * Not offered by the picker; painted when a conversation already wears one.
 */
export const PREMIUM_WALLPAPERS: ChatWallpaper[] = [
  { name: "premium_aurora_borealis", label: "Aurora Borealis", gradientColors: ["#00c9ff", "#92fe9d", "#fc466b"] },
  { name: "premium_golden_hour", label: "Golden Hour", gradientColors: ["#ffd700", "#ff8c00", "#ff4500"] },
  { name: "premium_galaxy", label: "Galaxy", gradientColors: ["#0f0c29", "#302b63", "#24243e"] },
  { name: "premium_emerald_luxe", label: "Emerald Luxe", gradientColors: ["#11998e", "#38ef7d"] },
  { name: "premium_royal_velvet", label: "Royal Velvet", gradientColors: ["#360033", "#0b8793"] },
  { name: "premium_diamond_shine", label: "Diamond Shine", gradientColors: ["#b993d6", "#8ca6db"] },
];

export function isPremiumWallpaper(name: string | null | undefined): boolean {
  return typeof name === "string" && name.indexOf(PREMIUM_WALLPAPER_PREFIX) === 0;
}

/**
 * The body the PUT carries for a preset: the name plus the colours, so the
 * app — which renders a saved theme from `backgroundColor`/`gradientColors` —
 * shows the same wallpaper the web just chose. "default" carries the name
 * alone, which is what clears a wallpaper.
 */
export function themePayload(preset: string): { [key: string]: any } {
  const theme: { [key: string]: any } = { preset: preset };
  for (let i = 0; i < CHAT_WALLPAPERS.length; i += 1) {
    const wallpaper = CHAT_WALLPAPERS[i];
    if (wallpaper.name !== preset) continue;
    if (wallpaper.backgroundColor) theme.backgroundColor = wallpaper.backgroundColor;
    if (wallpaper.gradientColors) theme.gradientColors = wallpaper.gradientColors;
    break;
  }
  return theme;
}
