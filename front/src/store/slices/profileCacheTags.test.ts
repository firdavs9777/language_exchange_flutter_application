/**
 * The two cache-invalidation paths the profile redesign depends on, asserted
 * against the real store with a mocked `fetch` — both were silently broken:
 *
 * - `getMyMoments` provided no tags, so `deleteMoment`'s `invalidatesTags`
 *   matched nothing and a deleted moment reappeared on the next visit inside
 *   `keepUnusedDataFor`.
 * - `updateUserInfo` declared `providesTags` (meaningless on a mutation)
 *   instead of `invalidatesTags`, so a profile save never refetched
 *   `getUserProfile`.
 */
import { makeStore } from "../../store";
import { momentsApiSlice } from "./momentsSlice";
import { usersApiSlice } from "./usersSlice";
import { MOMENTS_URL } from "../../constants";

function mockFetch(): string[] {
  const calls: string[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    calls.push(`${req.method} ${req.url}`);
    return new Response(JSON.stringify({ success: true, data: [] }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  });
  return calls;
}

const gets = (calls: string[], fragment: string): string[] =>
  calls.filter((call) => call.indexOf("GET ") === 0 && call.indexOf(fragment) > -1);

afterEach(() => {
  delete (global as any).fetch;
});

it("refetches the user's moments after one is deleted", async () => {
  const calls = mockFetch();
  const store = makeStore();

  await store.dispatch(
    momentsApiSlice.endpoints.getMyMoments.initiate({ userId: "u1" })
  );
  expect(gets(calls, `${MOMENTS_URL}/user/u1`)).toHaveLength(1);

  await store.dispatch(momentsApiSlice.endpoints.deleteMoment.initiate("m1"));
  // The invalidation is queued as a microtask after the mutation settles.
  await Promise.resolve();
  await new Promise((resolve) => setTimeout(resolve, 0));

  expect(gets(calls, `${MOMENTS_URL}/user/u1`).length).toBeGreaterThan(1);
});

it("refetches the signed-in user's profile after a save", async () => {
  const calls = mockFetch();
  const store = makeStore();

  await store.dispatch(usersApiSlice.endpoints.getUserProfile.initiate({}));
  expect(gets(calls, "/auth/me")).toHaveLength(1);

  await store.dispatch(
    usersApiSlice.endpoints.updateUserInfo.initiate({ name: "Ada" })
  );
  await Promise.resolve();
  await new Promise((resolve) => setTimeout(resolve, 0));

  expect(gets(calls, "/auth/me").length).toBeGreaterThan(1);
});

it("refetches the stories feed after a block, so the blocked author's ring disappears", async () => {
  const { storiesApiSlice } = require("./storiesSlice");
  const calls = mockFetch();
  const store = makeStore();

  await store.dispatch(storiesApiSlice.endpoints.getStoryFeeds.initiate(undefined));
  expect(gets(calls, "/stories/feed")).toHaveLength(1);

  await store.dispatch(usersApiSlice.endpoints.blockUser.initiate("u2"));
  await Promise.resolve();
  await new Promise((resolve) => setTimeout(resolve, 0));

  expect(gets(calls, "/stories/feed").length).toBeGreaterThan(1);
});
