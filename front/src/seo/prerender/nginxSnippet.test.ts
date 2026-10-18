/**
 * @jest-environment node
 */
import fs from "fs";
import path from "path";

/**
 * deploy/nginx.snippet.conf is applied by hand on the droplet (README "nginx"),
 * so nothing but this test notices when an edit breaks it. Link previews
 * (links#4): chat apps and social sites fetch a shared banatalk.com link once,
 * run no JavaScript, and so only ever saw the homepage's tags. The snippet now
 * sends those fetchers to the backend's real cards at api.banatalk.com/og/.
 */
const raw = fs.readFileSync(path.resolve(__dirname, "../../../deploy/nginx.snippet.conf"), "utf8");
// Comments stripped, so prose can never satisfy an assertion.
const conf = raw
  .split("\n")
  .map((line) => line.replace(/#.*$/, ""))
  .join("\n");

interface Loc { regex: RegExp; source: string; body: string; at: number }

/** Every `location ~ <regex> { ... }` block (one level of nested braces). */
function regexLocations(): Loc[] {
  const out: Loc[] = [];
  const re = /location ~(\*?) (\S+) \{((?:[^{}]|\{[^{}]*\})*)\}/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(conf))) {
    out.push({ regex: new RegExp(m[2], m[1] ? "i" : ""), source: m[2], body: m[3], at: m.index });
  }
  return out;
}

/** The UA alternations used by the bot `if`s (nginx `~*` = case-insensitive PCRE). */
function botRegexes(): RegExp[] {
  const out: RegExp[] = [];
  const re = /if \(\$http_user_agent ~\* "([^"]+)"\)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(conf))) out.push(new RegExp(m[1], "i"));
  return out;
}

const HEX = "507f1f77bcf86cd799439011";
const PREVIEW_PATHS = [`/moment/${HEX}`, `/profile/${HEX}`, `/community/${HEX}`, `/story/${HEX}`, "/i/ABCD2345"];
const botLocationFor = (p: string) => regexLocations().find((l) => l.regex.test(p) && /http_user_agent/.test(l.body));

describe("link-preview crawler rule", () => {
  it("covers all five shareable link types, with or without a trailing slash", () => {
    for (const p of PREVIEW_PATHS) {
      expect(botLocationFor(p)).toBeTruthy();
      expect(botLocationFor(`${p}/`)).toBeTruthy();
    }
  });

  it("never sends web-only pages that share a prefix to the OG endpoint", () => {
    for (const p of ["/community/nearby", "/profile/edit", `/profile/${HEX}/followers`, "/moments/saved", "/moment/"]) {
      expect(botLocationFor(p)).toBeUndefined();
    }
  });

  it("sits before the generated routes include and before location /", () => {
    const first = Math.min(...PREVIEW_PATHS.map((p) => botLocationFor(p)!.at));
    expect(first).toBeLessThan(conf.indexOf("nginx.routes.conf"));
    expect(first).toBeLessThan(conf.indexOf("location / {"));
  });

  it("copies the location captures before the UA if (the if's match overwrites $1/$2)", () => {
    for (const p of PREVIEW_PATHS) {
      const body = botLocationFor(p)!.body;
      expect(body.indexOf("set $og_id")).toBeGreaterThanOrEqual(0);
      expect(body.indexOf("set $og_id")).toBeLessThan(body.indexOf("if ("));
      expect(body).toMatch(/rewrite \^ \/__og\/[^ ]+ last;/);
      expect(body).not.toMatch(/rewrite[^;]*\$[12]/);
      // Humans still get the app exactly as the generated routes conf serves it.
      expect(body).toContain("try_files $uri $uri/index.html /app.html;");
    }
  });

  it("matches link-preview fetchers and nothing a person or a search engine uses", () => {
    const bots = botRegexes();
    expect(bots.length).toBeGreaterThan(0);
    const isBot = (ua: string) => bots.every((re) => re.test(ua));
    for (const ua of [
      "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)",
      "facebookexternalhit/1.1 Facebot Twitterbot/1.0", // iMessage
      "Twitterbot/1.0",
      "Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)",
      "kakaotalk-scrap/1.0; +https://devtalk.kakao.com/t/scrap/33984",
      "WhatsApp/2.23.20.0 A",
      "Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)",
      "LinkedInBot/1.0 (compatible; Mozilla/5.0; Apache-HttpClient +http://www.linkedin.com)",
      "TelegramBot (like TwitterBot)",
    ]) {
      expect(isBot(ua)).toBe(true);
    }
    for (const ua of [
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) [FBAN/FBIOS;FBAV/450.0]",
      "Mozilla/5.0 (Linux; Android 14) LinkedInApp/9.29",
      "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
      "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
      "Mozilla/5.0 (Macintosh) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17 Safari/605.1.15 (Applebot/0.1)",
    ]) {
      expect(isBot(ua)).toBe(false);
    }
  });

  it("proxies the internal /__og/ location to the backend card over TLS, with short timeouts and an SPA fallback", () => {
    const og = regexLocations().find((l) => l.source.indexOf("__og") >= 0);
    expect(og).toBeTruthy();
    const b = og!.body;
    expect(b).toMatch(/^\s*internal;/m);
    expect(b).toContain("proxy_pass https://api.banatalk.com/og/$1/$2;");
    expect(b).toContain("proxy_set_header Host api.banatalk.com;");
    expect(b).toContain("proxy_ssl_server_name on;");
    expect(b).toMatch(/resolver \S+/); // proxy_pass with variables needs one
    expect(b).toMatch(/proxy_connect_timeout \d+s;/);
    expect(b).toMatch(/proxy_read_timeout \d+s;/);
    expect(b).toContain("proxy_intercept_errors on;");
    expect(b).toMatch(/error_page 500 502 503 504 = @og_fallback;/);
    expect(conf).toMatch(/location @og_fallback \{\s*try_files \/app\.html =404;\s*\}/);
    for (const type of ["moment", "profile", "community", "story", "i"]) {
      expect(og!.regex.test(`/__og/${type}/abc123`)).toBe(true);
    }
  });
});
