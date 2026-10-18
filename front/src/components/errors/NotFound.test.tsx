import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import { HelmetProvider } from "react-helmet-async";
import { MemoryRouter } from "react-router-dom";
import NotFound from "./NotFound";

// Under Jest's jsdom environment, react-helmet-async returns a null server
// context unless canUseDOM is forced false, which is what lets us read
// ctx.helmet after renderToString below.
HelmetProvider.canUseDOM = false;

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const page = (
  <MemoryRouter>
    <NotFound />
  </MemoryRouter>
);

it("explains itself and offers the two ways back", () => {
  render(<HelmetProvider>{page}</HelmetProvider>);
  expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("This page doesn't exist");
  expect(screen.getByText("Go to the homepage")).toHaveAttribute("href", "/");
  expect(screen.getByText("Get the app")).toHaveAttribute("href", "/download");
});

it("is noindex with its own title", () => {
  const ctx: any = {};
  renderToString(<HelmetProvider context={ctx}>{page}</HelmetProvider>);
  expect(ctx.helmet.meta.toString()).toContain('content="noindex, nofollow"');
  expect(ctx.helmet.title.toString()).toContain("Page not found | BananaTalk");
});
