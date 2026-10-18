import "@testing-library/jest-dom";
import pathMod from "path";
import fsMod from "fs";
import { render, screen, act } from "@testing-library/react";
import Reveal from "./Reveal";
import { useCountUp } from "./useCountUp";

const setReducedMotion = (reduce: boolean) => {
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    configurable: true,
    value: (query: string) => ({
      matches: reduce && query.includes("reduce"),
      media: query,
      addEventListener: () => {},
      removeEventListener: () => {},
      addListener: () => {},
      removeListener: () => {},
      dispatchEvent: () => false,
    }),
  });
};

beforeEach(() => setReducedMotion(false));

// The rule that matters most: content is in the DOM whether or not anything animated.
it("renders children immediately, with no observer present", () => {
  render(<Reveal><p>visible content</p></Reveal>);
  expect(screen.getByText("visible content")).toBeInTheDocument();
});

it("does not hide children behind an intersection that may never fire", () => {
  render(<Reveal><p>still here</p></Reveal>);
  expect(screen.getByTestId("reveal")).toContainElement(screen.getByText("still here"));
});

it("drops the transition entirely under reduced motion", () => {
  setReducedMotion(true);
  render(<Reveal><p>x</p></Reveal>);
  expect(screen.getByTestId("reveal").className).not.toContain("duration-");
});

function CountProbe({ to }: { to: number }) {
  const n = useCountUp(to, { durationMs: 100, start: true });
  return <span data-testid="count">{n}</span>;
}

it("counts up to the target and stops there", () => {
  jest.useFakeTimers();
  render(<CountProbe to={137} />);
  act(() => { jest.advanceTimersByTime(200); });
  expect(screen.getByTestId("count")).toHaveTextContent("137");
  jest.useRealTimers();
});

it("returns the target immediately under reduced motion", () => {
  setReducedMotion(true);
  render(<CountProbe to={137} />);
  expect(screen.getByTestId("count")).toHaveTextContent("137");
});

// ---------------------------------------------------------------------------
// Motion tokens. Every homepage animation is CSS-only and lives in
// tailwind.config.js, never inline in a component: the page is prerendered
// with renderToString, so an animation that needed JS state would either
// change the server markup or desync at hydration.
//
// require() with an absolute path rather than a relative import: CRA's
// ModuleScopePlugin forbids importing from outside src/ (Jest does not, but
// keeping it a runtime require sidesteps the rule) -- same reasoning as
// src/design/tokens.test.ts.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const twConfig = require(pathMod.resolve(__dirname, "../../../../tailwind.config.js"));
const extend = twConfig.theme.extend;

const HOMEPAGE_ANIMATIONS = [
  "bt-type-dots",
  "bt-msg-in",
  "bt-line-in",
  "bt-drift",
  "bt-gradient",
];

it("defines a keyframe for every homepage animation", () => {
  HOMEPAGE_ANIMATIONS.forEach((name) => {
    expect(extend.keyframes[name]).toBeDefined();
  });
});

it("defines a matching animation utility for every homepage keyframe", () => {
  HOMEPAGE_ANIMATIONS.forEach((name) => {
    expect(typeof extend.animation[name]).toBe("string");
    expect(extend.animation[name]).toContain(name);
  });
});

// These are ambient loops, not entrances: a one-shot animation would leave
// the hero dead after the first 14 seconds.
it("loops every homepage animation", () => {
  HOMEPAGE_ANIMATIONS.forEach((name) => {
    expect(extend.animation[name]).toContain("infinite");
  });
});

// Arbitrary `animate-[...]` values would put keyframes back in the markup,
// out of reach of the token file and of these tests.
it("keeps arbitrary animation values out of the homepage", () => {
  const walk = (dir: string): string[] =>
    fsMod.readdirSync(dir, { withFileTypes: true }).reduce((acc: string[], e: any) => {
      const full = pathMod.join(dir, e.name);
      return acc.concat(e.isDirectory() ? walk(full) : [full]);
    }, []);
  const offenders = walk(pathMod.resolve(__dirname, ".."))
    // Source only: this file names the offending string in order to test for
    // it, and would otherwise report itself.
    .filter((f) => /\.(tsx?|jsx?)$/.test(f) && f.indexOf(".test.") === -1)
    .filter((f) => fsMod.readFileSync(f, "utf8").indexOf("animate-[") !== -1);
  expect(offenders).toEqual([]);
});
