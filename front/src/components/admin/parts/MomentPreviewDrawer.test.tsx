import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import MomentPreviewDrawer from "./MomentPreviewDrawer";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockSetHidden = jest.fn();

jest.mock("../../../store/slices/adminSlice", () => ({
  useSetMomentHiddenMutation: () => mockSetHidden(),
}));

const MOMENT = {
  id: "m1",
  title: "Seoul sunset",
  description: "Walked the river at golden hour and practised ordering coffee.",
  imageUrl: "https://cdn.example.com/m1.jpg",
  language: "ko",
  category: "daily",
  user: { id: "u1", name: "Mina", image: "https://cdn.example.com/u1.jpg" },
  likeCount: 12,
  commentCount: 3,
  viewCount: 480,
  shareCount: 1,
  openReports: 2,
  isDeleted: false,
  createdAt: "2026-09-20T10:00:00.000Z",
};

let trigger: jest.Mock;
let onClose: jest.Mock;

const renderDrawer = (moment: any = MOMENT) => {
  onClose = jest.fn();
  return render(
    <MemoryRouter>
      <MomentPreviewDrawer moment={moment} onClose={onClose} />
    </MemoryRouter>
  );
};

beforeEach(() => {
  trigger = jest.fn(() => ({ unwrap: () => Promise.resolve({}) }));
  mockSetHidden.mockReset().mockReturnValue([trigger, { isLoading: false, reset: jest.fn() }]);
});

it("shows the image, the full text and the author", () => {
  renderDrawer();
  expect(screen.getByTestId("moment-preview-drawer")).toBeInTheDocument();
  expect(screen.getByAltText("Seoul sunset")).toHaveAttribute(
    "src",
    "https://cdn.example.com/m1.jpg"
  );
  expect(
    screen.getByText("Walked the river at golden hour and practised ordering coffee.")
  ).toBeInTheDocument();
  const author = screen.getByRole("link", { name: /Mina/ });
  expect(author).toHaveAttribute("href", "/profile/u1");
});

it("shows the counts and the open report total", () => {
  renderDrawer();
  const counts = screen.getByTestId("moment-counts");
  expect(counts).toHaveTextContent("12");
  expect(counts).toHaveTextContent("3");
  expect(counts).toHaveTextContent("480");
  expect(screen.getByTestId("moment-open-reports")).toHaveTextContent("2");
});

it("hides a visible moment through the confirm dialog with a reason", async () => {
  renderDrawer();
  fireEvent.click(screen.getByTestId("moment-hide"));
  expect(screen.getByTestId("confirm-dialog-confirm")).toBeDisabled();
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "nudity" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(trigger).toHaveBeenCalledWith({ id: "m1", hidden: true, reason: "nudity" });
  await waitFor(() => expect(onClose).toHaveBeenCalled());
});

it("unhides a hidden moment and shows the hidden badge", async () => {
  renderDrawer({ ...MOMENT, isDeleted: true });
  expect(screen.getByTestId("moment-hidden-badge")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("moment-unhide"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "appeal upheld" },
  });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(trigger).toHaveBeenCalledWith({
    id: "m1",
    hidden: false,
    reason: "appeal upheld",
  });
  await waitFor(() => expect(onClose).toHaveBeenCalled());
});

it("keeps the dialog open and shows the error when the mutation fails", async () => {
  trigger = jest.fn(() => ({
    unwrap: () => Promise.reject({ data: { message: "Moment not found" } }),
  }));
  mockSetHidden.mockReturnValue([
    trigger,
    { isLoading: false, error: { data: { message: "Moment not found" } }, reset: jest.fn() },
  ]);
  renderDrawer();
  fireEvent.click(screen.getByTestId("moment-hide"));
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "spam" } });
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  await waitFor(() =>
    expect(screen.getByTestId("confirm-dialog-error")).toHaveTextContent("Moment not found")
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

it("renders without an image or an author", () => {
  renderDrawer({ ...MOMENT, imageUrl: null, user: null });
  expect(screen.queryByAltText("Seoul sunset")).not.toBeInTheDocument();
  expect(screen.queryByRole("link", { name: /Mina/ })).not.toBeInTheDocument();
  expect(screen.getByTestId("moment-preview-drawer")).toBeInTheDocument();
});
