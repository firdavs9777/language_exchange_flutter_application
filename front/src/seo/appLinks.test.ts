import fs from "fs";
import path from "path";

/**
 * The two files iOS and Android fetch to decide whether the app may claim
 * banatalk.com links.
 *
 * They shipped to production with `TODO_` placeholders in both, which means
 * verification failed and every link opened the browser — the app gateway was
 * inert from the start. These assertions stop a placeholder reaching the build
 * again, and keep the paths in step with what the app actually parses.
 */
const wellKnown = path.resolve(__dirname, "../../public/.well-known");
const aasa = JSON.parse(
  fs.readFileSync(path.join(wellKnown, "apple-app-site-association"), "utf8")
);
const assetLinks = JSON.parse(
  fs.readFileSync(path.join(wellKnown, "assetlinks.json"), "utf8")
);

const detail = aasa.applinks.details[0];

describe("apple-app-site-association", () => {
  it("names a real team and the app's own bundle id", () => {
    const appId: string = detail.appIDs[0];
    expect(appId).not.toContain("TODO");
    // TEAMID.bundle — the bundle half must match ios/Runner.xcodeproj.
    expect(appId).toMatch(/^[A-Z0-9]{10}\.com\.bananatalk\.bananatalkApp$/);
  });

  // Claimed: only what app 2.6.1's parser routes. /chat/* and /story/* are
  // added back by the owner (Phase 5) once 2.7.0 -- which parses both -- is
  // most of the iOS base; 2.6.1 opens and drops them.
  it("claims exactly the path types app 2.6.1 routes", () => {
    const claimed = detail.components.filter((c: any) => !c.exclude).map((c: any) => c["/"]).sort();
    expect(claimed).toEqual(["/community/*", "/i/*", "/moment/*", "/profile/*"]);
    const all = detail.components.map((c: any) => c["/"]);
    expect(all).not.toContain("/chat/*");
    expect(all).not.toContain("/story/*");
  });

  // links#15: /profile/edit etc. opened the app, which read "edit" as a user id.
  // Every web route under a claimed prefix that is not the detail page itself
  // must be excluded -- derived from the router, so a new web-only page under
  // /profile/ or /community/ fails here until it is excluded too.
  it("excludes every web-only page under a claimed prefix, before the wildcard", () => {
    const { routes } = require("../router/routes");
    const DETAIL = ["moment/:id", "profile/:userId", "community/:userId", "i/:code"];
    const webOnly: string[] = (routes[0].children || [])
      .map((c: any) => c.path)
      .filter((p: any) => typeof p === "string" && /^(moment|profile|community|i)\//.test(p) && DETAIL.indexOf(p) < 0)
      .map((p: string) => "/" + p.replace(/:[A-Za-z]+/g, "*"));
    expect(webOnly.sort()).toEqual(["/community/city", "/community/genders", "/community/nearby", "/profile/*/followers", "/profile/*/following", "/profile/edit"]);

    const paths: string[] = detail.components.map((c: any) => c["/"]);
    for (const p of webOnly) {
      const i = paths.indexOf(p);
      expect(i).toBeGreaterThanOrEqual(0);
      expect(detail.components[i].exclude).toBe(true);
      const wildcard = paths.indexOf("/" + p.split("/")[1] + "/*");
      expect(i).toBeLessThan(wildcard);
    }
  });

  // Apple's matching, simplified: the first component whose pattern matches decides.
  it("resolves real links the way iOS will", () => {
    const toRe = (p: string) => new RegExp("^" + p.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".") + "$");
    const opensApp = (url: string) => {
      const hit = detail.components.find((c: any) => toRe(c["/"]).test(url));
      return Boolean(hit && !hit.exclude);
    };
    const id = "507f1f77bcf86cd799439011";
    expect(opensApp(`/moment/${id}`)).toBe(true);
    expect(opensApp(`/profile/${id}`)).toBe(true);
    expect(opensApp(`/community/${id}`)).toBe(true);
    expect(opensApp("/i/ABCD2345")).toBe(true);
    expect(opensApp("/profile/edit")).toBe(false);
    expect(opensApp(`/profile/${id}/followers`)).toBe(false);
    expect(opensApp(`/profile/${id}/following`)).toBe(false);
    expect(opensApp("/community/nearby")).toBe(false);
    expect(opensApp("/community/city")).toBe(false);
    expect(opensApp("/community/genders")).toBe(false);
    expect(opensApp(`/chat/${id}`)).toBe(false);
    expect(opensApp(`/story/${id}`)).toBe(false);
  });
});

describe("assetlinks.json", () => {
  it("names the app's own package", () => {
    expect(assetLinks[0].target.package_name).toBe("com.bananatalk.app");
  });

  // PENDING until the two fingerprints are pasted in. Android App Links are
  // dead until then: Google's verifier fetches this file and finds TODO_ where
  // a SHA-256 should be, so banatalk.com links open the browser, not the app.
  //
  // To enable: replace both strings in public/.well-known/assetlinks.json and
  // change this to `it(`.
  //   upload key -> keytool -list -v -keystore <upload.jks> -alias <alias>
  //   Play key   -> Play Console > Test and release > App integrity > App signing
  it("carries the Play signing fingerprint, with no placeholder left", () => {
    const prints: string[] = assetLinks[0].target.sha256_cert_fingerprints;
    expect(prints.length).toBeGreaterThanOrEqual(1);
    prints.forEach((print) => {
      expect(print).not.toContain("TODO");
      expect(print).toMatch(/^([0-9A-F]{2}:){31}[0-9A-F]{2}$/i);
    });
    // Play App Signing key (from Play Console > Deep links, 2026-10-16).
    expect(prints).toContain("8D:B2:D2:7A:CD:16:8C:BD:91:2C:32:01:A6:67:07:83:28:A9:43:6D:48:55:E6:1C:AC:20:2C:05:EE:06:3B:FE");
  });

  // PENDING: add the upload-key fingerprint (keytool on the keystore machine)
  // so internal/sideloaded builds verify too, then enable.
  it.skip("carries both signing fingerprints, with no placeholder left", () => {
    const prints: string[] = assetLinks[0].target.sha256_cert_fingerprints;
    // Two: Google re-signs for the Play Store, so an installed app carries the
    // Play fingerprint while an internal or sideloaded build carries the
    // upload one. Listing only one breaks links for that install source.
    expect(prints).toHaveLength(2);
    prints.forEach((print) => {
      expect(print).not.toContain("TODO");
      expect(print).toMatch(/^([0-9A-F]{2}:){31}[0-9A-F]{2}$/i);
    });
  });
});
