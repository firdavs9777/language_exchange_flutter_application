import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import EditMessageDialog, { editErrorText } from "./EditMessageDialog";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const t = () => "";

function renderDialog(props: any = {}) {
  const onSave = jest.fn();
  const onCancel = jest.fn();
  render(
    <EditMessageDialog
      initialText="helo"
      busy={false}
      error=""
      onSave={onSave}
      onCancel={onCancel}
      {...props}
    />
  );
  return { onSave, onCancel };
}

it("starts with the message text and saves the trimmed edit", () => {
  const { onSave } = renderDialog();
  const input = screen.getByTestId("edit-message-input") as HTMLTextAreaElement;
  expect(input.value).toBe("helo");
  fireEvent.change(input, { target: { value: "  hello  " } });
  fireEvent.click(screen.getByTestId("edit-message-save"));
  expect(onSave).toHaveBeenCalledWith("hello");
});

it("cannot save an empty or unchanged text", () => {
  const { onSave } = renderDialog();
  expect(screen.getByTestId("edit-message-save")).toBeDisabled();
  fireEvent.change(screen.getByTestId("edit-message-input"), { target: { value: "   " } });
  expect(screen.getByTestId("edit-message-save")).toBeDisabled();
  fireEvent.click(screen.getByTestId("edit-message-save"));
  expect(onSave).not.toHaveBeenCalled();
});

it("caps the text at the backend's 2000 characters", () => {
  renderDialog();
  expect(screen.getByTestId("edit-message-input")).toHaveAttribute("maxLength", "2000");
});

it("shows the failure inside the dialog and locks it while saving", () => {
  renderDialog({ busy: true, error: "You can only edit a message within 15 minutes of sending it." });
  expect(screen.getByTestId("edit-message-error")).toHaveTextContent("15 minutes");
  expect(screen.getByTestId("edit-message-cancel")).toBeDisabled();
});

it("cancels", () => {
  const { onCancel } = renderDialog();
  fireEvent.click(screen.getByTestId("edit-message-cancel"));
  expect(onCancel).toHaveBeenCalled();
});

describe("editErrorText", () => {
  it("names the 15-minute window", () => {
    expect(
      editErrorText({ status: 400, data: { success: false, error: "Message can only be edited within 15 minutes" } }, t)
    ).toBe("You can only edit a message within 15 minutes of sending it.");
  });
  it("falls back to a generic line for anything else, never the raw validator text", () => {
    expect(editErrorText({ status: 400, data: { error: "Message content is required" } }, t)).toBe(
      "Couldn't edit the message. Try again."
    );
    expect(editErrorText(undefined, t)).toBe("Couldn't edit the message. Try again.");
  });
});
