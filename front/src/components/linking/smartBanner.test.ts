import fs from "fs";
import path from "path";
import { smartBannerArgument, setSmartBannerArgument, SMART_BANNER_APP_ID } from "./smartBanner";

const HEX = "507f1f77bcf86cd799439011";
const ROOT = "https://banatalk.com/";

const TABLE: [string, string][] = [
  ["/", ROOT],
  ["/moments", ROOT],
  [`/moment/${HEX}`, `${ROOT}moment/${HEX}`],
  [`/moment/${HEX}/`, `${ROOT}moment/${HEX}`],
  [`/profile/${HEX}`, `${ROOT}profile/${HEX}`],
  [`/community/${HEX}`, `${ROOT}community/${HEX}`],
  [`/story/${HEX}`, `${ROOT}story/${HEX}`],
  [`/card/${HEX}`, `${ROOT}profile/${HEX}`], // the app has no card route
  ["/i/ABCD2345", `${ROOT}i/ABCD2345`],
  ["/profile/edit", ROOT],
  ["/community/nearby", ROOT],
  [`/profile/${HEX}/followers`, ROOT],
  ["/i/a b", ROOT],
  ["/chat/" + HEX, ROOT], // 2.6.1 drops chat links
];

describe("smartBannerArgument", () => {
  it.each(TABLE)("%s -> %s", (p, expected) => {
    expect(smartBannerArgument(p)).toBe(expected);
  });
});

describe("setSmartBannerArgument", () => {
  it("rewrites the existing tag and leaves the app id alone", () => {
    document.head.innerHTML = `<meta name="apple-itunes-app" content="app-id=${SMART_BANNER_APP_ID}, app-argument=${ROOT}">`;
    setSmartBannerArgument(`/moment/${HEX}`);
    expect(document.querySelector('meta[name="apple-itunes-app"]')!.getAttribute("content"))
      .toBe(`app-id=${SMART_BANNER_APP_ID}, app-argument=${ROOT}moment/${HEX}`);
  });

  it("does nothing when the tag is missing", () => {
    document.head.innerHTML = "";
    expect(() => setSmartBannerArgument("/")).not.toThrow();
  });
});

// The same rule runs as an inline script in public/index.html, because Safari
// reads the tag while parsing -- before any bundle runs. The two copies must agree.
describe("public/index.html", () => {
  const html = fs.readFileSync(path.resolve(__dirname, "../../../public/index.html"), "utf8");
  const script = (html.match(/<script id="smart-banner-argument">([\s\S]*?)<\/script>/) || [])[1];

  it("has one smart-banner tag, the inline script right after it, and no google-play-app tag", () => {
    expect(html.match(/name="apple-itunes-app"/g)).toHaveLength(1);
    expect(html).not.toContain("google-play-app");
    expect(script).toBeTruthy();
    expect(html.indexOf('id="smart-banner-argument"')).toBeGreaterThan(html.indexOf('name="apple-itunes-app"'));
  });

  it.each(TABLE)("inline script on %s matches smartBannerArgument", (p) => {
    document.head.innerHTML = `<meta name="apple-itunes-app" content="app-id=${SMART_BANNER_APP_ID}, app-argument=${ROOT}">`;
    window.history.replaceState(null, "", p);
    // eslint-disable-next-line no-new-func
    new Function(script)();
    expect(document.querySelector('meta[name="apple-itunes-app"]')!.getAttribute("content"))
      .toBe(`app-id=${SMART_BANNER_APP_ID}, app-argument=${smartBannerArgument(p)}`);
  });

  afterAll(() => window.history.replaceState(null, "", "/"));
});
