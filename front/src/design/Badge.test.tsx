import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import Badge from "./Badge";

it("renders its label", () => {
  render(<Badge>VIP</Badge>);
  expect(screen.getByTestId("badge")).toHaveTextContent("VIP");
});

it("defaults to the brand tone", () => {
  render(<Badge>New</Badge>);
  const el = screen.getByTestId("badge");
  expect(el.className).toContain("bg-brand/[0.12]");
  expect(el.className).toContain("text-brand-dark");
});

it("renders the banana tone when asked", () => {
  render(<Badge tone="banana">VIP</Badge>);
  const el = screen.getByTestId("badge");
  expect(el.className).toContain("bg-banana/[0.28]");
  expect(el.className).toContain("text-banana-dark");
});

// Tailwind v3 emits NO background rule for an opacity step missing from
// theme.opacity, and does not fail the build. Arbitrary modifiers always.
it("uses arbitrary opacity modifiers, never bare steps", () => {
  const { rerender } = render(<Badge>New</Badge>);
  expect(screen.getByTestId("badge").className).not.toMatch(/bg-brand\/\d+(\s|$)/);

  rerender(<Badge tone="banana">VIP</Badge>);
  expect(screen.getByTestId("badge").className).not.toMatch(/bg-banana\/\d+(\s|$)/);
});

it("ships a dark-mode text variant for both tones", () => {
  const { rerender } = render(<Badge>New</Badge>);
  expect(screen.getByTestId("badge").className).toContain("dark:text-brand-light");

  rerender(<Badge tone="banana">VIP</Badge>);
  expect(screen.getByTestId("badge").className).toContain("dark:text-banana-light");
});
