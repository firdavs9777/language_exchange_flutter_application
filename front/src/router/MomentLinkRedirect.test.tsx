import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import MomentLinkRedirect from "./MomentLinkRedirect";

const Where = () => <div data-testid="where">{useLocation().pathname}</div>;

it("redirects /moments/:id to /moment/:id, replacing the history entry", () => {
  render(
    <MemoryRouter initialEntries={["/", "/moments/abc123"]} initialIndex={1}>
      <Routes>
        <Route path="moments/:id" element={<MomentLinkRedirect />} />
        <Route path="moment/:id" element={<Where />} />
      </Routes>
    </MemoryRouter>
  );
  expect(screen.getByTestId("where")).toHaveTextContent("/moment/abc123");
});
