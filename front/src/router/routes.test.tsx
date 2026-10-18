/**
 * @jest-environment node
 */
// Runs without a DOM on purpose: the prerender step requires this module in
// plain Node, so importing it must never touch window, document or storage.
import { matchRoutes } from "react-router-dom";

// The prerender list is the source of truth for what counts as public; a
// hand-kept copy here drifted the moment /communities landed.
const PUBLIC_PATHS: string[] = require("../seo/pages").SEO_PAGES.map((p: { path: string }) => p.path);

it("imports without a DOM", () => {
  expect(typeof window).toBe("undefined");
  const { routes } = require("./routes");
  expect(routes[0].path).toBe("/");
  expect(routes[0].children.length).toBeGreaterThan(30);
});

it("matches every public marketing path to a layout plus a page", () => {
  const { routes } = require("./routes");
  for (const path of PUBLIC_PATHS) {
    const matches = matchRoutes(routes, path);
    expect(matches && matches.length).toBe(2);
    expect(matches![1].route.path).not.toBe("*");
  }
});

it("sends unknown paths to the catch-all route", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/no-such-page");
  expect(matches && matches.length).toBe(2);
  expect(matches![1].route.path).toBe("*");
});

// Since the app is split into route chunks, a navigation can fail: a chunk
// fetch that 404s (a tab left open across a deploy) rejects inside Suspense.
// Without an errorElement react-router replaces the whole app with its default
// stack-trace screen. This asserts the boundary is actually wired to the root
// route, where it catches every route below it.
it("puts an error boundary on the root route", () => {
  const { routes } = require("./routes");
  const RouteError = require("../components/errors/RouteError").default;
  expect(routes[0].errorElement).toBeTruthy();
  expect(routes[0].errorElement.type).toBe(RouteError);
});

// The admin console is a lazy child tree. It must resolve to real routes (not
// the catch-all) while still importing in plain Node: React.lazy defers the
// import until something renders it, and nothing prerenders /admin.
it("matches the admin console paths to real routes, not the catch-all", () => {
  const { routes } = require("./routes");
  for (const path of ["/admin", "/admin/reach", "/admin/users", "/admin/content", "/admin/ai-usage", "/admin/audit", "/admin/announcements"]) {
    const matches = matchRoutes(routes, path);
    expect(matches && matches.length).toBe(3); // App -> AdminLayout -> page
    for (const m of matches!) {
      expect(m.route.path).not.toBe("*");
    }
  }
});

// The profile redesign put one component on both profile paths. The element on
// each route is <Suspense><LazyThing /></Suspense>, and a lazy component keeps
// no record of what it will import -- so lazyWithRetry is swapped for a stub
// that hangs its sessionStorage key (the module path) on the component, which
// is the only thing that identifies the chunk without resolving the import.
function chunkKeysFor(paths: string[]): string[] {
  let keys: string[] = [];
  jest.isolateModules(() => {
    jest.doMock("./lazyWithRetry", () => ({
      lazyWithRetry: (key: string) => {
        const Stub: any = () => null;
        Stub.chunkKey = key;
        return Stub;
      },
    }));
    const { routes } = require("./routes");
    keys = paths.map((path) => {
      const matches = matchRoutes(routes, path);
      const element: any = matches![matches!.length - 1].route.element;
      return element.props.children.type.chunkKey;
    });
    jest.dontMock("./lazyWithRetry");
  });
  return keys;
}

it("renders the one profile page on both /profile and /profile/:userId", () => {
  const [own, other, edit] = chunkKeysFor(["/profile", "/profile/abc123", "/profile/edit"]);
  expect(own).toBe("../components/profile/ProfilePage");
  expect(other).toBe("../components/profile/ProfilePage");
  // The static segment still wins over the dynamic one.
  expect(edit).toBe("../components/profile/EditProfile");
});

// Followers, following and visitors are one page behind five paths: the three
// own-list paths every existing link already points at, and the two per-user
// paths the profile's stat tiles link to.
it("puts every follower/following/visitor path on the one list page", () => {
  const keys = chunkKeysFor([
    "/followersList",
    "/followingsList",
    "/visitors",
    "/profile/abc123/followers",
    "/profile/abc123/following",
  ]);
  for (const key of keys) {
    expect(key).toBe("../components/profile/UserListPage");
  }
});

