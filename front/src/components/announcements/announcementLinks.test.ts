import { webTargetFor } from "./announcementLinks";

test.each([
  ["https://example.com/x", { kind: "external", href: "https://example.com/x" }],
  ["http://example.com", { kind: "external", href: "http://example.com" }],
  ["bananatalk://moment/abc", { kind: "internal", path: "/moment/abc" }],
  ["bananatalk://moments/abc", { kind: "internal", path: "/moment/abc" }],
  ["bananatalk://profile/u1", { kind: "internal", path: "/profile/u1" }],
  ["bananatalk://community/u1", { kind: "internal", path: "/community/u1" }],
  ["bananatalk://i/CODE", { kind: "internal", path: "/i/CODE" }],
  ["bananatalk://announcement/a1", { kind: "internal", path: "/announcement/a1" }],
  ["bananatalk://study", null],
  ["bananatalk://", null],
  ["javascript:alert(1)", null],
  ["", null],
  [null, null],
])("%s", (url, expected) => {
  expect(webTargetFor(url as any)).toEqual(expected);
});
