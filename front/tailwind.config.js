// tailwind.config.js
//
// Tokens ported from the Flutter app's lib/core/theme/app_theme.dart so the
// two products share one visual vocabulary.
//
// These are ADDITIVE and brand-named on purpose. An earlier draft overrode
// `teal`, `borderRadius` and `boxShadow` so that reaching for a Tailwind
// default produced the app's value. Measured against this codebase that would
// have broken 327 `teal-N` usages across 49 files (Tailwind REPLACES a colour
// scale rather than merging it), moved 232 radius call sites and re-weighted
// 102 shadows, including in Chat and Learning which no current sub-project
// touches. src/design/tokens.test.ts guards against reintroducing that.
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // `deep` is the accessible member of the family: white text on
        // #00BFA5 is 2.33:1 and on #008E76 is 4.09:1, both under AA. #00806A
        // clears it at 4.89:1, so any brand fill that carries small white
        // text uses `deep`; DEFAULT and `dark` stay for large or decorative
        // fills.
        brand: { DEFAULT: "#00BFA5", light: "#5DF2D6", dark: "#008E76", deep: "#00806A", deepest: "#00654F" }, // AppColors.primary
        banana: { DEFAULT: "#FFD54F", light: "#FFFF81", dark: "#C9A415" }, // AppColors.secondary
        surface: { DEFAULT: "#FFFFFF", dark: "#1E1E1E" },
        canvas: { DEFAULT: "#F8F9FA", dark: "#121212" },
        cardbg: { DEFAULT: "#FFFFFF", dark: "#2C2C2C" },
        // Neutral scale of our own. Tailwind's `gray` is cool-blue and reads
        // cheap beside the teal brand; `ink` is a degree warmer and goes
        // deeper at the top end, which is what gives the navbar and footer
        // their weight. Additive -- `gray-N` is untouched.
        ink: {
          50: "#F7F8FA",
          100: "#EEF1F5",
          200: "#DFE4EB",
          300: "#C7CFDA",
          400: "#98A3B4",
          500: "#6B7686",
          600: "#4E5868",
          700: "#3A4352",
          800: "#262E3B",
          900: "#171E29",
          950: "#0D131C",
        },
        // Hairlines. A border is not a light gray text colour; naming it
        // stops the two from being swapped by accident.
        line: { DEFAULT: "#E5E9F0", strong: "#D3DAE4", dark: "#2F3641" },
      },
      fontFamily: {
        // Inter for UI text (tall x-height, real tabular figures), Plus Jakarta
        // Sans for headings (geometric, a little more character than Inter at
        // display sizes without turning playful). Self-hosted: see src/fonts.css.
        sans: [
          "Inter",
          "system-ui",
          "-apple-system",
          "BlinkMacSystemFont",
          '"Segoe UI"',
          "Roboto",
          '"Helvetica Neue"',
          "Arial",
          '"Noto Sans"',
          "sans-serif",
        ],
        display: [
          '"Plus Jakarta Sans"',
          "Inter",
          "system-ui",
          "-apple-system",
          '"Segoe UI"',
          "sans-serif",
        ],
        // Story handwriting face. The app draws `handwriting` text stories and
        // `handwritten` overlays in Caveat; no webfont ships for one sticker
        // style (src/fonts.test.ts pins the self-hosted set), so Caveat is named
        // first for machines that have it and the OS handwriting faces follow.
        hand: ['Caveat', '"Segoe Print"', '"Bradley Hand"', '"Comic Sans MS"', "cursive"],
      },
      letterSpacing: {
        // The two negative steps of Tailwind's scale, with their own values,
        // behind the variables src/index.css zeroes for Hangul, kana, Han,
        // Thai, Arabic and Devanagari. Without this the :lang() reset would
        // not reach the homepage hero: its <h1> carries `tracking-tight`, and
        // a utility class beats the base h1 rule no matter what that rule
        // reads its value from. The positive steps (wide/wider/widest) are
        // untouched -- loosening a syllabic script is harmless, and .bt-eyebrow
        // depends on it.
        tight: "var(--bt-track-tw-tight, -0.025em)",
        tighter: "var(--bt-track-tw-tighter, -0.05em)",
      },
      fontSize: {
        // Display sizes only. The body scale stays Tailwind's so no existing
        // `text-sm` moves. Tracking tightens as size grows -- large type set at
        // 0 tracking looks loose, which is the single most common tell of an
        // un-designed page.
        eyebrow: ["0.75rem", { lineHeight: "1", letterSpacing: "0.14em" }],
        "display-sm": ["1.75rem", { lineHeight: "1.2", letterSpacing: "-0.018em" }],
        "display-md": ["2.25rem", { lineHeight: "1.15", letterSpacing: "-0.024em" }],
        "display-lg": ["2.75rem", { lineHeight: "1.1", letterSpacing: "-0.028em" }],
        "display-xl": ["3.5rem", { lineHeight: "1.06", letterSpacing: "-0.032em" }],
        "display-2xl": ["4.5rem", { lineHeight: "1.02", letterSpacing: "-0.036em" }],
      },
      borderRadius: {
        card: "20px",  // AppRadius.xl
        chip: "12px",  // AppRadius.md
        sheet: "24px", // AppRadius.xxl
      },
      boxShadow: {
        card: "0 1px 4px rgba(0,0,0,0.04)",       // AppShadows.sm
        raised: "0 2px 8px rgba(0,0,0,0.06)",     // AppShadows.md
        float: "0 4px 16px rgba(0,0,0,0.08)",     // AppShadows.lg
        brand: "0 6px 16px rgba(0,191,165,0.30)", // AppShadows.colored
        // Wide, low-opacity and offset downward: reads as elevation rather
        // than as a grey outline, which is what the old flat shadows did.
        lift: "0 10px 30px -12px rgba(13,19,28,0.18)",
        glass: "0 8px 32px -8px rgba(13,19,28,0.24)",
      },
      keyframes: {
        "bt-rise": {
          from: { opacity: "0", transform: "translateY(10px)" },
          to: { opacity: "1", transform: "none" },
        },
        "bt-marquee": {
          from: { transform: "translateX(0)" },
          to: { transform: "translateX(-50%)" },
        },
        "bt-float": {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-8px)" },
        },
        "bt-shimmer": {
          from: { backgroundPosition: "200% 0" },
          to: { backgroundPosition: "-200% 0" },
        },
        // --- Homepage hero cycle -------------------------------------------
        // One 14s loop drives the whole demo. Each element gets the same
        // keyframes and a different `animationDelay`, so the sequence is a
        // property of the tokens rather than of a JS timer -- the page is
        // prerendered, and a timer would mean markup that differs between
        // server and first client paint.
        //
        // The typing indicator covers its bubble's text (bg-inherit) until
        // 8.5% -- 1.19s of the 14s cycle -- and then clears for good, which
        // is what makes the text look typed rather than merely faded in.
        // Opacity stays at 1 for the whole window on purpose: the indicator
        // is opaque (bg-inherit) and masks the bubble's text until it clears.
        // The dots' own pulse is Tailwind's `animate-pulse`, staggered.
        "bt-type-dots": {
          "0%": { opacity: "1", visibility: "visible" },
          "7%": { opacity: "1", visibility: "visible" },
          "8.5%": { opacity: "0", visibility: "hidden" },
          "100%": { opacity: "0", visibility: "hidden" },
        },
        // The bubble rises in at 3% (0.42s) carrying the typing indicator,
        // rests, then fades with the rest of the conversation so the cycle can
        // start over. It must NOT stay transparent through the typing window:
        // the indicator is its child, and a parent at opacity 0 takes its
        // whole subtree with it -- which would mean the dots never showed.
        "bt-msg-in": {
          "0%": { opacity: "0", transform: "translateY(6px)" },
          "3%": { opacity: "1", transform: "none" },
          "86%": { opacity: "1", transform: "none" },
          "100%": { opacity: "0", transform: "none" },
        },
        // The translation line unrolls under the dashed rule. max-height, not
        // height: the line's real height depends on how the text wraps.
        "bt-line-in": {
          "0%": { opacity: "0", maxHeight: "0" },
          "6%": { opacity: "0", maxHeight: "0" },
          "11%": { opacity: "1", maxHeight: "2.5rem" },
          "86%": { opacity: "1", maxHeight: "2.5rem" },
          "100%": { opacity: "0", maxHeight: "2.5rem" },
        },
        // The story viewer's segment bar. A CSS animation rather than a
        // setInterval writing an inline width every 100ms: the bar is the
        // clock, so `animation-play-state: paused` is the whole of
        // hold-to-pause, and `animationend` is the whole of auto-advance --
        // one source of truth instead of a timer and a style that can drift
        // apart. 5s is the duration the interval counted out.
        "bt-story-progress": {
          from: { width: "0%" },
          to: { width: "100%" },
        },
        "bt-drift": {
          "0%, 100%": { transform: "translateY(0) rotate(0deg)" },
          "50%": { transform: "translateY(-18px) rotate(4deg)" },
        },
        "bt-gradient": {
          "0%, 100%": { backgroundPosition: "0% 50%" },
          "50%": { backgroundPosition: "100% 50%" },
        },
      },
      animation: {
        "bt-rise": "bt-rise .5s ease-out both",
        "bt-marquee": "bt-marquee 28s linear infinite",
        "bt-float": "bt-float 4s ease-in-out infinite",
        "bt-shimmer": "bt-shimmer 3s linear infinite",
        // `both` fill mode: during its delay an element sits at the 0% frame
        // (invisible) instead of its static state, so nothing flashes before
        // its slot. Every one of these loops -- they are ambience, not an
        // entrance, and `motion-safe:` is what switches them off.
        "bt-type-dots": "bt-type-dots 14s ease-in-out infinite both",
        "bt-msg-in": "bt-msg-in 14s ease-out infinite both",
        "bt-line-in": "bt-line-in 14s ease-out infinite both",
        "bt-story-progress": "bt-story-progress 5s linear forwards",
        "bt-drift": "bt-drift 24s ease-in-out infinite",
        "bt-gradient": "bt-gradient 12s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};
