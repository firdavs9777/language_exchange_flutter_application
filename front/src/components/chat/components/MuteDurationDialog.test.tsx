import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import MuteDurationDialog from "./MuteDurationDialog";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

it("hands back the chosen duration in ms (null for always)", () => {
  const onChoose = jest.fn();
  render(<MuteDurationDialog name="Ada" onChoose={onChoose} onCancel={jest.fn()} />);
  expect(screen.getByText("Mute Ada?")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("mute-option-8h"));
  expect(onChoose).toHaveBeenCalledWith(28800000);
  fireEvent.click(screen.getByTestId("mute-option-always"));
  expect(onChoose).toHaveBeenLastCalledWith(null);
});

it("cancels", () => {
  const onCancel = jest.fn();
  render(<MuteDurationDialog name="Ada" onChoose={jest.fn()} onCancel={onCancel} />);
  fireEvent.click(screen.getByTestId("mute-cancel"));
  expect(onCancel).toHaveBeenCalled();
});
