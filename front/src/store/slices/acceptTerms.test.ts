import { ACCEPT_TERMS_URL } from "../../constants";

describe("accept-terms endpoint", () => {
  it("has the accept-terms path", () => {
    expect(ACCEPT_TERMS_URL).toBe("/api/v1/auth/accept-terms");
  });
});
