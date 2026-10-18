// Safari's Smart App Banner ("Open" in the BananaTalk app) passes
// `app-argument` to the app, whose deep-link parser routes it. A static
// homepage argument opened the app at home whatever page was being read
// (links#16). The same rule runs as an inline script in public/index.html --
// Safari reads the tag while parsing, before any bundle runs -- and
// smartBanner.test.ts keeps the two copies in agreement.

export const SMART_BANNER_APP_ID = "6755862146";
const ROOT = "https://banatalk.com/";
const OBJECT_ID = /^[0-9a-fA-F]{24}$/;
const INVITE_CODE = /^[A-Za-z0-9]{4,32}$/;
const LINKABLE = /^\/(moment|profile|community|story|card|i)\/([^/]+)\/?$/;

/** The universal link the app should open for this page; the homepage when there is none. */
export function smartBannerArgument(pathname: string): string {
  const m = LINKABLE.exec(pathname || "");
  if (!m) return ROOT;
  const type = m[1];
  const id = m[2];
  if (type === "i") return INVITE_CODE.test(id) ? `${ROOT}i/${id}` : ROOT;
  if (!OBJECT_ID.test(id)) return ROOT; // profile/edit, community/nearby ...
  return `${ROOT}${type === "card" ? "profile" : type}/${id}`;
}

export function setSmartBannerArgument(pathname: string, doc: Document = document): void {
  const tag = doc.querySelector('meta[name="apple-itunes-app"]');
  if (!tag) return;
  tag.setAttribute("content", `app-id=${SMART_BANNER_APP_ID}, app-argument=${smartBannerArgument(pathname)}`);
}
