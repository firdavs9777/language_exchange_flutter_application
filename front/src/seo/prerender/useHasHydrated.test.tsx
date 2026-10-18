import React from "react";
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import { useHasHydrated } from "./useHasHydrated";

/**
 * The contract: the SERVER pass and the FIRST client render must agree.
 *
 * This is asserted at the `renderToString` boundary rather than through a
 * component, because that is where the bug lived — a value that differs
 * between the two is exactly what React reports as a hydration mismatch, and
 * it is invisible in a normal client-only test.
 */
const Probe: React.FC = () => <span data-testid="v">{useHasHydrated() ? "after" : "before"}</span>;

it("is false during the server pass, where effects never run", () => {
  // The prerender writes this string into the static file, so it must be the
  // stable branch.
  expect(renderToString(<Probe />)).toContain("before");
  expect(renderToString(<Probe />)).not.toContain("after");
});

it("flips to true once mounted on the client", () => {
  render(<Probe />);
  expect(screen.getByTestId("v")).toHaveTextContent("after");
});

it("agrees with the server on the very first client render", () => {
  // If these two ever diverge, every prerendered page using the hook takes a
  // hydration mismatch and re-renders from scratch.
  let firstClientRender = "";
  const Capture: React.FC = () => {
    const v = useHasHydrated() ? "after" : "before";
    if (!firstClientRender) firstClientRender = v;
    return <span>{v}</span>;
  };
  render(<Capture />);
  expect(firstClientRender).toBe(renderToString(<Probe />).replace(/<[^>]*>/g, ""));
});
