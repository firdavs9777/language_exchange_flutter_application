# Web ↔ app parity — owner steps (Phase 5)

Code for phases 0–4 is deployed (backend, website) or merged (app, ships with 2.7.0). These steps need
server, console or account access. Do them in this order; each says how to check it.

## 1. HTTPS for www.banatalk.com (site is broken on www today)

```bash
sudo certbot --nginx -d banatalk.com -d www.banatalk.com
```
Then make www redirect to the apex in the `server { server_name www.banatalk.com; … }` block:
`return 301 https://banatalk.com$request_uri;`
Check: `curl -sI https://www.banatalk.com | head -3` → `301` to `https://banatalk.com/`.

## 2. Apply the website's nginx snippet (link previews, iOS links)

File: web repo `deploy/nginx.snippet.conf` (read its header comments first — it replaces the existing
`location /`). It serves the Apple app-site-association file as `application/json`, returns real 404s,
and sends link-preview bots (KakaoTalk, Telegram, WhatsApp, Facebook, Slack, Discord, X…) on
`/moment|profile|community|story|i/<id>` to `https://api.banatalk.com/og/<type>/<id>`.
```bash
sudo nginx -t && sudo systemctl reload nginx
```
Check: `curl -s -A facebookexternalhit https://banatalk.com/moment/<a real id> | grep og:title` → the
moment's own title, not the generic site title. `curl -sI https://banatalk.com/.well-known/apple-app-site-association`
→ `content-type: application/json`.

## 3. Android App Links fingerprints

Play Console → your app → Test and release → App integrity → App signing: copy **both** SHA-256 values
(App signing key certificate and Upload key certificate). Send them to Claude (or edit web repo
`public/.well-known/assetlinks.json`, replacing `TODO_SHA256_UPLOAD` and `TODO_SHA256_PLAY_APP_SIGNING`)
and push web main.
Check on an Android phone with the app: `adb shell pm verify-app-links --re-verify com.bananatalk.app`
then `adb shell pm get-app-links com.bananatalk.app` → `banatalk.com: verified`.

## 4. Production env checks (backend `config/config.env`, then `pm2 restart language-app --update-env`)

- `GOOGLE_PUBSUB_AUDIENCE` (or `DOMAIN`) must equal the Play RTDN push audience
  `https://api.banatalk.com/api/v1/purchases/android/webhook`.
- `GOOGLE_PUBSUB_SERVICE_ACCOUNT` = the service account on the Play RTDN Pub/Sub push subscription
  (Google Cloud → Pub/Sub → Subscriptions → your subscription → Authentication).
- Check: `pm2 logs language-app --lines 200 | grep "Google Play RTDN received"` after a test purchase.

## 5. Sign in with Apple on the website (optional, stays hidden until done)

1. Apple Developer → Identifiers → Services IDs → new, e.g. `com.bananatalk.web`; enable Sign in with
   Apple; **group it with the primary App ID `com.bananatalk.bananatalkApp`** (team RJF4T5CJ76) so web and
   app sign-ins land on the same account; domain `banatalk.com`, return URL `https://banatalk.com/login`.
2. Backend env: `APPLE_WEB_SERVICES_ID=com.bananatalk.web`, `WEB_APPLE_SIGNIN_ENABLED=true`, restart.
3. Web: set `REACT_APP_APPLE_SERVICES_ID=com.bananatalk.web` in `.env.production`, push web main.
Check: "Continue with Apple" appears on /login; sign in with an Apple ID that already uses the app →
same account.

## 6. Turn the website features on, one at a time, after a browser check

Backend env → restart → open the site (hard refresh). Turn off again if anything looks wrong.

| Flag | Check before leaving it on |
|---|---|
| `WEB_REELS_ENABLED=true` | /reels grid, open a reel, like/comment, post a short reel; the app sees it |
| `WEB_GATHERINGS_ENABLED=true` | /gatherings list, join one, host one; app user sees it |
| `WEB_VOICE_ROOMS_ENABLED=true` | join an app user's voice room, hear and speak (needs two people) |
| `WEB_LANGUAGE_ROOMS_ENABLED=true` | /rooms, send a message; City and Genders tabs in Community |

`WEB_CALLS_ENABLED` is unused: website chats show "Call in the app" instead (decision 2026-10-16).

## 7. After 2.7.0 is most of the iOS base

- Add `/story/*` and `/chat/*` back to the web repo's `public/.well-known/apple-app-site-association`
  (2.6.1 can't open them, so they stay off until then).
- Turn on `REFERRALS_ENABLED` once Android App Links verify (step 3).

## 8. Release build note

Android Studio's bundled Java is now 25, which Gradle 8.11 can't run. Before building 2.7.0:
```bash
flutter config --jdk-dir=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

## 9. Renew the cdn.banatalk.com certificate (manual, every ~90 days — next before 2027-01-10)

cdn.banatalk.com is a CNAME to the DigitalOcean Spaces CDN; DNS is at Namecheap, so neither DO nor
certbot can renew it automatically. Last done 2026-10-19 (expires 2027-01-17).

1. Server: `sudo certbot certonly --manual --preferred-challenges dns -d cdn.banatalk.com --force-renewal --key-type ecdsa --new-key`
   If it prints a TXT value: Namecheap → Advanced DNS → add TXT, host `_acme-challenge.cdn`, TTL 1 min,
   wait until `dig +short TXT _acme-challenge.cdn.banatalk.com @1.1.1.1` shows it, then press Enter.
   (If the domain was validated in the last ~30 days it skips this and issues straight away.)
2. DigitalOcean → Settings → Security → SSL certificates → Add Certificate → Bring your own:
   Certificate = `cert.pem`, Private key = `privkey.pem`, Chain = `chain.pem`
   (all in `/etc/letsencrypt/live/cdn.banatalk.com/`; copy from your own terminal, never into a chat).
3. Spaces → my-projects-media → Settings → CDN → Edit → certificate dropdown → the new one → Save.
   Leave Edge Cache TTL alone.
4. Check: `echo | openssl s_client -connect cdn.banatalk.com:443 -servername cdn.banatalk.com 2>/dev/null | openssl x509 -noout -enddate`
   shows the new date. Then delete the old certificate in DO and the `_acme-challenge.cdn` TXT rows.
