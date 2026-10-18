import { callLabel, callPreviewText, formatCallDuration, outcomeOf } from "./callLabel";

/**
 * One call message is shared by both people; each side words it from
 * media.callData.outcome and whether the viewer placed the call — the app's
 * CallLabels (lib/models/call_outcome.dart), case for case.
 */
const ME = "me";
const THEM = "u2";

describe("outcomeOf", () => {
  it("reads outcome when the server wrote one", () => {
    expect(outcomeOf({ outcome: "busy" })).toBe("busy");
  });
  it("maps the legacy status of rows written before outcome existed", () => {
    expect(outcomeOf({ status: "ended" })).toBe("completed");
    expect(outcomeOf({ status: "answered" })).toBe("completed");
    expect(outcomeOf({ status: "missed" })).toBe("no_answer");
    expect(outcomeOf({ status: "rejected" })).toBe("declined");
    expect(outcomeOf({ status: "busy" })).toBe("busy");
  });
  it("treats an unknown or empty record as a completed call, like the app", () => {
    expect(outcomeOf({ outcome: "exploded" })).toBe("completed");
    expect(outcomeOf(undefined)).toBe("completed");
  });
});

describe("formatCallDuration", () => {
  it("is m:ss under an hour and h:mm:ss above", () => {
    expect(formatCallDuration(0)).toBe("0:00");
    expect(formatCallDuration(75)).toBe("1:15");
    expect(formatCallDuration(3725)).toBe("1:02:05");
  });
  it("never shows a negative or fractional duration", () => {
    expect(formatCallDuration(-5)).toBe("0:00");
    expect(formatCallDuration(61.9)).toBe("1:01");
    expect(formatCallDuration(NaN)).toBe("0:00");
  });
});

describe("callLabel, from each side", () => {
  const cases: Array<[string, any, string, string, boolean]> = [
    // [name, callData, viewer, expected fallback, negative]
    ["caller, completed voice", { outcome: "completed", type: "audio", initiator: ME, duration: 75 }, ME, "Outgoing voice call", false],
    ["callee, completed video", { outcome: "completed", type: "video", initiator: THEM }, ME, "Incoming video call", false],
    ["caller, no answer", { outcome: "no_answer", type: "audio", initiator: ME }, ME, "Voice call · No answer", false],
    ["callee, no answer = missed", { outcome: "no_answer", type: "audio", initiator: THEM }, ME, "Missed voice call", true],
    ["caller, cancelled", { outcome: "cancelled", type: "video", initiator: ME }, ME, "Cancelled video call", false],
    ["callee, cancelled = missed", { outcome: "cancelled", type: "video", initiator: THEM }, ME, "Missed video call", true],
    ["caller, declined", { outcome: "declined", type: "audio", initiator: ME }, ME, "Voice call declined", true],
    ["callee, declined", { outcome: "declined", type: "audio", initiator: THEM }, ME, "Declined voice call", true],
    ["caller, busy", { outcome: "busy", type: "audio", initiator: ME }, ME, "Ada was on another call", false],
    ["callee, busy = missed", { outcome: "busy", type: "audio", initiator: THEM }, ME, "Missed voice call", true],
  ];
  cases.forEach(([name, data, viewer, fallback, negative]) => {
    it(name, () => {
      const label = callLabel(data, viewer, false, "Ada");
      expect(label.fallback).toBe(fallback);
      expect(label.negative).toBe(negative);
    });
  });

  it("only a completed call carries a duration", () => {
    expect(callLabel({ outcome: "completed", initiator: ME, duration: 75 }, ME, false, "Ada").duration).toBe("1:15");
    expect(callLabel({ outcome: "no_answer", initiator: ME, duration: 75 }, ME, false, "Ada").duration).toBeNull();
  });

  it("reads a populated initiator as well as a bare id", () => {
    expect(callLabel({ outcome: "completed", initiator: { _id: ME } }, ME, false, "Ada").direction).toBe("outgoing");
  });

  it("falls back to the bubble's side when the record names no initiator", () => {
    expect(callLabel({ outcome: "completed" }, ME, true, "Ada").direction).toBe("outgoing");
    expect(callLabel({ outcome: "completed" }, ME, false, "Ada").direction).toBe("incoming");
  });
});

describe("callPreviewText", () => {
  it("adds the duration to a completed call, the way the app's list does", () => {
    const t = () => "";
    expect(
      callPreviewText(t, { outcome: "completed", type: "audio", initiator: ME, duration: 75 }, ME, true, "Ada")
    ).toBe("Outgoing voice call · 1:15");
    expect(callPreviewText(t, { outcome: "no_answer", initiator: THEM }, ME, false, "Ada")).toBe("Missed voice call");
  });
});
