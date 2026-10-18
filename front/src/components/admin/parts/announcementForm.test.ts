import {
  ANNOUNCEMENT_LOCALES, emptyForm, fromAnnouncement, toInput, validateForm,
  toLocalInput, fromLocalInput, targetingSummary, AnnouncementForm,
  deliveryInfo, matchesSearch, MAX_DELIVERY_ATTEMPTS, reachesApp,
} from "./announcementForm";

const filled = (over: Partial<AnnouncementForm> = {}): AnnouncementForm => ({
  ...emptyForm(),
  translations: { en: { title: "Hello", body: "World", buttonLabel: "" } },
  ...over,
});

it("covers the 19 backend template locales", () => {
  expect(ANNOUNCEMENT_LOCALES).toHaveLength(19);
  expect(ANNOUNCEMENT_LOCALES).toContain("zh_TW");
});

it("an empty form needs title and body in the default language", () => {
  const errors = validateForm(emptyForm());
  expect(errors["translations.en.title"]).toBeTruthy();
  expect(errors["translations.en.body"]).toBeTruthy();
  expect(validateForm(filled())).toEqual({});
});

it("limits mirror the backend: title 100, body 1000, button label 40", () => {
  const long = (n: number) => "x".repeat(n);
  expect(validateForm(filled({ translations: { en: { title: long(101), body: "b", buttonLabel: "" } } }))["translations.en.title"]).toMatch(/100/);
  expect(validateForm(filled({ translations: { en: { title: "t", body: long(1001), buttonLabel: "" } } }))["translations.en.body"]).toMatch(/1000/);
  expect(validateForm(filled({ translations: { en: { title: "t", body: "b", buttonLabel: long(41) } }, buttonUrl: "bananatalk://x" }))["translations.en.buttonLabel"]).toMatch(/40/);
});

it("a second language with any text needs both title and body", () => {
  const errors = validateForm(filled({
    translations: { en: { title: "t", body: "b", buttonLabel: "" }, ko: { title: "제목", body: "", buttonLabel: "" } },
  }));
  expect(errors["translations.ko.body"]).toBeTruthy();
});

it("button link: https or bananatalk:// only; a label needs a link", () => {
  // eslint-disable-next-line no-script-url
  expect(validateForm(filled({ buttonUrl: "javascript:alert(1)" })).buttonUrl).toBeTruthy();
  ["https://banatalk.com", "bananatalk://moment/1"].forEach((url) =>
    expect(validateForm(filled({ buttonUrl: url })).buttonUrl).toBeUndefined());
  ["/study", "//evil.com", "https://", "ftp://x.com"].forEach((url) =>
    expect(validateForm(filled({ buttonUrl: url })).buttonUrl).toBeTruthy());
  expect(validateForm(filled({ translations: { en: { title: "t", body: "b", buttonLabel: "Open" } } })).buttonUrl).toBeTruthy();
});

it("end after start; at least one channel; at least one platform; whole-number priority", () => {
  expect(validateForm(filled({ startsAt: "2030-01-02T10:00", endsAt: "2030-01-02T09:00" })).endsAt).toBeTruthy();
  expect(validateForm(filled({ showInApp: false, notify: false })).channels).toBeTruthy();
  expect(validateForm(filled({ platforms: [] })).platforms).toBeTruthy();
  expect(validateForm(filled({ priority: "1.5" })).priority).toBeTruthy();
});

it("scheduling needs a future start", () => {
  const now = new Date("2030-01-01T00:00:00");
  expect(validateForm(filled(), { schedule: true, now }).startsAt).toBeTruthy();
  expect(validateForm(filled({ startsAt: "2029-12-31T10:00" }), { schedule: true, now }).startsAt).toBeTruthy();
  expect(validateForm(filled({ startsAt: "2030-01-02T10:00" }), { schedule: true, now }).startsAt).toBeUndefined();
});

