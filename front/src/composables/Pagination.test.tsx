import "@testing-library/jest-dom";
import React from "react";
import { renderToString } from "react-dom/server";
import { render, screen } from "@testing-library/react";
import Pagination from "./Pagination";

const props = {
  currentPage: 1,
  totalPages: 5,
  onPageChange: () => {},
  hasNextPage: true,
  hasPrevPage: false,
  totalMoments: 47,
};

describe("Pagination and the prerender", () => {
  const original = Object.getOwnPropertyDescriptor(window, "innerWidth");
  afterEach(() => {
    if (original) Object.defineProperty(window, "innerWidth", original);
  });

  it("never reads the viewport while rendering markup (window does not exist in the prerender)", () => {
    const read = jest.fn(() => 1200);
    Object.defineProperty(window, "innerWidth", { configurable: true, get: read });
    renderToString(<Pagination {...props} />);
    expect(read).not.toHaveBeenCalled();
  });

  it("the server markup is the same whatever the viewport, so a phone hydrates it cleanly", () => {
    Object.defineProperty(window, "innerWidth", { configurable: true, get: () => 375 });
    const phone = renderToString(<Pagination {...props} />);
    Object.defineProperty(window, "innerWidth", { configurable: true, get: () => 1440 });
    const desktop = renderToString(<Pagination {...props} />);
    expect(phone).toBe(desktop);
  });

  it("after hydration a wide screen shows more page numbers", () => {
    Object.defineProperty(window, "innerWidth", { configurable: true, get: () => 1440 });
    render(<Pagination {...props} />);
    expect(screen.getByRole("button", { name: "3" })).toBeInTheDocument();
  });
});
