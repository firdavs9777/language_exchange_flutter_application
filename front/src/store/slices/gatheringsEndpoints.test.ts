// Every request the website sends for gatherings and clubs, against the real
// backend routes (be/routes/gatherings.js, be/routes/clubs.js) and in the same
// shape the app's GatheringApiClient sends.
import { makeStore } from "../../store";
import { gatheringsApiSlice, gatheringListQuery, gatheringEditBody } from "./gatheringsSlice";
import { GATHERINGS_URL, CLUBS_URL } from "../../constants";

type Captured = { url: string; method: string; body: string | null; contentType: string | null };

function mockFetch(payload: any = { success: true, data: {} }, status = 200): Captured[] {
  const calls: Captured[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    let body: string | null = null;
    if (req.method !== "GET" && req.method !== "HEAD") {
      // A FormData body is not readable as text under the jsdom fetch polyfill.
      try {
        body = await req.clone().text();
      } catch (e) {
        body = "[form-data]";
      }
    }
    calls.push({
      url: req.url,
      method: req.method,
      body,
      contentType: req.headers && req.headers.get ? req.headers.get("content-type") : null,
    });
    return new Response(JSON.stringify(payload), { status, headers: { "content-type": "application/json" } });
  });
  return calls;
}

const originalFetch = global.fetch;
afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

const ep = () => (gatheringsApiSlice.endpoints as any);
const run = async (name: string, arg?: any) => {
  const store = makeStore();
  return store.dispatch(ep()[name].initiate(arg));
};
const path = (c: Captured) => new URL(c.url).pathname;
const json = (c: Captured) => JSON.parse(c.body as string);

describe("gatheringListQuery (what the browse page asks for)", () => {
  it("always sends scope and page, like the app", () => {
    expect(gatheringListQuery({})).toBe("scope=mine&page=1");
  });
  it("adds only the filters that are set, and hasSeat only when on", () => {
    expect(
      gatheringListQuery({ scope: "all", page: 2, topic: "grammar", when: "week", hasSeat: true, language: "Korean" })
    ).toBe("scope=all&page=2&language=Korean&topic=grammar&when=week&hasSeat=true");
    expect(gatheringListQuery({ scope: "me", hasSeat: false, topic: "" })).toBe("scope=me&page=1");
  });
});

describe("gatherings", () => {
  it("lists with GET /gatherings?<query> and unwraps data to an array", async () => {
    const calls = mockFetch({ success: true, count: 1, data: [{ _id: "g1" }] });
    const res: any = await run("getGatherings", { scope: "all", page: 1 });
    expect(path(calls[0])).toBe(GATHERINGS_URL);
    expect(new URL(calls[0].url).search).toBe("?scope=all&page=1");
    expect(res.data).toEqual([{ _id: "g1" }]);
  });

  it("an empty or odd envelope is still an array (the page maps over it)", async () => {
    mockFetch({ success: true });
    const res: any = await run("getGatherings", {});
    expect(res.data).toEqual([]);
  });

  it("detail is GET /gatherings/:id, unwrapped", async () => {
    const calls = mockFetch({ success: true, data: { _id: "g1", title: "Coffee" } });
    const res: any = await run("getGathering", "g1");
    expect(path(calls[0])).toBe(`${GATHERINGS_URL}/g1`);
    expect(res.data).toEqual({ _id: "g1", title: "Coffee" });
  });

  it("creates with POST /gatherings and the app's body", async () => {
    const calls = mockFetch();
    await run("createGathering", {
      title: "Korean coffee chat",
      language: "Korean",
      startsAt: "2026-11-01T10:00:00.000Z",
      description: "",
      durationMinutes: 60,
      capacity: 6,
      quorum: 3,
      joinMode: "open",
      topic: "conversation",
      club: "c1",
    });
    expect(calls[0].method).toBe("POST");
    expect(path(calls[0])).toBe(GATHERINGS_URL);
    expect(json(calls[0])).toEqual({
      title: "Korean coffee chat",
      language: "Korean",
      startsAt: "2026-11-01T10:00:00.000Z",
      description: "",
      durationMinutes: 60,
      capacity: 6,
      quorum: 3,
      joinMode: "open",
      topic: "conversation",
      club: "c1",
    });
  });

  it("edits with PUT /gatherings/:id and only the changed fields", async () => {
    const calls = mockFetch();
    await run("updateGathering", { id: "g1", body: { title: "New" } });
    expect(calls[0].method).toBe("PUT");
    expect(path(calls[0])).toBe(`${GATHERINGS_URL}/g1`);
    expect(json(calls[0])).toEqual({ title: "New" });
  });

  it.each([
    ["cancelGathering", "g1", "DELETE", "/g1", null],
    ["rsvpGathering", "g1", "POST", "/g1/rsvp", null],
    ["cancelRsvp", "g1", "DELETE", "/g1/rsvp", null],
    ["hostDecision", { id: "g1", run: false }, "POST", "/g1/decision", { run: false }],
    ["endGathering", "g1", "POST", "/g1/end", null],
    ["decideJoinRequest", { id: "g1", userId: "u9", approve: true }, "POST", "/g1/requests/u9", { approve: true }],
    ["removeGatheringCover", "g1", "DELETE", "/g1/cover", null],
  ])("%s -> %s %s", async (name, arg, method, suffix, body) => {
    const calls = mockFetch();
    await run(name as string, arg);
    expect(calls[0].method).toBe(method);
    expect(path(calls[0])).toBe(`${GATHERINGS_URL}${suffix}`);
    if (body) expect(json(calls[0])).toEqual(body);
  });

  it("rsvp keeps the server's `pending` flag on the result", async () => {
    mockFetch({ success: true, data: { _id: "g1", viewerIsAttending: false, pending: true }, pending: true });
    const res: any = await run("rsvpGathering", "g1");
    expect(res.data).toEqual({ _id: "g1", viewerIsAttending: false, pending: true });
  });

  it("uploads a cover as a FormData body with field `image` (uploadSingleCompressed('image'))", async () => {
    const calls = mockFetch({ success: true, data: { coverImage: "https://cdn/x.jpg" } });
    const append = jest.spyOn(FormData.prototype, "append");
    const file = new File(["x"], "cover.jpg", { type: "image/jpeg" });
    await run("setGatheringCover", { id: "g1", file });
    expect(calls[0].method).toBe("POST");
    expect(path(calls[0])).toBe(`${GATHERINGS_URL}/g1/cover`);
    // fetchBaseQuery only JSON-encodes plain objects; a FormData body keeps
    // the browser's multipart boundary (no JSON content type set).
    expect(calls[0].contentType || "").not.toMatch(/application\/json/);
    expect(append).toHaveBeenCalledWith("image", file);
  });
});

