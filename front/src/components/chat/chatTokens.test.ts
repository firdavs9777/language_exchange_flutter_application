import fs from "fs";
import path from "path";
import { CHAT_WALLPAPERS, PREMIUM_WALLPAPERS } from "../../design/chatWallpapers";

/**
 * The chat colour tokens (Task H3).
 *
 * ./chatStyling.test.ts guards the chat COMPONENTS (no react-bootstrap, no
 * emoji icons, no colour in an inline style). This file guards the colours
 * themselves: that they are declared once in src/index.css, that the three
 * chat stylesheets reference nothing else, that dark mode is a property of
 * the tokens rather than of each rule, and that the wallpaper presets the
 * picker offers are exactly the ones the stylesheet can paint.
 *
 * Why static rather than rendered: jsdom does not do the cascade, custom
 * properties or `prefers-color-scheme`, so the only honest check of a token
 * system in this test runner is of the source it compiles from.
 */

const CHAT_DIR = __dirname;
const indexCss = fs.readFileSync(path.resolve(CHAT_DIR, "../../index.css"), "utf8");

const CHAT_STYLESHEETS = ["ChatContent.css", "MainChat.css", "UsersList.css"];

const sheets = CHAT_STYLESHEETS.map((name) => ({
  name,
  source: fs.readFileSync(path.join(CHAT_DIR, name), "utf8"),
}));

/** The eight the plan names. Everything else is an addition, not a swap. */
const REQUIRED_TOKENS = [
  "--chat-bg",
  "--chat-bubble-out",
  "--chat-bubble-out-text",
  "--chat-bubble-in",
  "--chat-bubble-in-text",
  "--chat-line",
  "--chat-muted",
  "--chat-surface",
];

function darkBlock(): string {
  const at = indexCss.indexOf("@media (prefers-color-scheme: dark)");
  expect(at).toBeGreaterThan(-1);
  // Walk the braces to the end of the media query, so the block's own
  // formatting cannot fool the reader.
  const rest = indexCss.slice(at);
  let depth = 0;
  for (let i = 0; i < rest.length; i += 1) {
    if (rest[i] === "{") depth += 1;
    if (rest[i] === "}") {
      depth -= 1;
      if (depth === 0) return rest.slice(0, i + 1);
    }
  }
  throw new Error("the dark-mode media query is never closed");
}

describe("the chat tokens are declared once, in src/index.css", () => {
  REQUIRED_TOKENS.forEach((token) => {
    it(`${token} has a light value in :root`, () => {
      expect(indexCss).toMatch(new RegExp(`\\n  ${token}:\\s*[^;]+;`));
    });
  });

  it("re-points the surface, the incoming bubble and the hairlines for dark mode", () => {
    const dark = darkBlock();
    ["--chat-bg", "--chat-surface", "--chat-bubble-in", "--chat-bubble-in-text", "--chat-line", "--chat-muted"].forEach(
      (token) => {
        expect(dark).toContain(`${token}:`);
      }
    );
  });

  it("builds the outgoing bubble from the brand scale, not a literal", () => {
    expect(indexCss).toContain("--bt-brand-deep");
    expect(indexCss).toMatch(
      /--chat-accent-gradient:\s*linear-gradient\([^;]*var\(--bt-brand-deep\)[^;]*var\(--bt-brand\)[^;]*\);/
    );
    expect(indexCss).toContain("--chat-bubble-out: var(--chat-accent-gradient);");
  });

  it("takes the incoming bubble from the ink scale", () => {
    expect(indexCss).toMatch(/--chat-bubble-in:\s*var\(--bt-ink-\d+\);/);
    expect(indexCss).toMatch(/--chat-bubble-in-text:\s*var\(--bt-ink-\d+\);/);
  });
});

