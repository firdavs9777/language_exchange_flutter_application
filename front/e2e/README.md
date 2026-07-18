# Stories smoke test (Package 3, Phase E)

A minimal Playwright suite to smoke-test the revived Stories UI against a **real
backend** — the verification I could not run in-agent (no browser/backend/login
in that environment). It logs in, visits each Stories surface, and asserts the
pages render without a crash / error boundary.

## Prerequisites
- The web app running (e.g. `npm start`, default http://localhost:3000) **or** a
  deployed URL to point `WEB_URL` at.
- The backend reachable at whatever `REACT_APP_API_URL` the app was built with
  (default `http://localhost:5003`), with a **valid login** on it.

## Install (nothing added to package.json)
```bash
npm i -D @playwright/test
npx playwright install chromium
```

## Run
```bash
WEB_URL=http://localhost:3000 \
SMOKE_EMAIL=you@example.com \
SMOKE_PASSWORD='your-password' \
npx playwright test -c e2e/playwright.config.ts
```

Add `--headed` to watch it, or `--debug` to step through. Failures capture a
screenshot + video + trace (see the `playwright-report` / `test-results` output).

## What it checks
1. **Stories strip** renders on `/moments` (`.stories-feed-container`).
2. **/create-story** composer loads without crashing (and doesn't bounce to login).
3. **/highlights** loads and never shows `undefined stories` (the `storyCount` fix).
4. **Viewer**: if a story ring with content exists, clicking it routes to
   `/stories/:userId` and renders without crashing. Skips (with a note) if the
   feed has no stories — seed one and re-run to cover the viewer.

## Notes / tuning
- Selectors are based on the current components (`StoriesFeed.tsx` classes,
  `input[type=email|password]` on `Login.tsx`). If you restyle (e.g. the pending
  SCSS→Tailwind conversion) update the selectors here.
- `assertNoCrash` looks for the CRA dev-server overlay and generic error-boundary
  copy — adjust the regex if your `ErrorBoundary` uses different wording.
- This is a **smoke** suite (does it load + basic flow), not a full behavioral
  E2E. Deep assertions (posting a story end-to-end, reactions, poll votes) want
  seeded data and are worth adding once the smoke passes.
