import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import ClubOwnerActions from "./ClubOwnerActions";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: (m: any) => mockError(m) } }));
const mockDelete = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useDeleteClubMutation: () => [mockDelete, { isLoading: false }],
}));

const club: any = { _id: "c1", name: "Seoul readers", memberCount: 5, upcoming: 2, viewerIsOwner: true };
function renderActions(c: any = club) {
  return render(
    <MemoryRouter initialEntries={["/clubs/c1"]}>
      <Routes>
        <Route path="/clubs/:id" element={<ClubOwnerActions club={c} />} />
        <Route path="/gatherings" element={<div data-testid="list-page" />} />
      </Routes>
    </MemoryRouter>
  );
}

beforeEach(() => {
  mockDelete.mockReset();
  mockError.mockReset();
});

it("deletes after a confirmation that says the gatherings stay", async () => {
  mockDelete.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  renderActions();
  fireEvent.click(screen.getByTestId("club-delete"));
  expect(screen.getByTestId("confirm-dialog")).toHaveTextContent("Gatherings already planned will still happen");
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockDelete).toHaveBeenCalledWith("c1"));
  await waitFor(() => expect(screen.getByTestId("list-page")).toBeInTheDocument());
});

it("renders nothing for anyone but the owner", () => {
  const { container } = renderActions({ ...club, viewerIsOwner: false });
  expect(container).toBeEmptyDOMElement();
});
