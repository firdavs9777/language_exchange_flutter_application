import { matchRoutes } from "react-router-dom";
import { routes } from "../router/routes";
import {
  SEO_PAGES,
  findSeoPage,
  canonicalUrl,
  normalizePath,
  seoTitleEn,
  seoDescriptionEn,
} from "./pages";
import { APP_STORE_URL, PLAY_STORE_URL } from "../components/growth/storeUrls";
import { PRERENDER_PATHS, SITEMAP_PATHS } from "./publicRoutes";

describe("SEO map", () => {
  it("every entry is a real route", () => {
    for (const page of SEO_PAGES) {
      const matches = matchRoutes(routes, page.path);
      expect(matches && matches.length).toBe(2);
      expect(matches![1].route.path).not.toBe("*");
    }
  });

  it("titles fit a result line and descriptions fit a snippet", () => {
    for (const page of SEO_PAGES) {
      const title = seoTitleEn(page);
      const description = seoDescriptionEn(page);
      expect(title.length).toBeGreaterThan(0);
      expect(title.length).toBeLessThanOrEqual(60);
      expect(description.length).toBeGreaterThan(0);
      expect(description.length).toBeLessThanOrEqual(160);
    }
  });

  it("no two pages share a title", () => {
    const titles = SEO_PAGES.map(seoTitleEn);
    expect(new Set(titles).size).toBe(titles.length);
  });

  it("each title carries the phrase it targets", () => {
    for (const page of SEO_PAGES) {
      expect(seoTitleEn(page).toLowerCase()).toContain(page.primary.toLowerCase());
    }
  });

  // The download page is the one entry a rich result can act on: the card
  // Google draws for an app needs both store links and a price.
  it("describes the app on /download, with both stores and the real price", () => {
    const page = findSeoPage("/download")!;
    expect(page.jsonLd).toBeDefined();
    const ld = page.jsonLd!({ url: canonicalUrl("/download") }) as any;
    expect(ld["@type"]).toBe("SoftwareApplication");
    expect(ld.url).toBe("https://banatalk.com/download");
    expect(ld.sameAs).toEqual([APP_STORE_URL, PLAY_STORE_URL]);
    expect(ld.operatingSystem).toContain("iOS");
    expect(ld.operatingSystem).toContain("Android");
    expect(ld.offers.price).toBe("0");
    expect(ld.offers.description).toBe("Free, VIP from $9.99");
    expect(() => JSON.stringify(ld)).not.toThrow();
  });

  // The two landing pages of task B4. seoTitleEn reads eng.json only, so the
  // length test above doubles as the guard that every seo.* key exists there.
  it("carries the two landing pages with the phrases they own", () => {
    const meet = findSeoPage("/meet")!;
    const korean = findSeoPage("/learn-korean")!;
    expect(meet.primary).toBe("meet people from other countries");
    expect(korean.primary).toBe("learn Korean by chatting");
    expect(meet.titleKey).toBe("seo.meet.title");
    expect(korean.titleKey).toBe("seo.learnKorean.title");
    expect(seoDescriptionEn(meet).toLowerCase()).toContain("meet people from other countries");
    expect(seoDescriptionEn(korean).toLowerCase()).toContain("learn korean by chatting");
  });

  // /communities left the indexed set on 2026-10-16: it is members-only, and
  // an indexed page is prerendered logged-out, which a sign-in guard cannot
  // sit behind. Keeping it out of SEO_PAGES keeps it out of the prerender list
  // and the sitemap too.
  it("does not index, prerender or sitemap the members-only /communities", () => {
    expect(findSeoPage("/communities")).toBeUndefined();
    expect(PRERENDER_PATHS).not.toContain("/communities");
    expect(SITEMAP_PATHS).not.toContain("/communities");
  });

  it("normalizes trailing slashes and builds canonical URLs", () => {
    expect(normalizePath("/privacy-policy/")).toBe("/privacy-policy");
    expect(normalizePath("/")).toBe("/");
    expect(findSeoPage("/privacy-policy/")!.path).toBe("/privacy-policy");
    expect(findSeoPage("/chat")).toBeUndefined();
    expect(canonicalUrl("/")).toBe("https://banatalk.com");
    expect(canonicalUrl("/download")).toBe("https://banatalk.com/download");
  });
});
