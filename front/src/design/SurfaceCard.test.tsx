import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import SurfaceCard from "./SurfaceCard";

it("renders its children", () => {
  render(<SurfaceCard>hello</SurfaceCard>);
  expect(screen.getByTestId("surface-card")).toHaveTextContent("hello");
});

it("carries the app's card radius and elevation", () => {
  render(<SurfaceCard>x</SurfaceCard>);
  const el = screen.getByTestId("surface-card");
  expect(el.className).toContain("rounded-card");
  expect(el.className).toContain("shadow-card");
  expect(el.className).toContain("bg-surface");
});

// A shadow on a dark surface reads as grime; the app drops it outright.
it("drops the shadow in dark mode", () => {
  render(<SurfaceCard>x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).toContain("dark:shadow-none");
});

it("applies the requested padding", () => {
  const { rerender } = render(<SurfaceCard padding="sm">x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).toContain("p-2.5");

  rerender(<SurfaceCard padding="lg">x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).toContain("p-5");
});

it("adds hover and press affordances only when interactive", () => {
  const { rerender } = render(<SurfaceCard>x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).not.toContain("cursor-pointer");

  rerender(<SurfaceCard interactive>x</SurfaceCard>);
  const el = screen.getByTestId("surface-card");
  expect(el.className).toContain("cursor-pointer");
  expect(el.className).toContain("hover:shadow-raised");
});

it("calls onClick when clicked", () => {
  const onClick = jest.fn();
  render(
    <SurfaceCard interactive onClick={onClick}>
      x
    </SurfaceCard>
  );
  fireEvent.click(screen.getByTestId("surface-card"));
  expect(onClick).toHaveBeenCalledTimes(1);
});

it("merges an extra className", () => {
  render(<SurfaceCard className="mb-2">x</SurfaceCard>);
  expect(screen.getByTestId("surface-card").className).toContain("mb-2");
});

it("exposes button semantics and focusability only when interactive", () => {
  const { rerender } = render(<SurfaceCard>x</SurfaceCard>);
  let el = screen.getByTestId("surface-card");
  expect(el).not.toHaveAttribute("role");
  expect(el).not.toHaveAttribute("tabIndex");

  rerender(<SurfaceCard interactive>x</SurfaceCard>);
  el = screen.getByTestId("surface-card");
  expect(el).toHaveAttribute("role", "button");
  expect(el).toHaveAttribute("tabindex", "0");
});

it("fires onClick on Enter when interactive", () => {
  const onClick = jest.fn();
  render(
    <SurfaceCard interactive onClick={onClick}>
      x
    </SurfaceCard>
  );
  fireEvent.keyDown(screen.getByTestId("surface-card"), { key: "Enter" });
  expect(onClick).toHaveBeenCalledTimes(1);
});

it("fires onClick on Space when interactive, and prevents the page scroll", () => {
  const onClick = jest.fn();
  render(
    <SurfaceCard interactive onClick={onClick}>
      x
    </SurfaceCard>
  );
  const spaceEvent = new KeyboardEvent("keydown", { key: " ", bubbles: true, cancelable: true });
  const preventDefaultSpy = jest.spyOn(spaceEvent, "preventDefault");
  screen.getByTestId("surface-card").dispatchEvent(spaceEvent);
  expect(onClick).toHaveBeenCalledTimes(1);
  expect(preventDefaultSpy).toHaveBeenCalled();
});

it("does not attach a key handler when not interactive", () => {
  const onClick = jest.fn();
  render(<SurfaceCard onClick={onClick}>x</SurfaceCard>);
  fireEvent.keyDown(screen.getByTestId("surface-card"), { key: "Enter" });
  expect(onClick).not.toHaveBeenCalled();
});
