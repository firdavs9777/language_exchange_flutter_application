import { routeTemplate } from "./routeTemplate";

it("replaces a param segment with its name", () => {
  expect(routeTemplate("/profile/abc123", { userId: "abc123" })).toBe("/profile/:userId");
});

it("replaces a param segment in the middle of the path", () => {
  // Every /chat route is keyed by the other person's user id; the chat
  // settings screen this used to cite was deleted along with its route.
  expect(routeTemplate("/chat/abc123/media", { userId: "abc123" })).toBe(
    "/chat/:userId/media"
  );
});

it("leaves the root path alone", () => {
  expect(routeTemplate("/", {})).toBe("/");
});

it("leaves a static path with no params alone", () => {
  expect(routeTemplate("/download", {})).toBe("/download");
});

it("replaces every segment equal to a param value", () => {
  expect(routeTemplate("/moment/12/x/12", { id: "12" })).toBe("/moment/:id/x/:id");
});

it("ignores the splat param", () => {
  expect(routeTemplate("/a/b", { "*": "a/b" })).toBe("/a/b");
});