describe("the chat stylesheets name no colour of their own", () => {
  sheets.forEach(({ name, source }) => {
    it(`${name} contains no hex colour`, () => {
      expect(source.match(/#[0-9a-fA-F]{3,8}\b/g) || []).toEqual([]);
    });

    it(`${name} needs no dark-mode block of its own -- the tokens carry it`, () => {
      expect(source).not.toContain("prefers-color-scheme");
    });

    it(`${name} references only tokens that exist`, () => {
      const referenced = source.match(/var\(--chat-[a-z-]+/g) || [];
      const missing = referenced
        .map((reference) => reference.replace("var(", ""))
        .filter((token, index, all) => all.indexOf(token) === index)
        .filter((token) => indexCss.indexOf(`${token}:`) === -1);
      expect(missing).toEqual([]);
    });
  });

  it("paints the message bubbles from the bubble tokens", () => {
    const content = sheets[0].source;
    expect(content).toContain("background: var(--chat-bubble-out);");
    expect(content).toContain("color: var(--chat-bubble-out-text);");
    expect(content).toContain("background: var(--chat-bubble-in);");
    expect(content).toContain("color: var(--chat-bubble-in-text);");
  });

  it("gives Task H2's link card a real ground on both kinds of bubble", () => {
    const content = sheets[0].source;
    expect(content).toContain("background: var(--chat-card-in);");
    expect(content).toContain(".modern-message.sent .message-link-card");
    expect(content).toContain("background: var(--chat-card-out);");
  });

  it("paints the conversation pane with --chat-bg, so a wallpaper can replace it", () => {
    expect(sheets[0].source).toMatch(/\.modern-chat-messages\s*\{[^}]*background: var\(--chat-bg\);/);
    expect(sheets[1].source).toMatch(/\.chat-area\s*\{[^}]*background: var\(--chat-bg\);/);
  });
});

describe("the bubble's geometry moved out of the markup", () => {
  const bubble = fs.readFileSync(path.join(CHAT_DIR, "MessageBubble.tsx"), "utf8");

  it("no longer computes borderRadius or visibility inline", () => {
    const inlineStyles = bubble.match(/style=\{\{[\s\S]*?\}\}/g) || [];
    expect(inlineStyles.filter((style) => /borderRadius|visibility/.test(style))).toEqual([]);
  });

  it("names the corners and the avatar spacer with classes the stylesheet owns", () => {
    expect(bubble).toContain("message-bubble--");
    expect(bubble).toContain("message-avatar--hidden");
    const content = sheets[0].source;
    ["single", "first", "middle", "last"].forEach((position) => {
      expect(content).toContain(`.message-bubble--${position}`);
    });
    expect(content).toContain(".message-avatar--hidden");
  });
});

describe("the conversation list left react-bootstrap behind", () => {
  const usersList = fs.readFileSync(path.join(CHAT_DIR, "UsersList.tsx"), "utf8");

  it("asks the delete question with the design system's ConfirmDialog", () => {
    expect(usersList).toContain("ConfirmDialog");
    expect(usersList).not.toContain("<Modal");
  });

  it("imports nothing from react-bootstrap -- its Modal and Badge are gone", () => {
    expect(usersList).not.toContain("react-bootstrap");
  });

  it("styles the unread pill from the stylesheet now that it is a plain span", () => {
    expect(sheets[2].source).toMatch(/\.users-list-badge\s*\{[^}]*border-radius:/);
  });
});

describe("the wallpaper presets the picker offers are the ones the CSS can paint", () => {
  CHAT_WALLPAPERS.forEach((wallpaper) => {
    it(`${wallpaper.name} has a [data-chat-theme] rule`, () => {
      const rule = new RegExp(
        `\\[data-chat-theme="${wallpaper.name}"\\]\\s*\\{[^}]*--chat-bg:[^}]*\\}`
      );
      const match = indexCss.match(rule);
      expect(match).not.toBeNull();
      const colours = wallpaper.gradientColors || [wallpaper.backgroundColor as string];
      colours.forEach((colour) => {
        expect((match as RegExpMatchArray)[0]).toContain(colour);
      });
    });
  });

  it("offers no coin-gated premium preset in the picker", () => {
    const premium = CHAT_WALLPAPERS.filter(
      (wallpaper) => wallpaper.name.indexOf("premium") !== -1
    );
    expect(premium).toEqual([]);
  });

  it("leaves the default preset to the tokens -- it is not a wallpaper", () => {
    expect(indexCss).not.toContain('[data-chat-theme="default"]');
    expect(
      CHAT_WALLPAPERS.filter((wallpaper) => wallpaper.name === "default")
    ).toEqual([]);
  });

  it("paints a swatch from the same rules as the pane", () => {
    expect(indexCss).toMatch(/\.chat-wallpaper-swatch\s*\{\s*background: var\(--chat-bg\);/);
  });
});

describe("the app's premium pack renders, though the picker does not offer it (chat#18)", () => {
  it("is exactly the app's six presets", () => {
    expect(PREMIUM_WALLPAPERS.map((w) => w.name).sort()).toEqual([
      "premium_aurora_borealis",
      "premium_diamond_shine",
      "premium_emerald_luxe",
      "premium_galaxy",
      "premium_golden_hour",
      "premium_royal_velvet",
    ]);
  });

  PREMIUM_WALLPAPERS.forEach((wallpaper) => {
    it(`${wallpaper.name} has a [data-chat-theme] rule with the app's colours`, () => {
      const rule = new RegExp(`\\[data-chat-theme="${wallpaper.name}"\\]\\s*\\{[^}]*--chat-bg:[^}]*\\}`);
      const match = indexCss.match(rule);
      expect(match).not.toBeNull();
      (wallpaper.gradientColors as string[]).forEach((colour) => {
        expect((match as RegExpMatchArray)[0]).toContain(colour);
      });
    });
  });

  it("paints an unknown premium_* preset with a premium gradient, not the default surface", () => {
    expect(indexCss).toMatch(/\[data-chat-theme\^="premium_"\]\s*\{[^}]*--chat-bg:\s*linear-gradient/);
  });

  it("declares the prefix rule BEFORE the named rules, so the named ones win", () => {
    expect(indexCss.indexOf('[data-chat-theme^="premium_"]')).toBeLessThan(
      indexCss.indexOf('[data-chat-theme="premium_aurora_borealis"]')
    );
  });
});
