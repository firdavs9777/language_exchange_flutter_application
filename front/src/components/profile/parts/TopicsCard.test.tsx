import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import TopicsCard from "./TopicsCard";

it("renders one chip per topic", () => {
  render(<TopicsCard topics={["music", "travel", "food"]} />);
  expect(screen.getAllByTestId("topic-chip")).toHaveLength(3);
  expect(screen.getByText("music")).toBeInTheDocument();
});

it("returns null when topics is empty", () => {
  const { container } = render(<TopicsCard topics={[]} />);
  expect(container).toBeEmptyDOMElement();
});

it("returns null when topics is undefined", () => {
  const { container } = render(<TopicsCard />);
  expect(container).toBeEmptyDOMElement();
});
