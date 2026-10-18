/**
 * @jest-environment node
 */
import { matchRoutes } from "react-router-dom";

const FLAGGED: Array<[string, string]> = [
  ["/voice-rooms", "webVoiceRoomsEnabled"],
  ["/voice-rooms/r1", "webVoiceRoomsEnabled"],
  ["/rooms", "webLanguageRoomsEnabled"],
  ["/rooms/r1", "webLanguageRoomsEnabled"],
  ["/community/city", "webLanguageRoomsEnabled"],
  ["/community/genders", "webLanguageRoomsEnabled"],
  ["/boost", "boostsEnabled"],
];

it.each(FLAGGED)("%s is a real route gated by %s", (path, flag) => {
  const { routes } = require("./routes");
  const FlagRoute = require("./FlagRoute").default;
  const matches = matchRoutes(routes, path);
  expect(matches && matches.length).toBe(2);
  const route: any = matches![1].route;
  expect(route.path).not.toBe("*");
  const gate = route.element.props.children; // <Suspense><FlagRoute …><Page/></FlagRoute></Suspense>
  expect(gate.type).toBe(FlagRoute);
  expect(gate.props.flag).toBe(flag);
});

it("City and Genders win over /community/:userId", () => {
  const { routes } = require("./routes");
  expect(matchRoutes(routes, "/community/city")![1].route.path).toBe("community/city");
  expect(matchRoutes(routes, "/community/abc123")![1].route.path).toBe("community/:userId");
});

it("still imports without a DOM", () => {
  expect(typeof window).toBe("undefined");
});
