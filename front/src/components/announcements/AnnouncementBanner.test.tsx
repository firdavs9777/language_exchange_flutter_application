import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import AnnouncementBanner from "./AnnouncementBanner";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));
jest.mock("react-redux", () => ({ useSelector: (fn: any) => fn({ auth: { userInfo: null } }) }));

const A = { id: "b1", title: "Maintenance tonight", body: "2–3am KST, chats may be slow", emoji: "🛠️", imageUrl: null,
  buttonLabel: null, buttonUrl: null, priority: 0, displayStyle: "banner" as const };

test("renders a region with title, one-line body and close", () => {
  const onClose = jest.fn();
  render(<MemoryRouter><AnnouncementBanner announcement={A} onClose={onClose} /></MemoryRouter>);
  expect(screen.getByRole("region", { name: "Maintenance tonight" })).toBeInTheDocument();
  expect(screen.getByTestId("ann-banner-body")).toHaveClass("truncate");
  fireEvent.click(screen.getByRole("button", { name: "announcements.close" }));
  expect(onClose).toHaveBeenCalled();
});

test("no button when there is no label/url", () => {
  render(<MemoryRouter><AnnouncementBanner announcement={A} onClose={() => {}} /></MemoryRouter>);
  expect(screen.queryByTestId("ann-banner-cta")).toBeNull();
});
