import fs from "fs";
import path from "path";

// Every moments_section.* key these files use must exist in eng.json, and
// none may use the unreachable `moments.` root ("moments" is a string).
const FILES = [
  "SavedMoments.tsx",
  "SingleMoment.tsx",
  "CreateMoment.tsx",
  "MainMoments.tsx",
  "MomentDetail.tsx",
  "MomentChips.tsx",
  "media/VoiceNoteRecorder.tsx",
  "media/MomentThumb.tsx",
  "comments/CommentItem.tsx",
  "comments/CommentComposer.tsx",
  "actions/ReportMomentDialog.tsx",
  "actions/BlockAuthorDialog.tsx",
];

const eng = JSON.parse(fs.readFileSync(path.join(__dirname, "../../utils/locales/eng.json"), "utf8"));
const has = (key: string): boolean => {
  let node: any = eng;
  const parts = key.split(".");
  for (let i = 0; i < parts.length; i += 1) {
    if (!node || typeof node !== "object") return false;
    node = node[parts[i]];
  }
  return typeof node === "string";
};

const keysIn = (file: string): string[] => {
  const source = fs.readFileSync(path.join(__dirname, file), "utf8");
  const out: string[] = [];
  const re = /\bt\(\s*["'`]([A-Za-z0-9_.]+)["'`]/g;
  let m = re.exec(source);
  while (m) {
    if (out.indexOf(m[1]) < 0) out.push(m[1]);
    m = re.exec(source);
  }
  return out;
};

it("no moments file reads the unreachable moments.* root", () => {
  FILES.forEach((file) => {
    const bad = keysIn(file).filter((k) => k.indexOf("moments.") === 0);
    expect({ file, bad }).toEqual({ file, bad: [] });
  });
});

it("every moments_section.* key the moments UI uses exists in eng.json", () => {
  FILES.forEach((file) => {
    // ReportMomentDialog builds keys from a table; its template key is skipped.
    const missing = keysIn(file).filter((k) => k.indexOf("moments_section.") === 0 && !has(k));
    expect({ file, missing }).toEqual({ file, missing: [] });
  });
});

it("the Saved page's seven strings are reachable", () => {
  ["title", "momentCount", "removeSuccess", "removeError", "remove", "noMoments", "browseMoments"].forEach((k) =>
    expect(has(`moments_section.saved.${k}`)).toBe(true)
  );
});

it("no hard-coded English left in the audited spots", () => {
  const read = (f: string) => fs.readFileSync(path.join(__dirname, f), "utf8");
  expect(read("SingleMoment.tsx")).not.toMatch(/toast\.error\("Please login to like posts"/);
  expect(read("SingleMoment.tsx")).not.toMatch(/\? "See less" : "See more"/);
  expect(read("media/VoiceNoteRecorder.tsx")).not.toMatch(/<span>Voice recording is not supported/);
  expect(read("MainMoments.tsx")).not.toMatch(/>\s*Prompt of the day\s*</);
  expect(read("MomentDetail.tsx")).not.toMatch(/>Tags:</);
  expect(read("CreateMoment.tsx")).not.toMatch(/\? 'Sharing\.\.\.' : 'Share'/);
});
