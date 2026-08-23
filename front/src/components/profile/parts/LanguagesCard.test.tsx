import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import LanguagesCard from "./LanguagesCard";

it("renders native and learning languages", () => {
  render(<LanguagesCard native="Korean" learning="English" />);
  expect(screen.getByTestId("language-native")).toHaveTextContent("Korean");
  expect(screen.getByTestId("language-learning")).toHaveTextContent("English");
});

it("renders the optional level slot only when provided", () => {
  const { rerender } = render(<LanguagesCard native="Korean" learning="English" />);
  expect(screen.queryByTestId("language-level")).not.toBeInTheDocument();

  rerender(<LanguagesCard native="Korean" learning="English" level="B2" />);
  expect(screen.getByTestId("language-level")).toHaveTextContent("B2");
});

it("returns null when neither language is provided", () => {
  const { container } = render(<LanguagesCard />);
  expect(container).toBeEmptyDOMElement();
});
