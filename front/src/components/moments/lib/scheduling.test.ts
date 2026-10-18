import { isScheduledLater, localInputToIso, minScheduleInput, isFutureInput } from "./scheduling";

const NOW = new Date("2026-10-08T10:00:30.000Z").getTime();

describe("scheduling", () => {
  it("a moment is scheduled only while its time is ahead", () => {
    expect(isScheduledLater({ scheduledFor: "2026-10-09T00:00:00.000Z" }, NOW)).toBe(true);
    expect(isScheduledLater({ scheduledFor: "2026-10-07T00:00:00.000Z" }, NOW)).toBe(false);
    expect(isScheduledLater({ scheduledFor: null }, NOW)).toBe(false);
    expect(isScheduledLater({}, NOW)).toBe(false);
    expect(isScheduledLater({ scheduledFor: "garbage" }, NOW)).toBe(false);
  });

  it("turns a datetime-local value into an ISO instant", () => {
    const local = "2026-10-09T09:30";
    expect(localInputToIso(local)).toBe(new Date(local).toISOString());
    expect(localInputToIso("")).toBeNull();
    expect(localInputToIso("nope")).toBeNull();
  });

  it("the earliest pickable minute is the next whole minute, in local time", () => {
    const min = minScheduleInput(NOW);
    expect(min).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/);
    expect(new Date(min).getTime()).toBeGreaterThan(NOW);
    expect(new Date(min).getTime() - NOW).toBeLessThanOrEqual(60000);
  });

  it("knows a past input from a future one", () => {
    expect(isFutureInput(minScheduleInput(NOW), NOW)).toBe(true);
    expect(isFutureInput("2020-01-01T00:00", NOW)).toBe(false);
    expect(isFutureInput("", NOW)).toBe(false);
  });
});