// The per-user list paths are longer than "profile/:userId", so they must win
// over it -- otherwise /profile/abc123/followers renders the profile page.
it("ranks the per-user list paths above the profile route", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/profile/abc123/followers");
  expect(matches![matches!.length - 1].route.path).toBe("profile/:userId/followers");
});

// The member page and the profile page are one page. /community/<id> is the
// link the app, the list and every share sheet already hand out, so it keeps
// working -- it just resolves to ProfilePage now, out of the same chunk as
// /profile/<id>, which is what makes the second visit free.
it("resolves /community/:id and /profile/:id to the one profile page", () => {
  const [community, profile] = chunkKeysFor(["/community/abc123", "/profile/abc123"]);
  expect(community).toBe("../components/profile/ProfilePage");
  expect(profile).toBe("../components/profile/ProfilePage");
});

// ProfilePage reads `useParams().userId`; a route that still said ":id" would
// render the signed-in user's own profile at every member URL.
it("names the member-page param userId, as ProfilePage reads it", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/community/abc123");
  expect(matches![matches!.length - 1].route.path).toBe("community/:userId");
  expect(matches![matches!.length - 1].params.userId).toBe("abc123");
});

// The static community paths must keep beating the dynamic member path.
it("keeps /community/nearby off the member page", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/community/nearby");
  expect(matches![matches!.length - 1].route.path).toBe("community/nearby");
});

// Every /chat route is keyed by the other person's user id -- that is what
// /chat/:userId carries, what ChatContent queries the thread with, and what
// the media gallery reads out of useParams. The param was named
// `conversationId` on the media route, which was never true.
it("names the media gallery's param userId", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/chat/abc123/media");
  expect(matches![matches!.length - 1].route.path).toBe("chat/:userId/media");
  expect(matches![matches!.length - 1].params.userId).toBe("abc123");
});

// The settings screen is gone: the "..." info panel in the chat header
// replaced it, and the route it left behind pointed at a deleted module.
it("no longer routes the chat settings screen", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/chat/abc123/settings");
  expect(matches![matches!.length - 1].route.path).toBe("*");
});

// The author's own stories page had no route at all: the component shipped in
// Task S2 and nothing could reach it. "mine" is a static segment sitting
// beside "stories/:userId", so this also pins the ranking -- if the dynamic
// route ever won, /stories/mine would open the viewer for a user called
// "mine".
it("resolves the author's own stories page ahead of the story viewer", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/stories/mine");
  expect(matches && matches.length).toBe(2);
  expect(matches![1].route.path).toBe("stories/mine");

  const viewer = matchRoutes(routes, "/stories/some-user-id");
  expect(viewer![1].route.path).toBe("stories/:userId");
});

it("routes old /moments/:id links to the redirect without touching /moments or /moments/saved", () => {
  const { routes } = require("./routes");
  const MomentLinkRedirect = require("./MomentLinkRedirect").default;
  const last = (path: string) => { const m = matchRoutes(routes, path)!; return m[m.length - 1].route; };
  expect(last("/moments/abc").element.type).toBe(MomentLinkRedirect);
  expect(last("/moments/saved").path).toBe("moments/saved");
  expect(last("/moments").path).toBe("moments");
});

it("routes /announcement/:id to its own page, not the catch-all", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/announcement/abc");
  expect(matches && matches.length).toBe(2);
  expect(matches![1].route.path).toBe("announcement/:id");
});

// Story share links (app 2.7.0, chat story cards): /story/<storyId>, a story id,
// next to -- not inside -- /stories/<userId>, which is keyed by the author.
it("matches /story/<id> to the story link page, not the catch-all or the viewer", () => {
  const { routes } = require("./routes");
  const matches = matchRoutes(routes, "/story/507f1f77bcf86cd799439011");
  expect(matches && matches.length).toBe(2);
  expect(matches![1].route.path).toBe("story/:id");
  expect(matchRoutes(routes, "/stories/abc")![1].route.path).toBe("stories/:userId");
});
