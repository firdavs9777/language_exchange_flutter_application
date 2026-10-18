import fs from "fs";
import path from "path";

// Community is the surface people spend the most time on, and the one most
// likely to be restyled. These are static guards, not render tests: they stop
// the design from leaking back into the component as inline styles, where no
// stylesheet, no theme and no hover state can reach it.

const tsx = fs.readFileSync(path.join(__dirname, "MainCommunity.tsx"), "utf8");
const scss = fs.readFileSync(path.join(__dirname, "tandem/tandem-community.scss"), "utf8");
const indexCss = fs.readFileSync(path.resolve(__dirname, "../../index.css"), "utf8");

it("keeps colours out of the component -- no hardcoded hex in an inline style", () => {
  const inlineStyles = tsx.match(/style=\{\{[\s\S]*?\}\}/g) || [];
  const withHex = inlineStyles.filter((s) => /#[0-9a-fA-F]{3,8}\b/.test(s));
  expect(withHex).toEqual([]);
});

it("styles the empty and error actions from the stylesheet", () => {
  expect(scss).toContain(".community-empty__action");
  expect(tsx).toContain("community-empty__action");
});

it("uses the shared type tokens rather than its own system font stack", () => {
  expect(scss).toContain("var(--bt-font-sans)");
  expect(scss).not.toContain("-apple-system, BlinkMacSystemFont");
});

it("still ships the class names the member list depends on", () => {
  for (const cls of [".community-page", ".community-empty", ".community-loadmore", ".tandem-member-card"]) {
    expect(scss).toContain(cls);
  }
});

it("leaves the Why sentence behind -- the card carries the reasons now", () => {
  expect(tsx).not.toContain("for-you-why");
  expect(tsx).not.toContain("communityMain.forYou.why");
});

// --- The member page --------------------------------------------------------
//
// /community/:id is the profile page now, and the blocks that made it one live
// in src/components/profile/parts. They are new code on the community surface,
// so they are held to the same rules as the list: design tokens only, lucide
// for every icon, nothing from react-bootstrap, and no colour or emoji baked
// into the markup where no theme can reach it.

const MEMBER_PAGE_FILES = [
  "../profile/ProfilePage.tsx",
  "../profile/parts/LanguageMatchCard.tsx",
  "../profile/parts/EngagementStats.tsx",
  "../profile/parts/MutualInterests.tsx",
  "../profile/parts/ConversationStarters.tsx",
  "../profile/parts/SuggestedMembers.tsx",
];

const memberPageSources: { name: string; source: string }[] = MEMBER_PAGE_FILES.map((rel) => ({
  name: rel,
  source: fs.readFileSync(path.join(__dirname, rel), "utf8"),
}));

// Emoji presentation blocks: pictographs, dingbats, symbols and the variation
// selector. Arrows and punctuation (em dash) are deliberately NOT in here --
// they are typography, not icons.
const EMOJI = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]/u;

