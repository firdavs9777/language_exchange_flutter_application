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
| `REACT_APP_ADS_DEV` | Set to `true` to enable ads in a non-production build | `true` |
| `REACT_APP_ADS_TEST` | Set to `true` to force `data-adtest="on"` in production | `true` |

Notes:
- In non-production builds ads are off unless `REACT_APP_ADS_DEV=true`.
- In non-production builds `data-adtest="on"` is applied automatically so test
  impressions don't count as invalid traffic (which can cause policy strikes).
  In production, add `REACT_APP_ADS_TEST=true` to force test mode.

## Going live

1. Set `REACT_APP_ADSENSE_CLIENT` and the three slot ids in the build env.
2. Edit `public/ads.txt` — replace `pub-0000000000000000` with your real
   publisher id (the digits after `ca-pub-`). It must be reachable at
   `https://<your-domain>/ads.txt`.
3. Ensure the deployed domain is approved in your AdSense account.

## SPA caveat

`AdUnit` pushes to the `adsbygoogle` queue exactly once per mount (a ref guard
prevents double-push under React 18 StrictMode / re-renders). Because this is a
single-page app, an ad is requested when the unit mounts; navigating away and
back remounts the unit. Ads will not fill on `localhost` — verify on the
approved production domain.
