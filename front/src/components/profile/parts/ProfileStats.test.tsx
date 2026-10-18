import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import ProfileStats from "./ProfileStats";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

function renderStats(props: any) {
  return render(
    <MemoryRouter>
      <ProfileStats followers={0} following={0} moments={0} isOwn={false} {...props} />
    </MemoryRouter>
  );
}

it("renders the three counts with their labels", () => {
  renderStats({ userId: "u2", followers: 12, following: 3, moments: 7 });
  expect(screen.getByTestId("stat-followers")).toHaveTextContent("12");
  expect(screen.getByTestId("stat-followers")).toHaveTextContent("Followers");
  expect(screen.getByTestId("stat-following")).toHaveTextContent("3");
  expect(screen.getByTestId("stat-following")).toHaveTextContent("Following");
  expect(screen.getByTestId("stat-moments")).toHaveTextContent("7");
  expect(screen.getByTestId("stat-moments")).toHaveTextContent("Moments");
});

it("links the follower and following tiles to that user's lists", () => {
  renderStats({ userId: "u2" });
  expect(screen.getByTestId("stat-followers")).toHaveAttribute("href", "/profile/u2/followers");
  expect(screen.getByTestId("stat-following")).toHaveAttribute("href", "/profile/u2/following");
});

it("sends an own profile's moments tile to my-moments", () => {
  renderStats({ userId: "me", isOwn: true });
  expect(screen.getByTestId("stat-moments")).toHaveAttribute("href", "/my-moments");
});

it("sends another user's moments tile to their moments section", () => {
  renderStats({ userId: "u2", isOwn: false });
  expect(screen.getByTestId("stat-moments")).toHaveAttribute("href", "/profile/u2#moments");
});

it("falls back to the signed-in user's own list routes with no id", () => {
  renderStats({ isOwn: true });
  expect(screen.getByTestId("stat-followers")).toHaveAttribute("href", "/followersList");
  expect(screen.getByTestId("stat-following")).toHaveAttribute("href", "/followingsList");
  expect(screen.getByTestId("stat-moments")).toHaveAttribute("href", "/my-moments");
});

it("every tile is a real link, so the whole tile is tappable", () => {
  renderStats({ userId: "u2" });
  expect(screen.getAllByRole("link")).toHaveLength(3);
});
