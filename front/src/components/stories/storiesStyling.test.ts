/**
 * @jest-environment node
 */
// What `src/components/stories/**` is allowed to look like.
//
// Task S4 took four SCSS files (1,610 lines of hex, gradients and media
// queries) off this directory and put it on Tailwind + `src/design/*`. A
// rewrite is a one-off; this file is what keeps it from growing back, because
// every one of these rules was broken here before and none of them is
// enforced by anything else:
//
//   1. no stylesheet of its own -- the tokens live in tailwind.config.js;
//   2. no react-bootstrap / react-icons / react-toastify -- the shell is
//      retiring all three, and a story screen was the last place importing
//      them next to their lucide + design/notify replacements;
//   3. no hex literals, EXCEPT where a hex is story *data* on the wire;
//   4. no inline styles, EXCEPT the three values that ARE story data and
//      cannot be a class: an overlay's position, an overlay's colour, and a
//      text story's own palette;
//   5. no emoji standing in for an icon. Emoji here are CONTENT -- the
//      reaction the reader picks, the sticker the author places -- so they
//      are allowed only inside a declared palette, never in markup.
//
// Source files only: a test file quotes the things it tests for.
import fs from "fs";
import path from "path";

const DIR = __dirname;

const sourceFiles = (): string[] =>
  fs
    .readdirSync(DIR)
    .filter((name) => /\.(ts|tsx)$/.test(name) && name.indexOf(".test.") === -1)
    .map((name) => path.join(DIR, name));

const read = (file: string): string => fs.readFileSync(file, "utf8");
const rel = (file: string): string => path.basename(file);

// --------------------------------------------------------------- stylesheets

