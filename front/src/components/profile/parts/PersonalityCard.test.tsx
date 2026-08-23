import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import PersonalityCard from "./PersonalityCard";

it("renders MBTI and blood type when both present", () => {
  render(<PersonalityCard mbti="INTJ" bloodType="O" />);
  expect(screen.getByTestId("personality-mbti")).toHaveTextContent("INTJ");
  expect(screen.getByTestId("personality-blood")).toHaveTextContent("O");
});

it("renders only MBTI when blood type absent", () => {
  render(<PersonalityCard mbti="ENFP" />);
  expect(screen.getByTestId("personality-mbti")).toHaveTextContent("ENFP");
  expect(screen.queryByTestId("personality-blood")).not.toBeInTheDocument();
});

it("returns null when both are absent", () => {
  const { container } = render(<PersonalityCard />);
  expect(container).toBeEmptyDOMElement();
});

it("returns null when both are empty strings", () => {
  const { container } = render(<PersonalityCard mbti="" bloodType="  " />);
  expect(container).toBeEmptyDOMElement();
});
