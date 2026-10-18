import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import fs from "fs";
import path from "path";
import RouteError from "./RouteError";

// No react-i18next mock here on purpose: RouteError carries its own
// I18nextProvider (it replaces <App />, so nothing above it does), and that is
// exactly the part worth exercising.

it("shows the chunk-failure copy and a reload button", () => {
  render(<RouteError />);
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
    "Something went wrong loading this page"
  );
  expect(screen.getByRole("alert")).toBeInTheDocument();
  expect(screen.getByRole("button", { name: "Reload" })).toBeInTheDocument();
});

// The whole point of the element is that it renders where the app could not,
// so it must not need anything the app needed. renderToString is the same call
// scripts/prerender.js makes: if RouteError read window during render, this
// throws.
it("renders without a DOM, so it is safe on a prerendered page", () => {
  const html = renderToString(<RouteError />);
  expect(html).toContain("Something went wrong loading this page");
  expect(html).toContain('data-testid="route-error"');
});

it("reloads the document when the button is clicked", () => {
  const original = window.location;
  const reload = jest.fn();
  delete (window as any).location;
  (window as any).location = { ...original, reload };
  try {
    render(<RouteError />);
    fireEvent.click(screen.getByRole("button", { name: "Reload" }));
    expect(reload).toHaveBeenCalledTimes(1);
  } finally {
    delete (window as any).location;
    (window as any).location = original;
  }
});

it("every locale carries the errors.chunk strings the page falls back from", () => {
  const dir = path.join(__dirname, "../../utils/locales");
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".json"))) {
    const chunk = JSON.parse(fs.readFileSync(path.join(dir, file), "utf8")).errors.chunk;
    expect({ file, title: typeof chunk.title, body: typeof chunk.body, reload: typeof chunk.reload })
      .toEqual({ file, title: "string", body: "string", reload: "string" });
  }
});
