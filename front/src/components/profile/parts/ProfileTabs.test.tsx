import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import ProfileTabs from "./ProfileTabs";

it("renders the default tabs and marks the active one", () => {
  render(<ProfileTabs active="moments" onChange={jest.fn()} />);
  expect(screen.getByTestId("profile-tab-overview")).toBeInTheDocument();
  expect(screen.getByTestId("profile-tab-moments")).toHaveAttribute("aria-selected", "true");
  expect(screen.getByTestId("profile-tab-about")).toHaveAttribute("aria-selected", "false");
});

it("calls onChange with the tab key when clicked", () => {
  const onChange = jest.fn();
  render(<ProfileTabs active="overview" onChange={onChange} />);
  fireEvent.click(screen.getByTestId("profile-tab-about"));
  expect(onChange).toHaveBeenCalledWith("about");
});

it("supports custom tabs", () => {
  render(<ProfileTabs active="a" onChange={jest.fn()} tabs={["a", "b"]} />);
  expect(screen.getByTestId("profile-tab-a")).toBeInTheDocument();
  expect(screen.getByTestId("profile-tab-b")).toBeInTheDocument();
  expect(screen.queryByTestId("profile-tab-overview")).not.toBeInTheDocument();
});
