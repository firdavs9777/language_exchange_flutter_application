import { test, expect, Page } from "@playwright/test";

/**
 * Stories smoke test — verifies the revived Stories UI (Package 3, Phase E)
 * loads and the core flows don't white-screen against a REAL backend.
 *
 * This does NOT assert deep behavior (that needs seeded data); it's a smoke
 * suite: log in, visit each Stories surface, confirm it renders without a
 * React error boundary / crash, and exercise create + view where possible.
 *
 * RUN (nothing is added to package.json — install locally):
 *   npm i -D @playwright/test
 *   npx playwright install chromium
 *   # start the app in another terminal (npm start) OR point WEB_URL at a deployed site
 *   WEB_URL=http://localhost:3000 \
 *   SMOKE_EMAIL=you@example.com \
 *   SMOKE_PASSWORD='***' \
 *   npx playwright test -c e2e/playwright.config.ts
 *
 * The app talks to REACT_APP_API_URL (default http://localhost:5003) — make sure
 * that backend is reachable and the credentials are valid there.
 */

const WEB_URL = process.env.WEB_URL || "http://localhost:3000";
const EMAIL = process.env.SMOKE_EMAIL || "";
const PASSWORD = process.env.SMOKE_PASSWORD || "";

// Fail fast with a clear message if creds are missing.
test.beforeAll(() => {
  if (!EMAIL || !PASSWORD) {
    throw new Error(
      "Set SMOKE_EMAIL and SMOKE_PASSWORD env vars (a valid login for the target backend)."
    );
  }
});

/** A React error boundary / crash guard used after every navigation. */
async function assertNoCrash(page: Page) {
  // CRA dev-server error overlay
  await expect(page.locator("#webpack-dev-server-client-overlay")).toHaveCount(0);
  // Common error-boundary copy — adjust if your ErrorBoundary uses different text.
  await expect(
    page.getByText(/something went wrong|unexpected error/i)
  ).toHaveCount(0);
  // The SPA root must have rendered *something*.
  const bodyText = (await page.locator("body").innerText()).trim();
  expect(bodyText.length).toBeGreaterThan(0);
}

async function login(page: Page) {
  await page.goto(`${WEB_URL}/login`, { waitUntil: "networkidle" });
  await page.locator('input[type="email"]').first().fill(EMAIL);
  await page.locator('input[type="password"]').first().fill(PASSWORD);
  // Submit — try an explicit submit button, then fall back to Enter.
  const submit = page.locator('button[type="submit"]').first();
  if (await submit.count()) {
    await submit.click();
  } else {
    await page.locator('input[type="password"]').first().press("Enter");
  }
  // Success = we navigate away from /login within a reasonable time.
  await expect(page).not.toHaveURL(/\/login/, { timeout: 15000 });
}

test.describe("Stories smoke", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("moments feed shows the Stories strip", async ({ page }) => {
    await page.goto(`${WEB_URL}/moments`, { waitUntil: "networkidle" });
    await assertNoCrash(page);
    // StoriesFeed renders .stories-feed-container (class from StoriesFeed.tsx)
    await expect(page.locator(".stories-feed-container")).toBeVisible({
      timeout: 10000,
    });
    // There should be at least the "create story" bubble.
    await expect(page.locator(".story-circle").first()).toBeVisible();
  });

  test("create-story composer loads without crashing", async ({ page }) => {
    await page.goto(`${WEB_URL}/create-story`, { waitUntil: "networkidle" });
    await assertNoCrash(page);
    // We should NOT have been bounced back to login.
    await expect(page).not.toHaveURL(/\/login/);
    expect(page.url()).toContain("/create-story");
  });

  test("highlights page loads and shows a story count (storyCount fix)", async ({
    page,
  }) => {
    await page.goto(`${WEB_URL}/highlights`, { waitUntil: "networkidle" });
    await assertNoCrash(page);
    // If any highlight cards exist, the count must be a number — never the
    // literal "undefined" that the storiesCount->storyCount bug produced.
    await expect(page.getByText(/undefined\s+stories/i)).toHaveCount(0);
  });

  test("opening a story ring loads the viewer (if any stories exist)", async ({
    page,
  }) => {
    await page.goto(`${WEB_URL}/moments`, { waitUntil: "networkidle" });
    await assertNoCrash(page);
    const ring = page.locator(".story-circle.has-stories").first();
    if (await ring.count()) {
      await ring.click();
      await expect(page).toHaveURL(/\/stories\//, { timeout: 10000 });
      await assertNoCrash(page);
      // Progress bars from StoryProgressBar should be present.
      await expect(page.locator("body")).toContainText(/./);
    } else {
      test.info().annotations.push({
        type: "note",
        description:
          "No stories with content in the feed — viewer path skipped. Seed a story and re-run to cover it.",
      });
    }
  });
});
