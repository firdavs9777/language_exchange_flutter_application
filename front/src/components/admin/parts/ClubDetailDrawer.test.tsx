import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import ClubDetailDrawer from "./ClubDetailDrawer";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockArchive = jest.fn();

jest.mock("../../../store/slices/adminSlice", () => ({
  useArchiveAdminClubMutation: () => mockArchive(),
}));

const CLUB = {
  _id: "c1",
  name: "Seoul Speakers",
  description: "Weekly Korean practice by the river.",
  owner: { _id: "u9", name: "Mina", username: "mina", images: ["https://cdn/u9.jpg"] },
  city: "Seoul",
  place: { name: "Hangang Park" },
  language: "ko",
  languageLabel: "Korean",
  memberCount: 42,
  status: "active",
  openReports: 2,
  createdAt: "2026-09-01T00:00:00.000Z",
};

let trigger: jest.Mock;
let onClose: jest.Mock;

const renderDrawer = (club: any = CLUB) => {
  onClose = jest.fn();
  return render(
    <MemoryRouter>
      <ClubDetailDrawer club={club} onClose={onClose} />
    </MemoryRouter>
  );
};

beforeEach(() => {
  trigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
  mockArchive.mockReset().mockReturnValue([trigger, { isLoading: false, reset: jest.fn() }]);
});

it("shows the description, owner, place, language, members, created and reports", () => {
  renderDrawer();
  expect(screen.getByTestId("club-detail-drawer")).toBeInTheDocument();
  expect(screen.getByText("Weekly Korean practice by the river.")).toBeInTheDocument();
  expect(screen.getByRole("link", { name: /Mina/ })).toHaveAttribute("href", "/profile/u9");
  expect(screen.getByTestId("club-place")).toHaveTextContent("Seoul");
  expect(screen.getByTestId("club-place")).toHaveTextContent("Hangang Park");
  expect(screen.getByTestId("club-members")).toHaveTextContent("42");
  expect(screen.getByTestId("club-open-reports")).toHaveTextContent("2");
  expect(screen.getByTestId("club-language")).toHaveTextContent("Korean");
});

it("archives an active club through the confirm dialog", async () => {
  renderDrawer();
  fireEvent.click(screen.getByTestId("club-archive"));
  expect(screen.getByTestId("confirm-dialog-confirm")).toBeDisabled();
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "spam" } });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(trigger).toHaveBeenCalledWith({ id: "c1", archived: true, reason: "spam" });
  await waitFor(() => expect(onClose).toHaveBeenCalled());
});

it("restores an archived club", async () => {
  renderDrawer({ ...CLUB, status: "archived" });
  fireEvent.click(screen.getByTestId("club-restore"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "appeal upheld" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(trigger).toHaveBeenCalledWith({
    id: "c1",
    archived: false,
    reason: "appeal upheld",
  });
  await waitFor(() => expect(onClose).toHaveBeenCalled());
});

it("keeps the dialog open and shows the error when the mutation fails", async () => {
  trigger = jest.fn(() => ({ unwrap: () => Promise.reject({ data: { message: "Nope" } }) }));
  mockArchive.mockReturnValue([
    trigger,
    { isLoading: false, error: { data: { message: "Nope" } }, reset: jest.fn() },
  ]);
  renderDrawer();
  fireEvent.click(screen.getByTestId("club-archive"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "spam" } });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() =>
    expect(screen.getByTestId("confirm-dialog-error")).toHaveTextContent("Nope")
  );
  expect(onClose).not.toHaveBeenCalled();
});

it("closes on the close button and the backdrop", () => {
  renderDrawer();
  fireEvent.click(screen.getByTestId("drawer-close"));
  expect(onClose).toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("drawer-backdrop"));
  expect(onClose).toHaveBeenCalledTimes(2);
});

it("renders a club with no owner, city or place", () => {
  renderDrawer({ ...CLUB, owner: null, city: null, place: null });
  expect(screen.queryByRole("link", { name: /Mina/ })).not.toBeInTheDocument();
  expect(screen.getByTestId("club-place")).toHaveTextContent("—");
});
