import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import ConfirmDialog from "./ConfirmDialog";

const base = () => ({
  open: true,
  title: "Ban user",
  body: "They lose access immediately.",
  confirmLabel: "Ban",
  onConfirm: jest.fn(),
  onCancel: jest.fn(),
});

it("renders nothing while closed", () => {
  const props = base();
  const { container } = render(<ConfirmDialog {...props} open={false} />);
  expect(container).toBeEmptyDOMElement();
});

it("renders the title, body and confirm label in a dialog", () => {
  const props = base();
  render(<ConfirmDialog {...props} />);
  const dialog = screen.getByRole("dialog");
  expect(dialog).toHaveTextContent("Ban user");
  expect(dialog).toHaveTextContent("They lose access immediately.");
  expect(screen.getByTestId("confirm-dialog-confirm")).toHaveTextContent("Ban");
});

it("confirms straight away when nothing is required", () => {
  const props = base();
  render(<ConfirmDialog {...props} />);
  expect(screen.getByTestId("confirm-dialog-confirm")).not.toBeDisabled();
  fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
  expect(props.onConfirm).toHaveBeenCalledWith("");
});

it("keeps confirm disabled until a reason is entered", () => {
  const props = base();
  render(<ConfirmDialog {...props} requireReason />);
  const confirm = screen.getByTestId("confirm-dialog-confirm");
  expect(confirm).toBeDisabled();

  // Whitespace is not a reason.
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "   " } });
  expect(confirm).toBeDisabled();

  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "spamming" } });
  expect(confirm).not.toBeDisabled();
  fireEvent.click(confirm);
  expect(props.onConfirm).toHaveBeenCalledWith("spamming");
});

it("keeps confirm disabled until the typed value matches exactly", () => {
  const props = base();
  render(
    <ConfirmDialog
      {...props}
      confirmLabel="Delete"
      requireTypedValue="ada@example.com"
      danger
    />
  );
  const confirm = screen.getByTestId("confirm-dialog-confirm");
  expect(confirm).toBeDisabled();

  fireEvent.change(screen.getByTestId("confirm-dialog-typed"), {
    target: { value: "ada@example.co" },
  });
  expect(confirm).toBeDisabled();

  // Case matters: this is a destructive, irreversible action.
  fireEvent.change(screen.getByTestId("confirm-dialog-typed"), {
    target: { value: "ADA@EXAMPLE.COM" },
  });
  expect(confirm).toBeDisabled();

  fireEvent.change(screen.getByTestId("confirm-dialog-typed"), {
    target: { value: "ada@example.com" },
  });
  expect(confirm).not.toBeDisabled();
});

it("requires both the reason and the typed value when both are asked for", () => {
  const props = base();
  render(<ConfirmDialog {...props} requireReason requireTypedValue="ada@example.com" />);
  const confirm = screen.getByTestId("confirm-dialog-confirm");
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "gdpr" } });
  expect(confirm).toBeDisabled();
  fireEvent.change(screen.getByTestId("confirm-dialog-typed"), {
    target: { value: "ada@example.com" },
  });
  expect(confirm).not.toBeDisabled();
  fireEvent.click(confirm);
  expect(props.onConfirm).toHaveBeenCalledWith("gdpr");
});

it("disables confirm while busy so an action cannot be sent twice", () => {
  const props = base();
  render(<ConfirmDialog {...props} busy />);
  const confirm = screen.getByTestId("confirm-dialog-confirm");
  expect(confirm).toBeDisabled();
  expect(confirm).toHaveAttribute("aria-busy", "true");
  fireEvent.click(confirm);
  expect(props.onConfirm).not.toHaveBeenCalled();
});

it("shows the mutation error inline and leaves the dialog open", () => {
  const props = base();
  render(<ConfirmDialog {...props} error="You cannot ban yourself" />);
  expect(screen.getByTestId("confirm-dialog-error")).toHaveTextContent("You cannot ban yourself");
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});

it("cancels from the cancel button, Escape and the backdrop", () => {
  const props = base();
  render(<ConfirmDialog {...props} />);
  fireEvent.click(screen.getByTestId("confirm-dialog-cancel"));
  expect(props.onCancel).toHaveBeenCalledTimes(1);

  fireEvent.keyDown(document, { key: "Escape" });
  expect(props.onCancel).toHaveBeenCalledTimes(2);

  fireEvent.click(screen.getByTestId("confirm-dialog-backdrop"));
  expect(props.onCancel).toHaveBeenCalledTimes(3);
});

it("clears the reason and typed value between openings", () => {
  const props = base();
  const { rerender } = render(<ConfirmDialog {...props} requireReason />);
  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), { target: { value: "spam" } });
  rerender(<ConfirmDialog {...props} requireReason open={false} />);
  rerender(<ConfirmDialog {...props} requireReason open />);
  expect(screen.getByTestId("confirm-dialog-reason")).toHaveValue("");
  expect(screen.getByTestId("confirm-dialog-confirm")).toBeDisabled();
});

