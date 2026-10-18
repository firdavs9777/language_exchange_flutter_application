import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import ProfileMoments from "./ProfileMoments";

const mockUseGetMyMomentsQuery = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../../store/slices/momentsSlice", () => ({
  useGetMyMomentsQuery: (...args: any[]) => mockUseGetMyMomentsQuery(...args),
}));

function renderMoments(props: any = {}, query: any = { data: undefined }) {
  mockUseGetMyMomentsQuery.mockReturnValue(query);
  return render(
    <MemoryRouter>
      <ProfileMoments userId="u2" isOwn={false} {...props} />
    </MemoryRouter>
  );
}

const imageMoment = {
  _id: "m1",
  description: "Sunset in Busan",
  imageUrls: ["https://cdn.test/a.jpg"],
  likeCount: 4,
  commentCount: 2,
};

const textMoment = {
  _id: "m2",
  description: "Anyone up for a call tonight?",
  imageUrls: [],
  likeCount: 0,
  commentCount: [],
};

beforeEach(() => {
  mockUseGetMyMomentsQuery.mockReset();
});

it("renders one tile per moment, each linking to the moment", () => {
  renderMoments({}, { data: { data: [imageMoment, textMoment] } });
  expect(screen.getAllByTestId("moment-tile")).toHaveLength(2);
  expect(screen.getAllByTestId("moment-tile")[0]).toHaveAttribute("href", "/moment/m1");
  expect(screen.getAllByTestId("moment-tile")[1]).toHaveAttribute("href", "/moment/m2");
});

it("renders an image tile for a moment with a photo", () => {
  renderMoments({}, { data: { data: [imageMoment] } });
  const image = screen.getByTestId("moment-tile-image");
  expect(image).toHaveAttribute("src", "https://cdn.test/a.jpg");
  expect(image).toHaveAttribute("alt", "Sunset in Busan");
});

it("renders a text tile for a moment with no photo", () => {
  renderMoments({}, { data: { data: [textMoment] } });
  expect(screen.queryByTestId("moment-tile-image")).not.toBeInTheDocument();
  expect(screen.getByTestId("moment-tile-text")).toHaveTextContent(
    "Anyone up for a call tonight?"
  );
});

it("shows like and comment counts, including an array comment count", () => {
  renderMoments({}, { data: { data: [{ ...imageMoment, commentCount: [1, 2, 3] }] } });
  expect(screen.getByTestId("moment-likes")).toHaveTextContent("4");
  expect(screen.getByTestId("moment-comments")).toHaveTextContent("3");
});

it("draws the counts with icons, never emoji", () => {
  const { container } = renderMoments({}, { data: { data: [imageMoment] } });
  expect(container.querySelectorAll("svg").length).toBeGreaterThan(0);
  expect(container.textContent).not.toMatch(/[❤\u{1F49B}\u{1F4AC}]/u);
});

it("offers See all on an own profile", () => {
  renderMoments({ isOwn: true, userId: "me" }, { data: { data: [imageMoment] } });
  expect(screen.getByTestId("moments-see-all")).toHaveAttribute("href", "/my-moments");
});

it("offers no See all link on another person's profile", () => {
  renderMoments({}, { data: { data: [imageMoment] } });
  expect(screen.queryByTestId("moments-see-all")).not.toBeInTheDocument();
});

it("shows skeleton tiles while the moments load", () => {
  renderMoments({}, { data: undefined, isLoading: true });
  expect(screen.getAllByTestId("moment-skeleton").length).toBeGreaterThan(0);
  expect(screen.queryByTestId("moments-empty")).not.toBeInTheDocument();
});

it("shows the own empty state when the signed-in user has no moments", () => {
  renderMoments({ isOwn: true, userId: "me" }, { data: { data: [] } });
  expect(screen.getByTestId("moments-empty")).toHaveTextContent("Share your first moment");
});

it("shows the other-person empty state", () => {
  renderMoments({}, { data: { data: [] } });
  expect(screen.getByTestId("moments-empty")).toHaveTextContent("No moments yet");
});

it("skips the request until a user id is known", () => {
  renderMoments({ userId: undefined }, { data: undefined });
  expect(mockUseGetMyMomentsQuery).toHaveBeenCalledWith(
    { userId: "" },
    { skip: true }
  );
});

it("anchors the section so the stats tile can link to it", () => {
  renderMoments({}, { data: { data: [imageMoment] } });
  expect(screen.getByTestId("profile-moments")).toHaveAttribute("id", "moments");
});

describe("scheduled moments", () => {
  const scheduled = { ...textMoment, _id: "m3", scheduledFor: "2099-01-01T00:00:00.000Z" };

  it("the author's grid marks a moment that has not gone out yet", () => {
    renderMoments({ isOwn: true, userId: "me" }, { data: { data: [scheduled, imageMoment] } });
    expect(screen.getAllByTestId("scheduled-badge")).toHaveLength(1);
  });

  it("nobody else's grid does", () => {
    renderMoments({ isOwn: false }, { data: { data: [scheduled] } });
    expect(screen.queryByTestId("scheduled-badge")).not.toBeInTheDocument();
  });
});
