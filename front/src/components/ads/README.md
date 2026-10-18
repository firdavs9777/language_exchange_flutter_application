# Ads (Google AdSense)

Env-gated AdSense integration for web parity with the Flutter app (banner below
the moment-detail action row, native/display ads interleaved in the feed and
comments). **Ads are a complete no-op until `REACT_APP_ADSENSE_CLIENT` is set** —
`AdUnit` renders `null` and the loader never injects the AdSense script, so the
app behaves exactly as before when the env is unset.

## Environment variables

Set these in `.env` (or your host's build env). All are optional; ads stay off
until at least `REACT_APP_ADSENSE_CLIENT` is provided.

| Variable | Purpose | Example |
| --- | --- | --- |
| `REACT_APP_ADSENSE_CLIENT` | Publisher id. Nothing renders without it. | `ca-pub-XXXXXXXXXXXXXXXX` |
| `REACT_APP_ADSENSE_SLOT_MOMENT_DETAIL` | Slot id for the moment-detail banner | `1234567890` |
| `REACT_APP_ADSENSE_SLOT_FEED` | Slot id for feed interleaved ads | `1234567891` |
| `REACT_APP_ADSENSE_SLOT_COMMENTS` | Slot id for the in-comments ad | `1234567892` |
| `REACT_APP_ADSENSE_SLOT_HOME` | Slot id for the home (marketing) page ad | `1234567893` |
| `REACT_APP_ADSENSE_SLOT_COMMUNITY` | Slot id for community-list interleaved ads | `1234567894` |
| `REACT_APP_ADSENSE_SLOT_PROFILE` | Slot id for the profile overview ad | `1234567895` |
| `REACT_APP_ADSENSE_AUTO_ADS` | Set to `true` to put the AdSense script on every page so Auto ads can place ads site-wide | `true` |
| `REACT_APP_ADS_DEV` | Set to `true` to enable ads in a non-production build | `true` |
| `REACT_APP_ADS_TEST` | Set to `true` to force `data-adtest="on"` in production | `true` |

Notes:
- In non-production builds ads are off unless `REACT_APP_ADS_DEV=true`.
- The slot ids are independent of Auto ads. A manual `AdUnit` renders only where
  its own slot id is set, so leaving them empty while `REACT_APP_ADSENSE_AUTO_ADS`
  is on means Auto ads alone decide placement.
- In non-production builds `data-adtest="on"` is applied automatically so test
  impressions don't count as invalid traffic (which can cause policy strikes).
  In production, add `REACT_APP_ADS_TEST=true` to force test mode.

## Who sees ads

Two rules, both in `adsGate.ts` so the manual units, the site-wide bootstrap and
the tests share one answer:

- **VIP users never see ads.** Ad-free is a benefit the app sells, and the web
  reads the same user document (`userMode === "vip"`, or an active
  `vipSubscription`), so a subscription bought in the app is honoured here. The
  unit renders nothing and never pushes to the queue.
- **Declining the consent bar gives non-personalized ads, not no ads.**
  `AdsBootstrap` mirrors the decision onto `adsbygoogle.requestNonPersonalizedAds`
  on mount and on every later change. Google's own certified GDPR message
  (Privacy & messaging in the AdSense console) sits on top of this for EU
  visitors and needs no code here.

## Going live

1. Set `REACT_APP_ADSENSE_CLIENT` in the build env (`.env.production` already
   carries the live publisher id). Add slot ids only for the manual placements
   you actually created in the console; the rest stay empty and render nothing.
2. `public/ads.txt` must carry the real publisher id (the digits after
   `ca-pub-`) and be reachable at `https://<your-domain>/ads.txt`.
3. Ensure the deployed domain is approved in your AdSense account.
4. Turn Auto ads on for the site in the AdSense console. Page exclusions are
   configured there, not in this code.

## SPA caveat

`AdUnit` pushes to the `adsbygoogle` queue exactly once per mount (a ref guard
prevents double-push under React 18 StrictMode / re-renders). Because this is a
single-page app, an ad is requested when the unit mounts; navigating away and
back remounts the unit. Ads will not fill on `localhost` — verify on the
approved production domain.
