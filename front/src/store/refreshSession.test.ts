import { refreshSession } from "./refreshSession";

const okResponse = (body: any) =>
  Promise.resolve(new Response(JSON.stringify(body), { status: 200, headers: { "content-type": "application/json" } }));

afterEach(() => jest.restoreAllMocks());

function harness(userInfo: any) {
  const actions: any[] = [];
  const dispatch = (a: any) => {
    actions.push(a);
    return a;
  };
  const getState = () => ({ auth: { userInfo } });
  return { actions, dispatch, getState };
}

it("swaps in the fresh token and keeps the session", async () => {
  (global as any).fetch = jest.fn(() => okResponse({ token: "new-t", refreshToken: "new-r" }));
  const h = harness({ user: { _id: "u1" }, token: "old-t", refreshToken: "old-r" });
  await expect(refreshSession(h.dispatch, h.getState)).resolves.toBe(true);
  expect(h.actions[0].type).toBe("auth/setCredentials");
  expect(h.actions[0].payload).toEqual(expect.objectContaining({ token: "new-t", refreshToken: "new-r" }));
  const [, init] = ((global as any).fetch as jest.Mock).mock.calls[0];
  expect(JSON.parse(init.body)).toEqual({ refreshToken: "old-r" });
});

it("logs out with no refresh token", async () => {
  (global as any).fetch = jest.fn();
  const h = harness({ user: { _id: "u1" }, token: "old-t" });
  await expect(refreshSession(h.dispatch, h.getState)).resolves.toBe(false);
  expect(h.actions[0].type).toBe("auth/logout");
  expect((global as any).fetch).not.toHaveBeenCalled();
});

it("logs out when the refresh is refused", async () => {
  (global as any).fetch = jest.fn(() =>
    Promise.resolve(new Response(JSON.stringify({ success: false }), { status: 401 }))
  );
  const h = harness({ user: { _id: "u1" }, token: "old-t", refreshToken: "bad" });
  await expect(refreshSession(h.dispatch, h.getState)).resolves.toBe(false);
  expect(h.actions[0].type).toBe("auth/logout");
});
