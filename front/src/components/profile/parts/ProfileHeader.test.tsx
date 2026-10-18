import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import ProfileHeader from "./ProfileHeader";

// An empty `t` forces the `|| "English"` fallbacks, so these assertions read
// as the copy a user sees rather than as key names.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const hoursAgo = (n: number) => new Date(Date.now() - n * 3600 * 1000).toISOString();

it("shows the name and a gradient initials fallback when there is no avatar", () => {
  render(<ProfileHeader name="Ada Lovelace" />);
  expect(screen.getByRole("heading")).toHaveTextContent("Ada Lovelace");
  expect(screen.getByTestId("avatar-initials")).toHaveTextContent("A");
  expect(screen.queryByTestId("avatar-image")).not.toBeInTheDocument();
});

it("renders the avatar image when one is given", () => {
  render(<ProfileHeader name="Ada" avatarUrl="http://x/a.png" />);
  expect(screen.getByTestId("avatar-image")).toHaveAttribute("src", "http://x/a.png");
});

it("always renders the cover band", () => {
  render(<ProfileHeader name="Ada" />);
  expect(screen.getByTestId("profile-cover")).toBeInTheDocument();
});

it("shows age and location when the fields are present", () => {
  render(
    <ProfileHeader
      name="Ada"
      birthYear={2000}
      birthMonth={1}
      birthDay={1}
      location={{ city: "Seoul", country: "South Korea" }}
    />
  );
  const meta = screen.getByTestId("profile-meta");
  expect(meta).toHaveTextContent("Seoul, South Korea");
  expect(meta.textContent).toMatch(/\d\d/);
});

it("omits the meta line entirely when neither age nor location is known", () => {
  render(<ProfileHeader name="Ada" />);
  expect(screen.queryByTestId("profile-meta")).not.toBeInTheDocument();
});

it("shows the VIP badge only for a vip userMode", () => {
  const { rerender } = render(<ProfileHeader name="Ada" userMode="regular" />);
  expect(screen.queryByTestId("badge-vip")).not.toBeInTheDocument();
  rerender(<ProfileHeader name="Ada" userMode="vip" />);
  expect(screen.getByTestId("badge-vip")).toHaveTextContent("VIP");
});

it("shows the verified badge only when isEmailVerified is true", () => {
  const { rerender } = render(<ProfileHeader name="Ada" />);
  expect(screen.queryByTestId("badge-verified")).not.toBeInTheDocument();
  rerender(<ProfileHeader name="Ada" isEmailVerified />);
  expect(screen.getByTestId("badge-verified")).toHaveTextContent("Verified");
});

it("shows the join month and year", () => {
  render(<ProfileHeader name="Ada" createdAt="2026-09-15T10:00:00.000Z" />);
  expect(screen.getByTestId("badge-joined")).toHaveTextContent("Joined Sep 2026");
});

it("omits the joined badge for an unparseable date", () => {
  render(<ProfileHeader name="Ada" createdAt="not-a-date" />);
  expect(screen.queryByTestId("badge-joined")).not.toBeInTheDocument();
});

it("shows a relative last-active badge", () => {
  render(<ProfileHeader name="Ada" lastActive={hoursAgo(2)} />);
  expect(screen.getByTestId("badge-active")).toHaveTextContent(/2 hours ago/);
});

it("prefers the online state over a stale last-active time", () => {
  render(<ProfileHeader name="Ada" isOnline lastActive={hoursAgo(2)} />);
  expect(screen.getByTestId("badge-active")).toHaveTextContent("Online now");
});

it("omits the active badge when lastActive is missing and the user is offline", () => {
  render(<ProfileHeader name="Ada" />);
  expect(screen.queryByTestId("badge-active")).not.toBeInTheDocument();
});

it("shows the username when there is one", () => {
  render(<ProfileHeader name="Ada" username="ada" />);
  expect(screen.getByText("@ada")).toBeInTheDocument();
});

// Editing is reached from the action row below the header (ProfileActions'
// "Edit profile" link), never from the cover band: the header carried an
// `onEdit` prop that no caller ever passed.
it("carries no edit control of its own", () => {
  render(<ProfileHeader name="Ada" />);
  expect(screen.queryByTestId("profile-header-edit")).not.toBeInTheDocument();
});
