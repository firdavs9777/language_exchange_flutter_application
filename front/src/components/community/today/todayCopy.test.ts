import fs from "fs";
import path from "path";

/**
 * Review finding: "Your 1 matches today". The title takes a count but no
 * plural forms, and skipping cards makes 1 an everyday value. Rather than
 * plural machinery in 18 locales, the count is set apart -- in parentheses or
 * after a colon -- so no noun has to agree with it.
 */
const dir = path.resolve(__dirname, "../../../utils/locales");
const AGREEING = ["eng", "de", "es", "fr", "it", "pt"]; // languages where "N matches" would need to agree

describe("today's title reads right at any count", () => {
  it.each(AGREEING)("%s sets the count apart", (name) => {
    const title: string = JSON.parse(fs.readFileSync(path.join(dir, `${name}.json`), "utf8")).communityMain.today.title;
    expect(title).toMatch(/\(\{\{count\}\}\)|:\s*\{\{count\}\}/);
  });

  it("English never says '1 matches'", () => {
    const title: string = JSON.parse(fs.readFileSync(path.join(dir, "eng.json"), "utf8")).communityMain.today.title;
    expect(title.replace("{{count}}", "1")).not.toMatch(/\b1 matches\b/);
  });
});
