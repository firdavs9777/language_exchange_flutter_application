// The paint box for the four promo illustrations.
//
// The band the art sits in is `bg-ink-950`, so every illustration is drawn on
// a transparent ground out of white, the brand teal family and the banana
// yellow -- the same values tailwind.config.js hands the rest of the site.
// They are literals here because an SVG `fill` cannot read a Tailwind class,
// and they are literals in exactly ONE place: paint.test.ts asserts each one
// against the resolved Tailwind theme, so the day the brand moves, this file
// fails rather than drifts. Nothing else in the promo code carries a hex.
export const WHITE = "#FFFFFF";
export const BRAND = "#00BFA5"; // colors.brand.DEFAULT
export const BRAND_LIGHT = "#5DF2D6"; // colors.brand.light
export const BRAND_DEEP = "#00806A"; // colors.brand.deep
export const BANANA = "#FFD54F"; // colors.banana.DEFAULT
export const INK_100 = "#EEF1F5"; // colors.ink.100
export const INK_200 = "#DFE4EB"; // colors.ink.200
export const INK_500 = "#6B7686"; // colors.ink.500
export const INK_900 = "#171E29"; // colors.ink.900

/**
 * The display stack, spelled for SVG.
 *
 * Only the Moments card uses it, and only for the two letters of the
 * `A -> 가` mark: everything else in these drawings is a path, because text in
 * an illustration is text a translator cannot reach. The Hangul syllable is
 * not in Plus Jakarta Sans or Inter; the fallbacks are what actually paint it,
 * which is why the stack is spelled out rather than ending at the brand faces.
 */
export const ART_FONT = '"Plus Jakarta Sans", Inter, system-ui, sans-serif';

/**
 * Every illustration takes the same three props.
 *
 * `title` is the sentence a screen reader hears -- it comes from
 * `growth.promo.<key>.alt`, so it is translated -- and `titleId` wires it to
 * the <svg role="img"> through aria-labelledby. The id is also the prefix for
 * any element id inside the drawing, which keeps two illustrations on one page
 * from colliding.
 */
export interface PromoArtProps {
  title: string;
  titleId: string;
  className?: string;
}