describe("clubs", () => {
  it("lists with scope and page", async () => {
    const calls = mockFetch({ success: true, data: [] });
    await run("getClubs", { scope: "member", page: 1 });
    expect(path(calls[0])).toBe(CLUBS_URL);
    expect(new URL(calls[0].url).search).toBe("?scope=member&page=1");
  });

  it.each([
    ["getClub", "c1", "GET", "/c1", null],
    ["createClub", { name: "Seoul readers", description: "Books", language: "Korean", interest: "books" }, "POST", "", { name: "Seoul readers", description: "Books", language: "Korean", interest: "books" }],
    ["updateClub", { id: "c1", body: { city: "Seoul" } }, "PUT", "/c1", { city: "Seoul" }],
    ["deleteClub", "c1", "DELETE", "/c1", null],
    ["joinClub", "c1", "POST", "/c1/join", null],
    ["leaveClub", "c1", "DELETE", "/c1/join", null],
    ["removeClubMember", { id: "c1", userId: "u2" }, "DELETE", "/c1/members/u2", null],
    ["setClubMemberRole", { id: "c1", userId: "u2", role: "organizer" }, "PUT", "/c1/members/u2", { role: "organizer" }],
    ["removeClubCover", "c1", "DELETE", "/c1/cover", null],
  ])("%s -> %s", async (name, arg, method, suffix, body) => {
    const calls = mockFetch({ success: true, data: name === "getClubs" ? [] : {} });
    await run(name as string, arg);
    expect(calls[0].method).toBe(method);
    expect(path(calls[0])).toBe(`${CLUBS_URL}${suffix}`);
    if (body) expect(json(calls[0])).toEqual(body);
  });
});

describe("gatheringEditBody (partial PUT, like the app)", () => {
  const before: any = {
    title: "A", description: "", language: "korean", languageLabel: "Korean", level: null, topic: null,
    startsAt: "2026-11-01T10:00:00.000Z", durationMinutes: 60, capacity: 6, joinMode: "open",
  };
  it("sends nothing when nothing changed", () => {
    expect(gatheringEditBody(before, { ...before })).toEqual({});
  });
  it("sends only the changed fields, and the label as `language`", () => {
    expect(
      gatheringEditBody(before, { ...before, title: "B", capacity: 8, languageLabel: "Japanese" })
    ).toEqual({ title: "B", capacity: 8, language: "Japanese" });
  });
  it("sends topic: null to clear a topic", () => {
    expect(gatheringEditBody({ ...before, topic: "grammar" }, { ...before, topic: null })).toEqual({ topic: null });
  });
  it("compares start times as instants, not strings", () => {
    expect(gatheringEditBody(before, { ...before, startsAt: "2026-11-01T10:00:00Z" })).toEqual({});
  });
});
