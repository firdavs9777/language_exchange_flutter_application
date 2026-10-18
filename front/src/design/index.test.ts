import * as Design from "./index";

// Nothing imports the barrel -- every test imports its component file
// directly. A wrong or missing export here would ship undetected.
it("re-exports every design primitive", () => {
  expect(Design.LanguageExchangePill).toBeDefined();
  expect(Design.dotsForLevel).toBeDefined();
  expect(Design.Avatar).toBeDefined();
  expect(Design.SurfaceCard).toBeDefined();
  expect(Design.Badge).toBeDefined();
  expect(Design.FollowButton).toBeDefined();
  expect(Design.ConfirmDialog).toBeDefined();
  expect(Design.notify).toBeDefined();
  expect(Design.TOAST_MS).toBeDefined();
});
