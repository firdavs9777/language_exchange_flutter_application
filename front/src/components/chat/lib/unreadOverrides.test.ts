import { bumpUnread, displayUnread, pruneOverrides } from "./unreadOverrides";

it("bumps from what is on screen, not from the socket's payload", () => {
  const server = { u2: 4 };
  const once = bumpUnread("u2", server, {});
  expect(once).toEqual({ u2: 5 });
  expect(bumpUnread("u2", server, once)).toEqual({ u2: 6 });
});

it("shows the override while it is ahead of the server", () => {
  expect(displayUnread("u2", { u2: 4 }, { u2: 6 })).toBe(6);
  expect(displayUnread("u3", { u2: 4 }, {})).toBe(0);
});

it("drops an override once the server has caught up (the server wins)", () => {
  expect(pruneOverrides({ u2: 6 }, { u2: 6, u3: 2 })).toEqual({ u3: 2 });
  expect(pruneOverrides({ u2: 0 }, { u2: 0 })).toEqual({});
});
