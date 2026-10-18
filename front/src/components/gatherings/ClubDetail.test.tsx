import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import ClubDetail from "./ClubDetail";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: (m: any) => mockError(m) } }));
let mockQuery: any;
const mockJoin = jest.fn();
const mockLeave = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useGetClubQuery: () => mockQuery,
  useJoinClubMutation: () => [mockJoin, { isLoading: false }],
  useLeaveClubMutation: () => [mockLeave, { isLoading: false }],
}));
jest.mock("./ClubPeople", () => () => <div data-testid="club-people" />);
jest.mock("./GatheringSafetyMenu", () => () => <div data-testid="safety-menu" />);
jest.mock("./GatheringCard", () => (p: any) => <div data-testid={`gathering-card-${p.gathering._id}`} />);
jest.mock("./ClubOwnerActions", () => () => <div data-testid="club-owner-actions" />);
jest.mock("./CoverEditor", () => () => <div data-testid="cover-editor" />);

const club = (extra: any = {}) => ({
  _id: "c1",
  name: "Seoul readers",
  description: "Books in Korean",
  language: "korean",
  languageLabel: "Korean",
  interest: "books",
  city: "Seoul",
  place: { name: "Cafe Ink", address: null },
  memberCount: 12,
  members: [],
  roleCounts: { owner: 1, organizer: 0, member: 11 },
  viewerCanManage: false,
  viewerIsMember: false,
  viewerIsOwner: false,
  owner: { _id: "own", name: "Olga" },
  upcoming: 1,
  pastCount: 11,
  gatherings: [{ _id: "g1" }],
  ...extra,
});
const ok = (data: any) => ({ data, isLoading: false, isError: false });
function renderClub() {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/clubs/c1"]}>
        <Routes>
          <Route path="/clubs/:id" element={<ClubDetail />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  [mockJoin, mockLeave, mockError].forEach((m) => m.mockReset());
  mockJoin.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockLeave.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockQuery = ok(club());
});

it("shows the club, where it meets, its history and its upcoming gatherings", () => {
  renderClub();
  const page = screen.getByTestId("club-detail");
  expect(page).toHaveTextContent("Seoul readers");
  expect(page).toHaveTextContent("Cafe Ink");
  expect(page).toHaveTextContent("Seoul");
  expect(page).toHaveTextContent("Met 11 times");
  expect(screen.getByTestId("gathering-card-g1")).toBeInTheDocument();
  expect(screen.getByTestId("club-people")).toBeInTheDocument();
});

it("joins in one tap; a non-member cannot host for the club", async () => {
  renderClub();
  expect(screen.queryByTestId("club-host-gathering-link")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("club-join"));
  await waitFor(() => expect(mockJoin).toHaveBeenCalledWith("c1"));
});

it("a member can leave (after confirming) and host a gathering for the club", async () => {
  mockQuery = ok(club({ viewerIsMember: true }));
  renderClub();
  expect(screen.getByTestId("club-host-gathering-link")).toHaveAttribute("href", "/gatherings/new?club=c1");
  fireEvent.click(screen.getByTestId("club-leave"));
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockLeave).toHaveBeenCalledWith("c1"));
});

it("the owner sees no Leave, a note instead, and the owner actions", () => {
  mockQuery = ok(club({ viewerIsMember: true, viewerIsOwner: true, viewerCanManage: true }));
  renderClub();
  expect(screen.queryByTestId("club-leave")).not.toBeInTheDocument();
  expect(screen.getByTestId("club-owner-note")).toBeInTheDocument();
  expect(screen.getByTestId("club-edit-link")).toHaveAttribute("href", "/clubs/c1/edit");
  expect(screen.getByTestId("club-owner-actions")).toBeInTheDocument();
});

it("an empty club says nothing is planned yet", () => {
  mockQuery = ok(club({ gatherings: [], upcoming: 0, pastCount: 0 }));
  renderClub();
  expect(screen.getByTestId("club-no-gatherings")).toBeInTheDocument();
});

it("a missing, deleted or blocked club is 'not available'", () => {
  mockQuery = { data: undefined, isLoading: false, isError: true };
  renderClub();
  expect(screen.getByTestId("club-unavailable")).toHaveTextContent("This club isn't available.");
});
