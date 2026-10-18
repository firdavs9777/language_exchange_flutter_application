/**
 * A story's `backgroundColor`, which is not always a colour.
 *
 * The app's text-story composer stores a GRADIENT ID there (`gradient_sunset`,
 * ...: `lib/pages/stories/models/story_gradient.dart`), while older app builds
 * and the web composer store a `#RRGGBB` hex. Painting the id as a CSS colour
 * is invalid CSS, so the browser dropped it and every app-made text story
 * rendered on the fallback black.
 *
 * The colours below mirror `StoryGradient.presets` exactly (the app paints
 * them top-left -> bottom-right). They are story DATA, which is why they end
 * up in an inline style like the hex colours beside them. Note the story
 * presets are not the same as the moment gradients of the same names.
 *
 * Kept free of browser globals at import time so the prerender can load it.
 */
export const STORY_GRADIENTS: { [id: string]: string[] } = {
  gradient_sunset: ["#FF512F", "#F09819"],
  gradient_ocean: ["#2193B0", "#6DD5ED"],
  gradient_forest: ["#134E5E", "#71B280"],
  gradient_purple: ["#8E2DE2", "#4A00E0"],
  gradient_fire: ["#EB5757", "#F2994A"],
  gradient_midnight: ["#232526", "#414345"],
  gradient_candy: ["#FC466B", "#3F5EFB"],
  gradient_sky: ["#56CCF2", "#2F80ED"],
  gradient_aurora: ["#00C9FF", "#92FE9D"],
  gradient_peach: ["#ED4264", "#FFEDBC"],
  gradient_mint: ["#00B09B", "#96C93D"],
  gradient_lavender: ["#E1B0FF", "#B39DDB"],
  gradient_galaxy: ["#0F2027", "#203A43", "#2C5364"],
};

const HEX_COLOR = /^#(?:[0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i;

/** Whether `value` is something CSS will paint as a colour. */
export function isCssColor(value: string): boolean {
  if (HEX_COLOR.test(value)) return true;
  const css: any = typeof window !== "undefined" ? (window as any).CSS : undefined;
  if (css && typeof css.supports === "function") {
    try {
      return Boolean(css.supports("color", value));
    } catch (e) {
      return false;
    }
  }
  // No CSS.supports (the prerender, very old browsers): functional and named
  // colours, nothing that could smuggle in another property.
  return /^(?:rgba?|hsla?)\([\d\s.,%/+-]+\)$/i.test(value) || /^[a-z]+$/i.test(value);
}

/** The CSS gradient for an app gradient id, or null for anything else. */
export function storyGradientCss(value?: string | null): string | null {
  const id = typeof value === "string" ? value.trim() : "";
  const colors = id ? STORY_GRADIENTS[id] : undefined;
  return colors ? "linear-gradient(to bottom right, " + colors.join(", ") + ")" : null;
}

/**
 * Inline style for a story background: the app gradient, the colour, or
 * nothing at all -- in which case the element's own class keeps its default.
 */
export function storyBackgroundStyle(
  value?: string | null
): { backgroundImage?: string; backgroundColor?: string } {
  const gradient = storyGradientCss(value);
  if (gradient) return { backgroundImage: gradient };
  const raw = typeof value === "string" ? value.trim() : "";
  if (raw && raw.indexOf("gradient_") !== 0 && isCssColor(raw)) return { backgroundColor: raw };
  return {};
}

/** A story's text colour, when it is a colour CSS can paint. */
export function storyTextColor(value?: string | null): string | undefined {
  const raw = typeof value === "string" ? value.trim() : "";
  return raw && isCssColor(raw) ? raw : undefined;
}
