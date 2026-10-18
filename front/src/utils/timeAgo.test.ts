import timeAgo from "./timeAgo";

// The three call sites this replaces all ran with a real `t`. Here `t` is the
// missing-key case — it returns "" — because that is the only case in which
// the three used to differ, and therefore the only one worth pinning.
const noKeys = () => "";
const withKeys = (key: string, vars?: any): string => {
  if (key === "moments_section.timeAgo.justNow") return "just now";
  if (key === "moments_section.timeAgo.minutesAgo") return `${vars.minutes}m ago`;
  if (key === "moments_section.timeAgo.hoursAgo") return `${vars.hours}h ago`;
  if (key === "moments_section.timeAgo.daysAgo") return `${vars.days}d ago`;
  return "";
};

const minutesAgo = (n: number) => new Date(Date.now() - n * 60000).toISOString();
const hoursAgo = (n: number) => minutesAgo(n * 60);
const daysAgo = (n: number) => hoursAgo(n * 24);

it("says 'just now' under a minute", () => {
  expect(timeAgo(minutesAgo(0), noKeys)).toBe("just now");
});

it("counts minutes, then hours, then days", () => {
  expect(timeAgo(minutesAgo(30), noKeys)).toBe("30m");
  expect(timeAgo(hoursAgo(5), noKeys)).toBe("5h");
  expect(timeAgo(daysAgo(3), noKeys)).toBe("3d");
});

it("spells the English fallback with 'ago' only when asked", () => {
  expect(timeAgo(minutesAgo(30), noKeys, { withAgo: true })).toBe("30m ago");
  expect(timeAgo(hoursAgo(5), noKeys, { withAgo: true })).toBe("5h ago");
  expect(timeAgo(daysAgo(3), noKeys, { withAgo: true })).toBe("3d ago");
});

it("hands a week-old timestamp to the locale date by default", () => {
  const old = daysAgo(30);
  expect(timeAgo(old, noKeys)).toBe(new Date(old).toLocaleDateString());
});

it("keeps counting days when the caller asked for that", () => {
  expect(timeAgo(daysAgo(30), noKeys, { beyondWeek: "days" })).toBe("30d");
});

it("prefers the translation over every fallback", () => {
  // The translated strings are identical for all three callers, which is why
  // one helper can serve them: the options only choose an English fallback.
  expect(timeAgo(minutesAgo(30), withKeys)).toBe("30m ago");
  expect(timeAgo(minutesAgo(30), withKeys, { withAgo: true })).toBe("30m ago");
});

it("renders nothing for a missing or unparseable timestamp", () => {
  expect(timeAgo(undefined, noKeys)).toBe("");
  expect(timeAgo("", noKeys)).toBe("");
  expect(timeAgo("not a date", noKeys)).toBe("");
});
