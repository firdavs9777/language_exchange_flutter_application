import "@testing-library/jest-dom";
import { fireEvent, render, screen } from "@testing-library/react";
import BackgroundField from "./BackgroundField";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

it("offers None plus all 20 gradients, including the 7 the web never had", () => {
  render(<BackgroundField value="" onChange={() => undefined} />);
  // None + 20 swatches
  expect(screen.getAllByRole("button")).toHaveLength(21);
  ["gradient_peach", "gradient_lavender", "gradient_mint", "gradient_rose",
   "gradient_slate", "gradient_ember", "gradient_lagoon"].forEach((key) => {
    expect(screen.getByLabelText(key)).toBeInTheDocument();
  });
});

it("reports the chosen key", () => {
  const onChange = jest.fn();
  render(<BackgroundField value="" onChange={onChange} />);
  fireEvent.click(screen.getByLabelText("gradient_lagoon"));
  expect(onChange).toHaveBeenCalledWith("gradient_lagoon");
});
