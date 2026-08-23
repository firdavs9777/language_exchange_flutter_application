import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import ProfileHeader from "./ProfileHeader";

it("shows a gradient initials fallback when avatarUrl is empty", () => {
  render(<ProfileHeader name="Alice" />);
  const fallback = screen.getByTestId("avatar-initials");
  expect(fallback).toHaveTextContent("A");
  expect(screen.queryByRole("img")).not.toBeInTheDocument();
});

it("renders the avatar image when avatarUrl is provided", () => {
  render(<ProfileHeader name="Alice" avatarUrl="http://x/a.png" />);
  expect(screen.getByRole("img")).toBeInTheDocument();
  expect(screen.queryByTestId("avatar-initials")).not.toBeInTheDocument();
});

it("shows the online dot only when isOnline", () => {
  const { rerender } = render(<ProfileHeader name="Alice" />);
  expect(screen.queryByTestId("online-dot")).not.toBeInTheDocument();
  rerender(<ProfileHeader name="Alice" isOnline />);
  expect(screen.getByTestId("online-dot")).toBeInTheDocument();
});

it("calls onEdit when the edit button is clicked", () => {
  const onEdit = jest.fn();
  render(<ProfileHeader name="Alice" username="alice" onEdit={onEdit} />);
  expect(screen.getByText("@alice")).toBeInTheDocument();
  fireEvent.click(screen.getByLabelText("Edit profile"));
  expect(onEdit).toHaveBeenCalledTimes(1);
});
