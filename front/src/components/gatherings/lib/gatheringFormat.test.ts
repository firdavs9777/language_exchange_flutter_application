import {
  formatGatheringTime,
  hostLocalTime,
  minutesUntil,
  isHostDecisionDue,
  seatsLeft,
  quorumLine,
  toLocalInputValue,
  fromLocalInputValue,
  gatheringErrorText,
  personId,
  personName,
  rsvpState,
  topicLabel,
} from "./gatheringFormat";

const t: any = () => "";
const NOW = new Date("2026-11-01T08:00:00.000Z");
const base: any = {
  _id: "g1",
  title: "Coffee",
  language: "korean",
  startsAt: "2026-11-01T10:00:00.000Z",
  durationMinutes: 60,
  capacity: 6,
  quorum: 3,
  joinMode: "open",
  status: "scheduled",
  going: 1,
  needed: 2,
  quorumMet: false,
  viewerIsAttending: false,
  viewerIsHost: false,
};

describe("time", () => {
  it("formats in the given zone and language", () => {
    expect(formatGatheringTime("2026-11-01T10:00:00.000Z", "en", "UTC")).toMatch(/10:00/);
    expect(formatGatheringTime("2026-11-01T10:00:00.000Z", "en", "Asia/Seoul")).toMatch(/7:00/);
  });
  it("never throws on a bad date or zone", () => {
    expect(formatGatheringTime("not a date", "en")).toBe("");
    expect(formatGatheringTime("2026-11-01T10:00:00.000Z", "en", "Not/AZone")).not.toBe("");
  });
  it("adds the host's local time only when their zone differs", () => {
    expect(hostLocalTime({ ...base, hostTimezone: "Asia/Seoul" }, "en", "UTC")).toMatch(/7:00/);
    expect(hostLocalTime({ ...base, hostTimezone: "UTC" }, "en", "UTC")).toBe(null);
    expect(hostLocalTime({ ...base, hostTimezone: null }, "en", "UTC")).toBe(null);
    expect(hostLocalTime({ ...base, hostTimezone: "Bogus/Zone" }, "en", "UTC")).toBe(null);
  });
  it("round-trips datetime-local values through the viewer's zone", () => {
    const iso = fromLocalInputValue("2026-11-01T19:30");
    expect(toLocalInputValue(iso)).toBe("2026-11-01T19:30");
    expect(fromLocalInputValue("")).toBe("");
    expect(toLocalInputValue("garbage")).toBe("");
  });
  it("counts minutes to the start (negative once started)", () => {
    expect(minutesUntil(base.startsAt, NOW)).toBe(120);
    expect(minutesUntil(base.startsAt, new Date("2026-11-01T10:30:00.000Z"))).toBe(-30);
  });
});

describe("host decision window (app: !quorumMet && <= 120 min; web also needs status scheduled)", () => {
  const host = { ...base, viewerIsHost: true };
  it("is due for the host inside two hours with quorum unmet", () => {
    expect(isHostDecisionDue(host, NOW)).toBe(true);
  });
  it("is not due earlier, for a guest, once met, or after a decision", () => {
    expect(isHostDecisionDue(host, new Date("2026-11-01T07:59:00.000Z"))).toBe(false);
    expect(isHostDecisionDue(base, NOW)).toBe(false);
    expect(isHostDecisionDue({ ...host, quorumMet: true }, NOW)).toBe(false);
    expect(isHostDecisionDue({ ...host, status: "confirmed" }, NOW)).toBe(false);
    expect(isHostDecisionDue({ ...host, status: "cancelled" }, NOW)).toBe(false);
  });
  it("treats a missing quorumMet as needed === 0 (older payloads)", () => {
    expect(isHostDecisionDue({ ...host, quorumMet: undefined, needed: 0 }, NOW)).toBe(false);
  });
});

describe("quorum and seats", () => {
  it("seats left never goes negative", () => {
    expect(seatsLeft(base)).toBe(5);
    expect(seatsLeft({ ...base, going: 9 })).toBe(0);
  });
  it("says how many more are needed, or that it is confirmed", () => {
    expect(quorumLine(base, t)).toBe("2 more needed to confirm · 1 going");
    expect(quorumLine({ ...base, going: 3, needed: 0, quorumMet: true, status: "confirmed" }, t)).toBe(
      "Confirmed · 3 going"
    );
    expect(quorumLine({ ...base, status: "cancelled" }, t)).toBe("Cancelled");
    expect(quorumLine({ ...base, status: "ended" }, t)).toBe("Ended");
  });
  it("labels topics, unknown ones as-is", () => {
    expect(topicLabel("exam_prep", t)).toBe("Exam prep");
    expect(topicLabel("weird", t)).toBe("weird");
    expect(topicLabel(null, t)).toBe("");
  });
});

describe("rsvpState", () => {
  it("covers every button state the page can show", () => {
    expect(rsvpState({ ...base, viewerIsHost: true })).toBe("host");
    expect(rsvpState({ ...base, viewerIsAttending: true })).toBe("going");
    expect(rsvpState({ ...base, viewerRequestPending: true })).toBe("pending");
    expect(rsvpState({ ...base, going: 6 })).toBe("full");
    expect(rsvpState({ ...base, status: "cancelled" })).toBe("closed");
    expect(rsvpState({ ...base, status: "ended" })).toBe("closed");
    expect(rsvpState(base)).toBe("join");
    expect(rsvpState({ ...base, joinMode: "approval" })).toBe("request");
  });
});

describe("people", () => {
  it("reads populated and bare-id hosts", () => {
    expect(personId({ _id: "u1", name: "Ada" })).toBe("u1");
    expect(personId("u2")).toBe("u2");
    expect(personId(null)).toBe("");
    expect(personName({ _id: "u1", name: "", username: "ada" })).toBe("@ada");
    expect(personName("u2")).toBe("");
  });
});

describe("gatheringErrorText", () => {
  const err = (status: number, error: string) => ({ status, data: { success: false, error } });
  it("maps the backend's known refusals to friendly text", () => {
    expect(gatheringErrorText(err(400, "This gathering is full"), t)).toBe("This gathering is full.");
    expect(gatheringErrorText(err(400, "Your request is waiting for the host to approve it"), t)).toBe(
      "Your request is waiting for the host."
    );
    expect(
      gatheringErrorText(err(403, "You have cancelled or missed too many of your own gatherings to host a new one"), t)
    ).toBe("You can't host right now: too many of your gatherings were cancelled or missed.");
    expect(gatheringErrorText(err(400, "Capacity cannot be lower than the 4 already going"), t)).toBe(
      "Capacity can't be lower than the 4 people already going."
    );
    expect(gatheringErrorText(err(404, "Gathering not found"), t)).toBe("This gathering isn't available.");
    expect(gatheringErrorText(err(404, "Club not found"), t)).toBe("This club isn't available.");
  });
  it("falls back to a generic line, never raw server text", () => {
    expect(gatheringErrorText(err(400, "Something internal"), t)).toBe("Something went wrong. Try again.");
    expect(gatheringErrorText(undefined, t)).toBe("Something went wrong. Try again.");
    expect(gatheringErrorText({ status: "FETCH_ERROR" }, t)).toBe("You're offline. Check your connection.");
  });
});