it("refuses every dismissal while busy — cancel, Escape and the backdrop", () => {
  const props = base();
  render(<ConfirmDialog {...props} busy />);

  expect(screen.getByTestId("confirm-dialog-cancel")).toBeDisabled();
  fireEvent.click(screen.getByTestId("confirm-dialog-cancel"));
  fireEvent.keyDown(document, { key: "Escape" });
  fireEvent.click(screen.getByTestId("confirm-dialog-backdrop"));

  expect(props.onCancel).not.toHaveBeenCalled();
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});

it("takes dismissals again once the mutation settles", () => {
  const props = base();
  const { rerender } = render(<ConfirmDialog {...props} busy />);
  fireEvent.keyDown(document, { key: "Escape" });
  expect(props.onCancel).not.toHaveBeenCalled();

  rerender(<ConfirmDialog {...props} busy={false} />);
  fireEvent.keyDown(document, { key: "Escape" });
  expect(props.onCancel).toHaveBeenCalledTimes(1);
});

// The same chrome the profile lightbox has always had. With this dialog now
// gating Block, Report, photo deletion and moment deletion, two overlays on
// one page must not disagree about what Tab does.
describe("dialog chrome", () => {
  it("wraps Tab and Shift+Tab inside the dialog", () => {
    const props = base();
    render(<ConfirmDialog {...props} />);
    const dialog = screen.getByTestId("confirm-dialog");
    const cancel = screen.getByTestId("confirm-dialog-cancel");
    const confirm = screen.getByTestId("confirm-dialog-confirm");

    confirm.focus();
    fireEvent.keyDown(dialog, { key: "Tab" });
    expect(document.activeElement).toBe(cancel);

    fireEvent.keyDown(dialog, { key: "Tab", shiftKey: true });
    expect(document.activeElement).toBe(confirm);
  });

  it("keeps the reason field inside the trap", () => {
    const props = base();
    render(<ConfirmDialog {...props} requireReason />);
    const dialog = screen.getByTestId("confirm-dialog");
    const reason = screen.getByTestId("confirm-dialog-reason");
    const cancel = screen.getByTestId("confirm-dialog-cancel");

    // Confirm is disabled until a reason is typed, so Cancel is the last stop.
    cancel.focus();
    fireEvent.keyDown(dialog, { key: "Tab" });
    expect(document.activeElement).toBe(reason);
  });

  it("locks the page behind it and restores the scroll on close", () => {
    const props = base();
    document.body.style.overflow = "";
    const { rerender, unmount } = render(<ConfirmDialog {...props} />);
    expect(document.body.style.overflow).toBe("hidden");

    rerender(<ConfirmDialog {...props} open={false} />);
    expect(document.body.style.overflow).toBe("");

    rerender(<ConfirmDialog {...props} open />);
    expect(document.body.style.overflow).toBe("hidden");
    unmount();
    expect(document.body.style.overflow).toBe("");
  });
});

// From the admin branch: the dialog now renders through design/DialogShell,
// which names it from the caller's own heading instead of a duplicated string.
it("is named by its visible heading", () => {
  const props = base();
  render(<ConfirmDialog {...props} />);
  const dialog = screen.getByRole("dialog");
  expect(dialog).toHaveAttribute("aria-labelledby", "confirm-dialog-title");
  expect(document.getElementById("confirm-dialog-title")).toHaveTextContent("Ban user");
});

it("offers an optional note under showReason without gating confirm on it", () => {
  const props = base();
  render(<ConfirmDialog {...props} showReason />);
  const confirm = screen.getByTestId("confirm-dialog-confirm");
  expect(screen.getByTestId("confirm-dialog-reason")).toBeInTheDocument();
  expect(confirm).not.toBeDisabled();

  fireEvent.change(screen.getByTestId("confirm-dialog-reason"), {
    target: { value: "  duplicate report " },
  });
  fireEvent.click(confirm);
  expect(props.onConfirm).toHaveBeenCalledWith("duplicate report");
});

// A report's description is capped at 500 by the backend (models/Report.js).
// The cap has to be a keystroke the browser refuses, not a 400 that arrives
// after the round trip and takes the text with it.
it("caps the reason at reasonMaxLength and counts what is left", () => {
  const props = base();
  render(<ConfirmDialog {...props} requireReason reasonMaxLength={500} />);
  const field = screen.getByTestId("confirm-dialog-reason");
  expect(field).toHaveAttribute("maxlength", "500");

  fireEvent.change(field, { target: { value: "abc" } });
  expect(screen.getByTestId("confirm-dialog-reason-count")).toHaveTextContent("3 / 500");
});

it("shows no counter when no cap was asked for", () => {
  const props = base();
  render(<ConfirmDialog {...props} requireReason />);
  expect(screen.getByTestId("confirm-dialog-reason")).not.toHaveAttribute("maxlength");
  expect(screen.queryByTestId("confirm-dialog-reason-count")).not.toBeInTheDocument();
});
