import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import ClubPeople from "./ClubPeople";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockError = jest.fn();
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: (m: any) => mockError(m) } }));
const mockRemove = jest.fn();
const mockRole = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useRemoveClubMemberMutation: () => [mockRemove, { isLoading: false }],
  useSetClubMemberRoleMutation: () => [mockRole, { isLoading: false }],
}));

const members = [
  { _id: "own", name: "Olga", username: "olga", images: [], role: "owner" },
  { _id: "org", name: "Omar", username: "omar", images: [], role: "organizer" },
  { _id: "mem", name: "Mina", username: "mina", images: [], role: "member" },
];
const club = (extra: any = {}) => ({
  _id: "c1",
  name: "Seoul readers",
  language: "korean",
  memberCount: 3,
  members,
  roleCounts: { owner: 1, organizer: 1, member: 1 },
  viewerCanManage: false,
  viewerIsMember: true,
  viewerIsOwner: false,
  owner: { _id: "own" },
  ...extra,
});
function renderPeople(c: any, me = "mem") {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: me } } }) => s } });
  return render(
    <Provider store={store}>
      <ClubPeople club={c} />
    </Provider>
  );
}

beforeEach(() => {
  [mockRemove, mockRole, mockError].forEach((m) => m.mockReset());
  mockRemove.mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockRole.mockReturnValue({ unwrap: () => Promise.resolve({ data: { userId: "mem", role: "organizer" } }) });
});

it("shows owner first, organizers, then members, with role labels", () => {
  renderPeople(club());
  const rows = screen.getAllByTestId(/^club-member-(own|org|mem)$/);
  expect(rows.map((r) => r.getAttribute("data-testid"))).toEqual(["club-member-own", "club-member-org", "club-member-mem"]);
  expect(screen.getByTestId("club-member-role-own")).toHaveTextContent("Owner");
  expect(screen.getByTestId("club-member-role-org")).toHaveTextContent("Organizer");
});

it("offers no management to a plain member", () => {
  renderPeople(club());
  expect(screen.queryByTestId("club-member-menu-mem")).not.toBeInTheDocument();
});

it("the owner can promote, demote and remove, but never touch themselves", async () => {
  renderPeople(club({ viewerCanManage: true, viewerIsOwner: true }), "own");
  expect(screen.queryByTestId("club-member-menu-own")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("club-member-menu-mem"));
  fireEvent.click(screen.getByTestId("club-make-organizer-mem"));
  await waitFor(() => expect(mockRole).toHaveBeenCalledWith({ id: "c1", userId: "mem", role: "organizer" }));
  fireEvent.click(screen.getByTestId("club-member-menu-org"));
  fireEvent.click(screen.getByTestId("club-make-member-org"));
  await waitFor(() => expect(mockRole).toHaveBeenCalledWith({ id: "c1", userId: "org", role: "member" }));
  fireEvent.click(screen.getByTestId("club-member-menu-mem"));
  fireEvent.click(screen.getByTestId("club-remove-mem"));
  fireEvent.click(screen.getByTestId("confirm-ok"));
  await waitFor(() => expect(mockRemove).toHaveBeenCalledWith({ id: "c1", userId: "mem" }));
});

it("an organizer can remove members but not organizers, and cannot change roles", () => {
  renderPeople(club({ viewerCanManage: true }), "org");
  expect(screen.queryByTestId("club-member-menu-org")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("club-member-menu-mem"));
  expect(screen.getByTestId("club-remove-mem")).toBeInTheDocument();
  expect(screen.queryByTestId("club-make-organizer-mem")).not.toBeInTheDocument();
});

it("says so when a role change is refused", async () => {
  mockRole.mockReturnValue({ unwrap: () => Promise.reject({ status: 403, data: { error: "Only the club owner can change roles" } }) });
  renderPeople(club({ viewerCanManage: true, viewerIsOwner: true }), "own");
  fireEvent.click(screen.getByTestId("club-member-menu-mem"));
  fireEvent.click(screen.getByTestId("club-make-organizer-mem"));
  await waitFor(() => expect(mockError).toHaveBeenCalledWith("Something went wrong. Try again."));
});