it("toInput drops empty extra languages, trims, 'all' wins, dates to ISO", () => {
  const input = toInput(filled({
    translations: {
      en: { title: " Hello ", body: "World", buttonLabel: "" },
      ko: { title: "", body: "", buttonLabel: "" },
    },
    platforms: ["all", "ios"],
    startsAt: "2030-01-02T10:00",
    priority: "4",
  }));
  expect(Object.keys(input.translations || {})).toEqual(["en"]);
  expect(input.translations!.en.title).toBe("Hello");
  expect(input.platforms).toEqual(["all"]);
  expect(input.startsAt).toBe(new Date("2030-01-02T10:00").toISOString());
  expect(input.priority).toBe(4);
  expect(input.buttonUrl).toBeNull();
});

it("toInput for a live announcement sends only text, end time and priority", () => {
  expect(Object.keys(toInput(filled(), true)).sort()).toEqual(["endsAt", "priority", "translations"]);
});

it("local datetime round-trips", () => {
  const iso = new Date("2030-05-06T07:08:00").toISOString();
  expect(fromLocalInput(toLocalInput(iso))).toBe(iso);
  expect(toLocalInput(null)).toBe("");
  expect(fromLocalInput("")).toBeNull();
});

it("fromAnnouncement fills the form from a row", () => {
  const form = fromAnnouncement({
    id: "a1", _id: "a1", status: "draft", priority: 2, defaultLocale: "ko",
    translations: { ko: { title: "제목", body: "본문" } },
    emoji: null, imageUrl: null, buttonUrl: null, platforms: ["ios"], languages: ["ko"],
    startsAt: null, endsAt: null, showInApp: true, notify: true, publishedAt: null, endedAt: null,
    delivery: { state: "none", targeted: 0, pushed: 0, listed: 0, failed: 0, startedAt: null, finishedAt: null },
    createdAt: "", updatedAt: "",
  });
  expect(form.translations.ko).toEqual({ title: "제목", body: "본문", buttonLabel: "" });
  expect(form.priority).toBe("2");
  expect(form.notify).toBe(true);
});

it("targeting summary", () => {
  expect(targetingSummary({ platforms: ["all"], languages: [] })).toBe("All platforms · all languages");
  expect(targetingSummary({ platforms: ["ios", "android"], languages: ["ko", "ja"] })).toBe("iOS + Android · ko, ja");
});

it("publishing now: an end time that is already past is caught before the request", () => {
  const now = new Date("2030-01-01T00:00:00");
  // No start time: the effective start is now, so an end at/before now can never be live.
  expect(validateForm(filled({ endsAt: "2029-12-31T10:00" }), { publish: true, now }).endsAt).toBeTruthy();
  expect(validateForm(filled({ endsAt: "2030-01-01T00:00" }), { publish: true, now }).endsAt).toBeTruthy();
  expect(validateForm(filled({ endsAt: "2030-01-02T10:00" }), { publish: true, now }).endsAt).toBeUndefined();
  expect(validateForm(filled(), { publish: true, now }).endsAt).toBeUndefined();
  // Not publishing: a past end on a plain draft save is the server's call.
  expect(validateForm(filled({ endsAt: "2029-12-31T10:00" }), { now }).endsAt).toBeUndefined();
});

it("emoji length is checked on the trimmed value", () => {
  expect(validateForm(filled({ emoji: "  " + "a".repeat(16) + "  " })).emoji).toBeUndefined();
  expect(validateForm(filled({ emoji: "a".repeat(17) })).emoji).toBeTruthy();
});

it("deliveryInfo: failed under the cap is retried only while live; at the cap it is exhausted", () => {
  expect(MAX_DELIVERY_ATTEMPTS).toBe(3);
  expect(deliveryInfo({ status: "draft" })).toEqual({ state: "none", attempts: 0, error: "", exhausted: false, retrying: false, stoppedAtEnd: false, endedByAdmin: false });
  const failedOnce = { state: "failed", attempts: 1, error: "fcm down" };
  expect(deliveryInfo({ status: "live", delivery: failedOnce })).toMatchObject({ retrying: true, exhausted: false, error: "fcm down" });
  expect(deliveryInfo({ status: "ended", delivery: failedOnce })).toMatchObject({ retrying: false, exhausted: false });
  expect(deliveryInfo({ status: "live", delivery: { state: "failed", attempts: 3, error: "x" } }))
    .toMatchObject({ retrying: false, exhausted: true, attempts: 3 });
  expect(deliveryInfo({ status: "live", delivery: { state: "done", attempts: 1, error: null } }))
    .toMatchObject({ state: "done", exhausted: false, error: "" });
});

