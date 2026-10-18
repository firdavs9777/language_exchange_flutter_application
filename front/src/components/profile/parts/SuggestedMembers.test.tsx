import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import SuggestedMembers from "./SuggestedMembers";

const mockGetMembers = jest.fn();
const mockNavigate = jest.fn();
const mockSendWave = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../../store/slices/communitySlice", () => ({
  useGetCommunityMembersQuery: (arg: any, opts: any) => mockGetMembers(arg, opts),
  useSendWaveMutation: () => [mockSendWave, { isLoading: false }],
}));

const member = (id: string) => ({
  _id: id,
  name: `User ${id}`,
  native_language: "English",
  language_to_learn: "Korean",
  imageUrls: [],
});

beforeEach(() => {
  mockGetMembers.mockReturnValue({ data: undefined });
});

afterEach(() => {
  jest.clearAllMocks();
});

function renderStrip(props: any = {}) {
  return render(
    <MemoryRouter>
      <SuggestedMembers
        targetUserId="u2"
        viewerId="me"
        language="English"
        name="Ada Lovelace"
        {...props}
      />
    </MemoryRouter>
  );
}

// `language=` is not a parameter of GET /auth/users; the server ignored it
// and the strip showed the viewer's default list. `nativeLanguage` without
// matchLanguage is the server's direct branch: native speakers of it.
it("asks for one page of native speakers of the profile's language", () => {
  renderStrip();
  expect(mockGetMembers.mock.calls[0][0]).toEqual({ page: 1, limit: 12, nativeLanguage: "English" });
  expect(mockGetMembers.mock.calls[0][0].matchLanguage).toBeUndefined();
  expect(mockGetMembers.mock.calls[0][1].skip).toBe(false);
});

it("does not ask at all when the profile has no language", () => {
  renderStrip({ language: undefined });
  expect(mockGetMembers.mock.calls[0][1].skip).toBe(true);
});

// GET /auth/users is protected and /community/:userId is public, so an
// anonymous visitor must never reach it.
it("asks nothing and renders nothing for a signed-out visitor", () => {
  mockGetMembers.mockReturnValue({ data: { data: [member("u3")] } });
  renderStrip({ viewerId: undefined });
  expect(mockGetMembers.mock.calls[0][1].skip).toBe(true);
  expect(screen.queryByTestId("suggested-members")).not.toBeInTheDocument();
});

it("leaves out the profile itself and the viewer", () => {
  mockGetMembers.mockReturnValue({
    data: { data: [member("u2"), member("me"), member("u3")] },
  });
  renderStrip();
  expect(screen.getAllByTestId("suggested-member")).toHaveLength(1);
  expect(screen.getByTestId("member-card-name")).toHaveTextContent("User u3");
});

it("shows at most four, however many the page returns", () => {
  mockGetMembers.mockReturnValue({
    data: { data: Array.from({ length: 12 }).map((unused, i) => member(`u${i + 10}`)) },
  });
  renderStrip();
  expect(screen.getAllByTestId("suggested-member")).toHaveLength(4);
});

it("renders nothing when nothing is left to suggest", () => {
  mockGetMembers.mockReturnValue({ data: { data: [member("u2")] } });
  renderStrip();
  expect(screen.queryByTestId("suggested-members")).not.toBeInTheDocument();
});

it("opens a suggestion on the member page", () => {
  mockGetMembers.mockReturnValue({ data: { data: [member("u3")] } });
  renderStrip();
  fireEvent.click(screen.getByTestId("member-card-root"));
  expect(mockNavigate).toHaveBeenCalledWith("/community/u3");
});

it("waves from the card without leaving the profile", () => {
  mockGetMembers.mockReturnValue({ data: { data: [member("u3")] } });
  renderStrip();
  fireEvent.click(screen.getByTestId("member-card-wave"));
  expect(mockNavigate).not.toHaveBeenCalled();
  expect(screen.getByTestId("wave-sheet")).toBeInTheDocument();
});

// Piece A rebuilt MemberCard as a photo-on-top grid cell. This strip is a
// horizontal carousel, not a grid, so it took a ~104px row to something four
// times taller. It asks for the row shape back.
it("asks for the compact card, not the grid cell", () => {
  mockGetMembers.mockReturnValue({ data: { data: [member("u3"), member("u4")] } });
  renderStrip();

  expect(screen.getAllByTestId("suggested-member").length).toBe(2);
  expect(screen.queryByTestId("member-card-photo")).not.toBeInTheDocument();
  expect(screen.getAllByTestId("member-card-avatar").length).toBeGreaterThan(0);
});

it("shows four suggestions, not a second community page", () => {
  mockGetMembers.mockReturnValue({
    data: { data: [member("u3"), member("u4"), member("u5"), member("u6"), member("u7"), member("u8")] },
  });
  renderStrip();

  expect(screen.getAllByTestId("suggested-member")).toHaveLength(4);
  // The way to more is the link, not a longer list.
  expect(screen.getByText(/see all members/i)).toBeInTheDocument();
});
