import { MUTE_DURATIONS, muteArgs } from "./muteDurations";

it("offers 1 hour, 8 hours, 1 week and always, in that order", () => {
  expect(MUTE_DURATIONS.map((d) => d.id)).toEqual(["1h", "8h", "1w", "always"]);
  expect(MUTE_DURATIONS.map((d) => d.ms)).toEqual([3600000, 28800000, 604800000, null]);
});

it("builds the mutation argument: a duration, or none for always", () => {
  expect(muteArgs("c1", 3600000)).toEqual({ conversationId: "c1", duration: 3600000 });
  expect(muteArgs("c1", null)).toEqual({ conversationId: "c1" });
});
