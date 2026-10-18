import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import LanguageRoomOwnerPanel from "./LanguageRoomOwnerPanel";

const mockDecide = jest.fn();
const mockRemove = jest.fn();
let mockRequests: any[] = [];
let mockMembers: any[] = [];
jest.mock("../../store/slices/languageRoomsSlice", () => {
  const actual = jest.requireActual("../../store/slices/languageRoomsSlice");
  return {
    languageRoomErrorText: actual.languageRoomErrorText,
    useGetLanguageRoomRequestsQuery: () => ({ data: { data: mockRequests } }),
    useGetLanguageRoomMembersQuery: () => ({ data: { data: mockMembers } }),
    useDecideLanguageRoomRequestMutation: () => [mockDecide],
    useRemoveLanguageRoomMemberMutation: () => [mockRemove],
  };
});
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

beforeEach(() => {
  mockDecide.mockReset().mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockRemove.mockReset().mockReturnValue({ unwrap: () => Promise.resolve({}) });
  mockRequests = [{ user: { _id: "u5", name: "Kim" }, requestedAt: "2026-10-16T10:00:00Z", status: "pending" }];
  mockMembers = [
    { _id: "me", name: "Me", role: "owner", imageUrls: [] },
    { _id: "u2", name: "Ana", role: "member", imageUrls: [] },
  ];
});

it("approves and denies join requests", async () => {
  render(<LanguageRoomOwnerPanel roomId="r1" />);
  expect(screen.getByTestId("lr-request-u5")).toHaveTextContent("Kim");
  fireEvent.click(screen.getByTestId("lr-approve-u5"));
  await waitFor(() => expect(mockDecide).toHaveBeenCalledWith({ roomId: "r1", userId: "u5", approve: true }));
  fireEvent.click(screen.getByTestId("lr-deny-u5"));
  await waitFor(() => expect(mockDecide).toHaveBeenCalledWith({ roomId: "r1", userId: "u5", approve: false }));
});

it("removes a member after a confirmation; never offers it for the owner", async () => {
  render(<LanguageRoomOwnerPanel roomId="r1" />);
  expect(screen.queryByTestId("lr-remove-me")).not.toBeInTheDocument();
  fireEvent.click(screen.getByTestId("lr-remove-u2"));
  expect(mockRemove).not.toHaveBeenCalled();
  fireEvent.click(screen.getByTestId("lr-remove-confirm-u2"));
  await waitFor(() => expect(mockRemove).toHaveBeenCalledWith({ roomId: "r1", userId: "u2" }));
});

it("shows a refusal", async () => {
  mockRemove.mockReturnValue({ unwrap: () => Promise.reject({ status: 400, data: { code: "CANNOT_KICK_OWNER" } }) });
  render(<LanguageRoomOwnerPanel roomId="r1" />);
  fireEvent.click(screen.getByTestId("lr-remove-u2"));
  fireEvent.click(screen.getByTestId("lr-remove-confirm-u2"));
  await waitFor(() => expect(screen.getByTestId("lr-owner-error")).toHaveTextContent("can't be removed"));
});