it("keeps no stylesheet of its own", () => {
  const styles = fs.readdirSync(DIR).filter((f) => /\.(scss|css)$/.test(f));
  expect(styles).toEqual([]);

  const importers = sourceFiles().filter((f) => /\.s?css"/.test(read(f)));
  expect(importers.map(rel)).toEqual([]);
});

// ------------------------------------------------------------------ packages

const FORBIDDEN_PACKAGES = ["react-bootstrap", "react-icons", "react-toastify"];

it("imports no react-bootstrap, react-icons or react-toastify", () => {
  const offenders: string[] = [];
  sourceFiles().forEach((file) => {
    const text = read(file);
    FORBIDDEN_PACKAGES.forEach((pkg) => {
      if (text.indexOf(`"${pkg}`) > -1 || text.indexOf(`'${pkg}`) > -1) {
        offenders.push(`${rel(file)} -> ${pkg}`);
      }
    });
  });
  expect(offenders).toEqual([]);
});

// ---------------------------------------------------------------------- hex

/**
 * The only three files allowed to spell a hex colour, and why.
 *
 * All are about VALUES THAT TRAVEL: `storyOverlays.ts` holds the palette the
 * composer writes into `overlays[].color` and the `/^#[0-9a-fA-F]{6}$/` the
 * backend validates it with, and `CreateStory.tsx` holds the two text-story
 * colours that are uploaded as `backgroundColor`/`textColor`, and
 * `storyBackground.ts` mirrors the app's `StoryGradient.presets`, because the
 * app uploads a gradient ID (`gradient_sunset`) as `backgroundColor`. A Tailwind class
 * cannot be sent over the wire, and a story composed on the phone can carry
 * any hex the app allowed -- so a class map would silently lose colours.
 */
const DATA_HEX_FILES = ["storyOverlays.ts", "CreateStory.tsx", "storyBackground.ts"];
const HEX = /#[0-9a-fA-F]{3,8}\b/;

it("spells no hex colour outside the three files where a hex is data", () => {
  const offenders: string[] = [];
  sourceFiles().forEach((file) => {
    if (DATA_HEX_FILES.indexOf(rel(file)) > -1) return;
    read(file)
      .split("\n")
      .forEach((line, i) => {
        if (HEX.test(line)) offenders.push(`${rel(file)}:${i + 1} ${line.trim()}`);
      });
  });
  expect(offenders).toEqual([]);
});

it("keeps even those hexes out of the styling, where a token belongs", () => {
  // A hex that reaches a `className` is not data any more -- it is a colour
  // decision taken outside the token file.
  const offenders: string[] = [];
  DATA_HEX_FILES.forEach((name) => {
    read(path.join(DIR, name))
      .split("\n")
      .forEach((line, i) => {
        if (HEX.test(line) && line.indexOf("className") > -1) {
          offenders.push(`${name}:${i + 1} ${line.trim()}`);
        }
      });
  });
  expect(offenders).toEqual([]);
});

// -------------------------------------------------------------- inline style

/** Every `style={...}` expression in a file, brace-balanced. */
function inlineStyles(source: string): string[] {
  const out: string[] = [];
  const marker = "style={";
  let at = source.indexOf(marker);
  while (at > -1) {
    let i = at + marker.length - 1; // on the opening "{"
    let depth = 0;
    for (; i < source.length; i += 1) {
      const c = source.charAt(i);
      if (c === "{") depth += 1;
      else if (c === "}") {
        depth -= 1;
        if (depth === 0) break;
      }
    }
    out.push(source.slice(at + marker.length - 1, i + 1));
    at = source.indexOf(marker, i);
  }
  return out;
}

/** Top-level comma split: commas inside (), [] or {} do not separate entries. */
function topLevelParts(body: string): string[] {
  const parts: string[] = [];
  let depth = 0;
  let current = "";
  for (let i = 0; i < body.length; i += 1) {
    const c = body.charAt(i);
    if (c === "(" || c === "[" || c === "{") depth += 1;
    if (c === ")" || c === "]" || c === "}") depth -= 1;
    if (c === "," && depth === 0) {
      parts.push(current);
      current = "";
    } else {
      current += c;
    }
  }
  if (current.trim()) parts.push(current);
  return parts.map((p) => p.trim()).filter((p) => p.length > 0);
}

/**
 * The allow-list, as patterns rather than as a list of files: the three
 * values a story CARRIES and a class cannot express.
 *
 *   - `overlayPositionStyle(x, y)` / `mentionPositionStyle(pos)` — `left` and
 *     `top` as percentages of a canvas whose size is whatever the viewport
 *     gives it. Two numbers read out of JSON at render time.
 *   - `color: <expr>` beside one of those — the overlay's own colour.
 *   - `{ backgroundColor, color }` — a text story's palette, as composed.
 *   - `...storyBackgroundStyle(value)` beside `color` — the same palette when
 *     `backgroundColor` carries an app gradient id (a `backgroundImage`).
 *
 * Anything else is a styling decision, and belongs in a class.
 */
const POSITION_CALL = /^\.\.\.?\s*(overlay|mention)PositionStyle\(.*\)$/;
const BARE_POSITION_CALL = /^\{\s*(overlay|mention)PositionStyle\(.*\)\s*\}$/;
const BACKGROUND_CALL = /^\.\.\.\s*storyBackgroundStyle\(.*\)$/;
const PALETTE_KEYS = ["backgroundColor", "color"];

function isAllowedStyle(expression: string): boolean {
  const trimmed = expression.replace(/\s+/g, " ").trim();
  // style={mentionPositionStyle(mention.position)}
  if (BARE_POSITION_CALL.test(trimmed)) return true;
  // style={{ ... }}
  const objectMatch = /^\{\s*\{([\s\S]*)\}\s*\}$/.exec(trimmed);
  if (!objectMatch) return false;

  return topLevelParts(objectMatch[1]).every((part) => {
    if (part.indexOf("...") === 0) {
      return POSITION_CALL.test(part.replace(/^\.\.\./, "...")) || BACKGROUND_CALL.test(part);
    }
    const key = part.split(":")[0].trim();
    return PALETTE_KEYS.indexOf(key) > -1;
  });
}

it("uses inline style only for an overlay's position, an overlay's colour and a text story's palette", () => {
  const offenders: string[] = [];
  sourceFiles().forEach((file) => {
    inlineStyles(read(file)).forEach((expression) => {
      if (!isAllowedStyle(expression)) {
        offenders.push(`${rel(file)}: ${expression.replace(/\s+/g, " ").slice(0, 90)}`);
      }
    });
  });
  expect(offenders).toEqual([]);
});

it("proves the inline-style guard can fire", () => {
  // The control. Without these, a parser that quietly matched nothing would
  // make the assertion above pass for the wrong reason.
  expect(isAllowedStyle("{{ ...overlayPositionStyle(o.x, o.y), color: o.color }}")).toBe(true);
  expect(isAllowedStyle("{mentionPositionStyle(mention.position)}")).toBe(true);
  expect(isAllowedStyle("{{ backgroundColor, color: textColor }}")).toBe(true);
  expect(isAllowedStyle("{{ backgroundColor: s.backgroundColor, color: s.textColor }}")).toBe(true);
  expect(isAllowedStyle("{{ ...storyBackgroundStyle(s.backgroundColor), color: storyTextColor(s.textColor) }}")).toBe(true);
  expect(isAllowedStyle("{{ ...storyBackgroundStyle(s.backgroundColor), padding: 12 }}")).toBe(false);
  // ...and the shapes that are a styling decision in disguise.
  expect(isAllowedStyle("{{ width: `${percentage}%` }}")).toBe(false);
  expect(isAllowedStyle("{{ backgroundColor: '#000', padding: 12 }}")).toBe(false);
  expect(isAllowedStyle("{{ transform: 'translateY(-50%)' }}")).toBe(false);
  expect(inlineStyles('<div style={{ a: 1 }} className="x" />')).toEqual(["{{ a: 1 }}"]);
});

// --------------------------------------------------------------------- emoji

// Pictographs only: the arrows and dingbats that show up in prose (→, ✓ in a
// comment) are not what this is about.
const EMOJI = /[\u{1F300}-\u{1FAFF}\u{2764}\u{2B50}\u{FE0F}]/u;
/** `const NAME = [` — a declared palette of story content. */
const PALETTE_DECLARATION = /^\s*(export\s+)?const\s+[A-Z][A-Z0-9_]*(\s*:[^=]+)?\s*=\s*\[/;

it("uses emoji only as declared story content, never as an icon", () => {
  const offenders: string[] = [];
  sourceFiles().forEach((file) => {
    read(file)
      .split("\n")
      .forEach((line, i) => {
        if (!EMOJI.test(line)) return;
        if (PALETTE_DECLARATION.test(line)) return;
        offenders.push(`${rel(file)}:${i + 1} ${line.trim()}`);
      });
  });
  // The two that are allowed are palettes: STORY_REACTIONS (what a reader can
  // send) and QUICK_EMOJI (what an author can place). Both are data the UI
  // renders; neither stands in for a button's meaning, which is what lucide
  // is for.
  expect(offenders).toEqual([]);
});

it("proves the emoji guard can fire", () => {
  expect(EMOJI.test('<button>❤️</button>')).toBe(true);
  expect(PALETTE_DECLARATION.test('const QUICK_EMOJI = ["\u{1F602}"];')).toBe(true);
  expect(PALETTE_DECLARATION.test('  <span>\u{1F602}</span>')).toBe(false);
  // Prose arrows and check marks stay legal.
  expect(EMOJI.test(" * Drafts → the `overlays` field.")).toBe(false);
});

it("still has the two emoji palettes it is meant to allow", () => {
  expect(read(path.join(DIR, "types.ts"))).toContain("STORY_REACTIONS");
  expect(EMOJI.test(read(path.join(DIR, "types.ts")))).toBe(true);
  expect(EMOJI.test(read(path.join(DIR, "CreateStory.tsx")))).toBe(true);
});
