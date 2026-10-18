import "@testing-library/jest-dom";
import { fireEvent, render, screen } from "@testing-library/react";
import ScheduleField from "./ScheduleField";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

it("shows an error for a past time", () => {
  const onChange = jest.fn();
  const { rerender } = render(<ScheduleField value="" onChange={onChange} />);
  fireEvent.change(screen.getByLabelText("Schedule"), { target: { value: "2020-01-01T10:00" } });
  expect(onChange).toHaveBeenCalledWith("2020-01-01T10:00");
  rerender(<ScheduleField value="2020-01-01T10:00" onChange={onChange} />);
  expect(screen.getByRole("alert")).toHaveTextContent("Pick a time in the future");
});

it("clears back to posting now", () => {
  const onChange = jest.fn();
  render(<ScheduleField value="2099-01-01T10:00" onChange={onChange} />);
  expect(screen.queryByRole("alert")).not.toBeInTheDocument();
  fireEvent.click(screen.getByRole("button", { name: "Post now instead" }));
  expect(onChange).toHaveBeenCalledWith("");
});