it("matchesSearch looks at every locale's title and body, case-insensitively", () => {
  const a = { translations: { en: { title: "Study Hub", body: "New daily pack" }, ko: { title: "공지", body: "새 소식" } } };
  expect(matchesSearch(a, "")).toBe(true);
  expect(matchesSearch(a, "  hub ")).toBe(true);
  expect(matchesSearch(a, "DAILY")).toBe(true);
  expect(matchesSearch(a, "소식")).toBe(true);
  expect(matchesSearch(a, "calls")).toBe(false);
  expect(matchesSearch({}, "x")).toBe(false);
});

it("publishing keeps the start/end ordering rule (the backend model rejects it, and publish saves first)", () => {
  const now = new Date("2030-01-01T00:00:00");
  const form = filled({ startsAt: "2030-01-02T10:00", endsAt: "2030-01-01T18:00" });
  expect(validateForm(form, { publish: true, now }).endsAt).toBe(
    "End must be after start. Fix the start or end time before publishing."
  );
  expect(validateForm(form, { now }).endsAt).toBe("End must be after start.");
  // A past end is still caught when publishing.
  expect(validateForm(filled({ startsAt: "2029-12-01T10:00", endsAt: "2029-12-31T10:00" }), { publish: true, now }).endsAt).toBeTruthy();
});

it("deliveryInfo: done with stoppedReason end_time is flagged; a missing field or another state is not", () => {
  expect(deliveryInfo({ delivery: { state: "done", stoppedReason: "end_time" } }).stoppedAtEnd).toBe(true);
  expect(deliveryInfo({ delivery: { state: "done" } }).stoppedAtEnd).toBe(false);
  expect(deliveryInfo({ delivery: { state: "done", stoppedReason: null } }).stoppedAtEnd).toBe(false);
  expect(deliveryInfo({ delivery: { state: "failed", stoppedReason: "end_time" } }).stoppedAtEnd).toBe(false);
});

it("deliveryInfo: admin_end is flagged only on done; unknown reasons are plain", () => {
  expect(deliveryInfo({ delivery: { state: "done", stoppedReason: "admin_end" } })).toMatchObject({ endedByAdmin: true, stoppedAtEnd: false });
  expect(deliveryInfo({ delivery: { state: "failed", stoppedReason: "admin_end" } }).endedByAdmin).toBe(false);
  expect(deliveryInfo({ delivery: { state: "done", stoppedReason: "mystery" } })).toMatchObject({ endedByAdmin: false, stoppedAtEnd: false });
});

test("displayStyle round-trips and defaults to popup", () => {
  expect(emptyForm().displayStyle).toBe("popup");
  const f = { ...emptyForm(), displayStyle: "banner" as const, platforms: ["web" as const] };
  expect(toInput(f).displayStyle).toBe("banner");
  expect(fromAnnouncement({ ...(toInput(f) as any), id: "x", _id: "x", status: "draft", translations: { en: { title: "t", body: "b" } }, delivery: {} } as any).displayStyle).toBe("banner");
  expect(fromAnnouncement({ id: "x", _id: "x", status: "draft", translations: { en: { title: "t", body: "b" } }, delivery: {} } as any).displayStyle).toBe("popup");
});

test("reachesApp mirrors the backend rule; toInput forces notify off when it can't", () => {
  expect(reachesApp({ ...emptyForm(), platforms: ["all"] })).toBe(true);
  expect(reachesApp({ ...emptyForm(), platforms: ["web"] })).toBe(false);
  expect(reachesApp({ ...emptyForm(), displayStyle: "banner" })).toBe(false);
  expect(toInput({ ...emptyForm(), displayStyle: "banner", notify: true }).notify).toBe(false);
});

test("targeting summary names Web", () => {
  expect(targetingSummary({ platforms: ["web", "ios"], languages: [] })).toContain("Web");
});
