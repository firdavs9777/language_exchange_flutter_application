import { isBoostLive, boostProgress, lastEndedBoost, formatBoostRemaining, boostErrorKind, BOOST_RESULT_WINDOW_MS } from "./boostLogic";

const NOW = Date.parse("2026-10-18T12:00:00Z");
const iso = (ms: number) => new Date(ms).toISOString();
const H = 3600000;

it("a boost is live until it ends, unless expired or refunded", () => {
  expect(isBoostLive({ _id: "a", endsAt: iso(NOW + H), status: "active" }, NOW)).toBe(true);
  expect(isBoostLive({ _id: "a", endsAt: iso(NOW - 1), status: "active" }, NOW)).toBe(false);
  expect(isBoostLive({ _id: "a", endsAt: iso(NOW + H), status: "expired" }, NOW)).toBe(false);
  expect(isBoostLive(null, NOW)).toBe(false);
});

it("progress is the share of the 24h window used, clamped", () => {
  const b = { _id: "a", startsAt: iso(NOW - 6 * H), endsAt: iso(NOW + 18 * H) };
  expect(boostProgress(b, NOW)).toBeCloseTo(0.25);
  expect(boostProgress(b, NOW + 48 * H)).toBe(1);
  expect(boostProgress({ _id: "x" }, NOW)).toBe(0);
});

it("the last ended boost counts only within 7 days and skips refunds", () => {
  const ended = { _id: "e", endsAt: iso(NOW - 2 * H), status: "expired", impressions: 40 };
  const refunded = { _id: "r", endsAt: iso(NOW - H), status: "refunded" };
  const old = { _id: "o", endsAt: iso(NOW - BOOST_RESULT_WINDOW_MS - H), status: "expired" };
  expect(lastEndedBoost([refunded, ended], NOW)).toBe(ended);
  expect(lastEndedBoost([old], NOW)).toBeNull();
  expect(lastEndedBoost([{ _id: "l", endsAt: iso(NOW + H), status: "active" }], NOW)).toBeNull();
  expect(lastEndedBoost(undefined, NOW)).toBeNull();
});

it("formats the time left", () => {
  const t = () => "";
  expect(formatBoostRemaining(3 * H + 5 * 60000, t)).toBe("3h 5m");
  expect(formatBoostRemaining(5 * 60000, t)).toBe("5m");
  expect(formatBoostRemaining(30000, t)).toBe("Ending soon");
});

it("maps the purchase refusals", () => {
  expect(boostErrorKind({ status: 402, data: { error: "insufficient_coins" } })).toBe("insufficient_coins");
  expect(boostErrorKind({ status: 409, data: { error: "already_boosted" } })).toBe("already_boosted");
  expect(boostErrorKind({ status: 429, data: { error: "capacity_full" } })).toBe("capacity_full");
  expect(boostErrorKind({ status: 429, data: { error: "Too many requests" } })).toBe("other");
  expect(boostErrorKind({ status: 500 })).toBe("other");
});