describe("the member page blocks", () => {
  memberPageSources.forEach(({ name, source }) => {
    it(`${name} carries no inline style attribute`, () => {
      expect(source.match(/style=\{\{/g) || []).toEqual([]);
    });

    it(`${name} names no colour by hex`, () => {
      expect(source.match(/#[0-9a-fA-F]{3,8}\b/g) || []).toEqual([]);
    });

    it(`${name} imports no react-bootstrap`, () => {
      expect(source).not.toContain("react-bootstrap");
    });

    it(`${name} draws its icons with lucide, not emoji`, () => {
      expect(EMOJI.test(source)).toBe(false);
    });
  });

  it("keeps the deleted detail page deleted", () => {
    expect(fs.existsSync(path.join(__dirname, "CommunityDetail.tsx"))).toBe(false);
    expect(fs.existsSync(path.join(__dirname, "CommunityDetail.css"))).toBe(false);
    // TandemMemberCard was the detail page's row. Nothing rendered it once
    // that page went; its one surviving export, the TandemMember type, now
    // lives in tandem/types.ts.
    expect(fs.existsSync(path.join(__dirname, "tandem/TandemMemberCard.tsx"))).toBe(false);
    expect(fs.existsSync(path.join(__dirname, "tandem/types.ts"))).toBe(true);
  });
});

describe("the member list is a grid, not a column", () => {
  it("puts three members per row above 1024px", () => {
    expect(scss).toMatch(/\.community-grid\s*\{[^}]*grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\)/);
  });

  it("drops to two columns on a tablet and one on a small phone", () => {
    expect(scss).toMatch(/@media \(max-width: 1024px\)[\s\S]*?\.community-grid\s*\{[^}]*repeat\(2, minmax\(0, 1fr\)\)/);
    expect(scss).toMatch(/@media \(max-width: 380px\)[\s\S]*?\.community-grid\s*\{[^}]*repeat\(1, minmax\(0, 1fr\)\)/);
  });

  it("renders members through the grid on both tabs, not a flex column", () => {
    expect(tsx).toContain('className="community-grid"');
    expect(tsx).not.toContain('className="flex flex-col gap-3"');
  });
});

describe("the list still skips work it cannot see", () => {
  it("reserves the cell's height, not the old row's", () => {
    expect(scss).toMatch(/\.community-card-slot\s*\{[^}]*content-visibility:\s*auto/);
    expect(scss).toMatch(/\.community-card-slot\s*\{[^}]*contain-intrinsic-size:\s*auto 420px/);
    expect(scss).not.toContain("contain-intrinsic-size: auto 104px");
    expect(scss).not.toContain("contain-intrinsic-size: auto 320px");
  });

  it("shapes the skeleton like the card it stands in for", () => {
    expect(scss).toMatch(/\.community-card-skeleton\s*\{[^}]*flex-direction:\s*column/);
    expect(scss).toMatch(/\.community-card-skeleton\s*\{[^}]*min-height:\s*420px/);
    // A full-width 16:10 photo block up top and a foot bar for the wave
    // button, not the deleted row card's 72x72 avatar square.
    expect(scss).toContain(".community-card-skeleton__photo");
    expect(scss).toContain(".community-card-skeleton__foot");
    expect(scss).not.toContain(".community-card-skeleton__avatar");
  });

  it("lays the skeletons out in the same grid as the members", () => {
    expect(tsx).not.toContain('className="community-skeleton-list"');
  });
});

describe("the interleaved ad does not break the 3-per-row rhythm", () => {
  it("spans the full row instead of occupying one of the three columns", () => {
    expect(tsx).toMatch(/<AdUnit[^>]*className="[^"]*\bcommunity-grid__ad\b[^"]*"/);
    expect(scss).toMatch(/\.community-grid__ad\s*\{[^}]*grid-column:\s*1\s*\/\s*-1/);
  });
});

describe("the shared scales exist as tokens", () => {
  it("declares a spacing scale", () => {
    ["--bt-space-1: 4px", "--bt-space-2: 8px", "--bt-space-3: 12px",
     "--bt-space-4: 16px", "--bt-space-5: 24px", "--bt-space-6: 32px",
     "--bt-space-7: 48px"].forEach((decl) => {
      expect(indexCss).toContain(decl);
    });
  });

  it("declares a five-step type scale", () => {
    ["--bt-text-xs: 0.75rem", "--bt-text-sm: 0.875rem", "--bt-text-base: 1rem",
     "--bt-text-lg: 1.125rem", "--bt-text-xl: 1.25rem"].forEach((decl) => {
      expect(indexCss).toContain(decl);
    });
  });
});

describe("type sizes come from the scale", () => {
  it("names no font size the scale does not have", () => {
    // `[^;]+;` requires the trailing semicolon, so the last declaration in a
    // block without one would escape the ban entirely. `[^;}]+` stops at a
    // closing brace too, which catches it.
    const sizes = scss.match(/font-size:\s*[^;}]+[;}]/g) || [];
    const offenders = sizes.filter(
      (decl) => !/var\(--bt-text-(xs|sm|base|lg|xl)\)/.test(decl) && !/inherit/.test(decl)
    );
    expect(offenders).toEqual([]);
  });
});

describe("the page's own rhythm comes from the scale", () => {
  const pageRule = (selector: string): string => {
    const m = scss.match(new RegExp(`\\${selector}\\s*\\{([^}]*)\\}`));
    return m ? m[1] : "";
  };

  it("pads the page container from the scale", () => {
    expect(pageRule(".community-page__container")).toMatch(/var\(--bt-space-\d\)/);
  });

  it("spaces the member grid from the scale", () => {
    expect(pageRule(".community-grid")).toMatch(/margin-top:\s*var\(--bt-space-\d\)/);
  });
});
