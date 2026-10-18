import fs from "fs";
import path from "path";

/**
 * Reported: the feed's cards are too big.
 *
 * Measured, they were -- 24px between cards on a desktop, on top of each card's
 * own 20px padding, with a four-step responsive padding ladder repeated on
 * every block inside it. Nothing is removed here; the air is.
 */
const feed = fs.readFileSync(
  path.resolve(__dirname, "./MainMoments.tsx"),
  "utf8"
);
const card = fs.readFileSync(
  path.resolve(__dirname, "./SingleMoment.tsx"),
  "utf8"
);

describe("moments density", () => {
  it("stacks the feed's cards at 16px on a desktop, not 24px", () => {
    expect(feed).toContain("space-y-3 sm:space-y-4");
    expect(feed).not.toContain("space-y-3 sm:space-y-6");
  });

  it("stops the card's padding ladder at 16px", () => {
    // The ladder climbed p-2 -> p-3 -> p-4 -> p-5. The last step is the one
    // that made a desktop card roomy; the smaller steps still serve phones.
    expect(card).not.toContain("md:p-5");
    expect(card).not.toContain("md:px-5");
  });
});
