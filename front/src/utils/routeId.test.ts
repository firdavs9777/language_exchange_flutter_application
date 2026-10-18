import routeId from "./routeId";

/**
 * Reported from production: a shared card link arrived as
 *   /card/6a7eb3d492fdab67baeed15f%20Practice%20English%20with%20me%20on%20BananaTalk
 * A share target had glued the Web Share `text` onto the `url`, and the page
 * looked up a user whose id was the whole sentence. Links like that are
 * already out in chats; the id at the front of them is still good.
 */
describe("routeId", () => {
  it("takes the id off the front of a link with a sentence glued on", () => {
    expect(routeId("6a7eb3d492fdab67baeed15f Practice English with me on BananaTalk")).toBe(
      "6a7eb3d492fdab67baeed15f"
    );
  });

  it("takes it when the junk is glued on with no space at all", () => {
    expect(routeId("6a7eb3d492fdab67baeed15f).")).toBe("6a7eb3d492fdab67baeed15f");
    expect(routeId("6a7eb3d492fdab67baeed15fPractice")).toBe("6a7eb3d492fdab67baeed15f");
  });

  it("leaves a clean id alone", () => {
    expect(routeId("6a7eb3d492fdab67baeed15f")).toBe("6a7eb3d492fdab67baeed15f");
  });

  it("falls back to the first word for an id that is not an ObjectId", () => {
    expect(routeId("u2")).toBe("u2");
    expect(routeId("  u2 and more ")).toBe("u2");
  });

  it("is empty for nothing", () => {
    expect(routeId(undefined)).toBe("");
    expect(routeId("")).toBe("");
  });
});
