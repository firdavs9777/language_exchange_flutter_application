import fs from "fs";
import path from "path";

/**
 * Every route change used to start where the last one left off.
 *
 * Reported from production: clicking a member in "More members like …" at the
 * foot of a profile loaded that person's profile with the window still scrolled
 * to the bottom. `/community/:userId` -> `/community/:otherId` changes only the
 * route param, so `ProfilePage` never unmounts and nothing resets the scroll.
 * Only `MomentDetail` and `MyMoments` had ever handled it, each with their own
 * `window.scrollTo(0, 0)` — so the fix that had been applied twice locally was
 * missing everywhere else.
 *
 * A static guard rather than a render test: `ScrollRestoration` returns null and
 * does its work through the data router, so there is nothing in the DOM to
 * assert on. What matters is that it is mounted once, in the root layout.
 */
const appSource = fs.readFileSync(
  path.resolve(__dirname, "../App.tsx"),
  "utf8"
);

describe("scroll restoration", () => {
  it("mounts the router's restorer in the root layout", () => {
    expect(appSource).toMatch(
      /import \{[^}]*ScrollRestoration[^}]*\} from "react-router-dom";/
    );
    expect(appSource).toContain("<ScrollRestoration />");
  });

  it("mounts it exactly once — two would fight over the same position", () => {
    expect(appSource.match(/<ScrollRestoration\s*\/>/g) || []).toHaveLength(1);
  });

  it("leaves back and forward to the restorer, not to a scrollTo reset", () => {
    // A `window.scrollTo(0, 0)` on every navigation sends a reader who pressed
    // Back to the top of the page they were half way down. The restorer knows
    // the difference; App must not second-guess it.
    expect(appSource).not.toMatch(/window\.scrollTo\(\s*0\s*,\s*0\s*\)/);
  });
});
