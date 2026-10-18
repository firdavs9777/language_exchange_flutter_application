import { EMAIL_RE } from "./validation";

it("accepts a plain address and rejects one without a domain", () => {
  expect(EMAIL_RE.test("ada@example.com")).toBe(true);
  expect(EMAIL_RE.test("not-an-email")).toBe(false);
});
