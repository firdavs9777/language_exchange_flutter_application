import { validateGatheringForm, defaultGatheringValues, MAX_CAPACITY, MAX_DAYS_AHEAD } from "./gatheringFormRules";

const NOW = new Date("2026-11-01T08:00:00.000Z");
const good = () => ({ ...defaultGatheringValues(NOW, "Korean"), title: "Coffee chat" });

it("defaults like the app: target language, tomorrow 19:00 local, 6 seats, quorum 3, open, 60 min", () => {
  const v = defaultGatheringValues(NOW, "Korean");
  const start = new Date(v.startsAt);
  expect(v.language).toBe("Korean");
  expect(start.getHours()).toBe(19);
  expect(start.getMinutes()).toBe(0);
  expect(start.getTime()).toBeGreaterThan(NOW.getTime());
  expect(v).toEqual(expect.objectContaining({ capacity: 6, quorum: 3, joinMode: "open", durationMinutes: 60, level: "", topic: "" }));
  expect(MAX_CAPACITY).toBe(20);
  expect(MAX_DAYS_AHEAD).toBe(90);
});

it("accepts a complete form", () => {
  expect(validateGatheringForm(good(), { mode: "create", now: NOW })).toEqual({});
});

it("requires a title of at most 120 characters and a language", () => {
  expect(validateGatheringForm({ ...good(), title: "   " }, { mode: "create", now: NOW })).toEqual({ title: "titleRequired" });
  expect(validateGatheringForm({ ...good(), title: "x".repeat(121) }, { mode: "create", now: NOW })).toEqual({ title: "titleTooLong" });
  expect(validateGatheringForm({ ...good(), language: "" }, { mode: "create", now: NOW })).toEqual({ language: "languageRequired" });
});

it("caps the description at 2000", () => {
  expect(validateGatheringForm({ ...good(), description: "x".repeat(2001) }, { mode: "create", now: NOW })).toEqual({
    description: "descriptionTooLong",
  });
});

it("needs a start in the future and within 90 days", () => {
  expect(validateGatheringForm({ ...good(), startsAt: "" }, { mode: "create", now: NOW })).toEqual({ startsAt: "startRequired" });
  expect(validateGatheringForm({ ...good(), startsAt: "2026-11-01T07:00:00.000Z" }, { mode: "create", now: NOW })).toEqual({
    startsAt: "startInPast",
  });
  expect(validateGatheringForm({ ...good(), startsAt: "2027-03-01T10:00:00.000Z" }, { mode: "create", now: NOW })).toEqual({
    startsAt: "startTooFar",
  });
});

it("keeps capacity 2-20 and quorum 2..capacity", () => {
  expect(validateGatheringForm({ ...good(), capacity: 1 }, { mode: "create", now: NOW })).toEqual({ capacity: "capacityRange" });
  expect(validateGatheringForm({ ...good(), capacity: 21 }, { mode: "create", now: NOW })).toEqual({ capacity: "capacityRange" });
  expect(validateGatheringForm({ ...good(), quorum: 1 }, { mode: "create", now: NOW })).toEqual({ quorum: "quorumRange" });
  expect(validateGatheringForm({ ...good(), capacity: 4, quorum: 5 }, { mode: "create", now: NOW })).toEqual({ quorum: "quorumRange" });
});

it("on edit, an unchanged start time is not re-checked (it is not sent)", () => {
  const past = "2026-10-01T10:00:00.000Z";
  expect(validateGatheringForm({ ...good(), startsAt: past }, { mode: "edit", now: NOW, originalStartsAt: past })).toEqual({});
  expect(validateGatheringForm({ ...good(), startsAt: "2026-10-02T10:00:00.000Z" }, { mode: "edit", now: NOW, originalStartsAt: past })).toEqual({
    startsAt: "startInPast",
  });
});

it("on edit, capacity cannot drop below the people already going, and quorum is not checked", () => {
  expect(validateGatheringForm({ ...good(), capacity: 3, quorum: 9 }, { mode: "edit", now: NOW, going: 4 })).toEqual({
    capacity: "capacityBelowGoing",
  });
  expect(validateGatheringForm({ ...good(), capacity: 4, quorum: 9 }, { mode: "edit", now: NOW, going: 4 })).toEqual({});
});
