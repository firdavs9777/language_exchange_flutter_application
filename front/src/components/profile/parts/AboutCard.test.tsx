import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import AboutCard from "./AboutCard";

it("renders only rows with values", () => {
  render(<AboutCard bio="Hello world" location="Seoul" />);
  expect(screen.getByTestId("about-row-bio")).toHaveTextContent("Hello world");
  expect(screen.getByTestId("about-row-location")).toHaveTextContent("Seoul");
  expect(screen.queryByTestId("about-row-gender")).not.toBeInTheDocument();
  expect(screen.queryByTestId("about-row-birthday")).not.toBeInTheDocument();
});

it("returns null when all values are empty", () => {
  const { container } = render(<AboutCard bio="" gender="  " />);
  expect(container).toBeEmptyDOMElement();
});
