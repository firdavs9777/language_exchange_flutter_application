/**
 * The prerendered HTML is always logged out (the prerender's store is built in
 * Node, where there is no localStorage). If the browser's first render restored
 * the session from localStorage, a signed-in visitor would hydrate a logged-in
 * navbar over logged-out markup — React #418, and a full client re-render of
 * every prerendered page. So on a prerendered page the slice starts logged out
 * and App restores the session after the first commit.
 */

const STORED = {
  user: { _id: "u1", name: "Ada", email: "ada@example.com", role: "admin" },
  token: "tok",
  refreshToken: "ref",
};

function loadSlice() {
  let mod: any;
  jest.isolateModules(() => {
    mod = require("./authSlice");
  });
  return mod;
}

function initialUserInfo(mod: any) {
  return mod.default(undefined, { type: "@@INIT" }).userInfo;
}

beforeEach(() => {
  window.localStorage.clear();
  document.body.innerHTML = "";
});

afterEach(() => {
  document.body.innerHTML = "";
});

it("starts logged out on a prerendered page, even with a stored session", () => {
  window.localStorage.setItem("userInfo", JSON.stringify(STORED));
  document.body.innerHTML = '<div id="root"><div>server</div></div>';

  expect(initialUserInfo(loadSlice())).toBeNull();
});

it("keeps the stored session on a client-rendered page", () => {
  window.localStorage.setItem("userInfo", JSON.stringify(STORED));
  document.body.innerHTML = '<div id="root"></div>';

  expect(initialUserInfo(loadSlice())).toEqual(STORED);
});

it("readStoredUserInfo returns the normalized stored value", () => {
  window.localStorage.setItem("userInfo", JSON.stringify(STORED));
  document.body.innerHTML = '<div id="root"><div>server</div></div>';

  expect(loadSlice().readStoredUserInfo()).toEqual(STORED);
});

it("readStoredUserInfo normalizes the old { data } shape and rewrites storage", () => {
  window.localStorage.setItem(
    "userInfo",
    JSON.stringify({ data: STORED.user, token: "tok", refreshToken: "ref" })
  );

  expect(loadSlice().readStoredUserInfo()).toEqual(STORED);
  expect(JSON.parse(window.localStorage.getItem("userInfo") as string)).toEqual(STORED);
});

it("readStoredUserInfo returns null when nothing is stored or it is corrupt", () => {
  const mod = loadSlice();
  expect(mod.readStoredUserInfo()).toBeNull();
  window.localStorage.setItem("userInfo", "{not json");
  expect(mod.readStoredUserInfo()).toBeNull();
});
