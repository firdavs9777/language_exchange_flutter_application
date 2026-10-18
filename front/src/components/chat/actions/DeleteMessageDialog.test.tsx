import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import DeleteMessageDialog, { deleteErrorText } from "./DeleteMessageDialog";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

function renderDialog(props: any = {}) {
  const onDelete = jest.fn();
  const onCancel = jest.fn();
  render(
    <DeleteMessageDialog
      canDeleteForEveryone
      busy={false}
      error=""
      onDelete={onDelete}
      onCancel={onCancel}
      {...props}
    />
  );
  return { onDelete, onCancel };
}

it("offers both choices inside the hour", () => {
  const { onDelete } = renderDialog();
  fireEvent.click(screen.getByTestId("delete-for-everyone"));
  expect(onDelete).toHaveBeenCalledWith(true);
  fireEvent.click(screen.getByTestId("delete-for-me"));
  expect(onDelete).toHaveBeenCalledWith(false);
});

it("offers only 'for me' once the hour is over", () => {
  renderDialog({ canDeleteForEveryone: false });
  expect(screen.queryByTestId("delete-for-everyone")).not.toBeInTheDocument();
  expect(screen.getByTestId("delete-for-me")).toBeInTheDocument();
});

it("locks while the request runs and shows its failure", () => {
  renderDialog({ busy: true, error: "Couldn't delete the message. Try again." });
  expect(screen.getByTestId("delete-for-me")).toBeDisabled();
  expect(screen.getByTestId("delete-message-cancel")).toBeDisabled();
  expect(screen.getByTestId("delete-message-error")).toHaveTextContent("Couldn't delete");
});

it("names the one-hour window", () => {
  const t = () => "";
  expect(
    deleteErrorText({ data: { error: "Message can only be deleted for everyone within 1 hour" } }, t)
  ).toBe("You can only delete a message for everyone within 1 hour of sending it.");
  expect(deleteErrorText({ status: 500 }, t)).toBe("Couldn't delete the message. Try again.");
});
