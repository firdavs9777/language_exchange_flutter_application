import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import DialogShell from "./DialogShell";

it("renders a labelled modal dialog with a backdrop", () => {
  render(
    <DialogShell label="Add user" onClose={jest.fn()}>
      <p>body</p>
    </DialogShell>
  );
  const dialog = screen.getByRole("dialog");
  expect(dialog).toHaveAttribute("aria-modal", "true");
  expect(dialog).toHaveAttribute("aria-label", "Add user");
  expect(dialog).toHaveTextContent("body");
  expect(screen.getByTestId("dialog-shell-backdrop")).toBeInTheDocument();
});

it("uses aria-labelledby instead of aria-label when the caller passes a heading id", () => {
  render(
    <DialogShell label="Add user" labelledBy="add-user-title" onClose={jest.fn()}>
      <h2 id="add-user-title">Add user</h2>
    </DialogShell>
  );
  const dialog = screen.getByRole("dialog");
  expect(dialog).toHaveAttribute("aria-labelledby", "add-user-title");
  expect(dialog).not.toHaveAttribute("aria-label");
});

it("restores focus to whatever had it before the dialog opened, on unmount", () => {
  const Harness: React.FC<{ show: boolean }> = ({ show }) => (
    <div>
      <button data-testid="trigger">Add user</button>
      {show ? (
        <DialogShell label="Add user" onClose={jest.fn()}>
          <button data-testid="inside">Save</button>
        </DialogShell>
      ) : null}
    </div>
  );
  const { rerender } = render(<Harness show={false} />);
  const trigger = screen.getByTestId("trigger");
  trigger.focus();
  expect(document.activeElement).toBe(trigger);

  rerender(<Harness show />);
  expect(document.activeElement).toBe(screen.getByRole("dialog"));

  rerender(<Harness show={false} />);
  expect(document.activeElement).toBe(trigger);
});

it("does not throw restoring focus to a node that was removed from the document", () => {
  const Harness: React.FC<{ show: boolean }> = ({ show }) => (
    <div>
      {show ? (
        <button data-testid="trigger">Add user</button>
      ) : null}
      {show ? (
        <DialogShell label="Add user" onClose={jest.fn()}>
          <p>body</p>
        </DialogShell>
      ) : null}
    </div>
  );
  const { rerender } = render(<Harness show />);
  screen.getByTestId("trigger").focus();
  expect(() => rerender(<Harness show={false} />)).not.toThrow();
});

it("closes on a backdrop click", () => {
  const onClose = jest.fn();
  render(
    <DialogShell label="Add user" onClose={onClose}>
      <p>body</p>
    </DialogShell>
  );
  fireEvent.click(screen.getByTestId("dialog-shell-backdrop"));
  expect(onClose).toHaveBeenCalled();
});

it("closes on Escape", () => {
  const onClose = jest.fn();
  render(
    <DialogShell label="Add user" onClose={onClose}>
      <p>body</p>
    </DialogShell>
  );
  fireEvent.keyDown(document, { key: "Escape" });
  expect(onClose).toHaveBeenCalledTimes(1);
});

it("stops listening for Escape once it unmounts", () => {
  const onClose = jest.fn();
  const { unmount } = render(
    <DialogShell label="Add user" onClose={onClose}>
      <p>body</p>
    </DialogShell>
  );
  unmount();
  fireEvent.keyDown(document, { key: "Escape" });
  expect(onClose).not.toHaveBeenCalled();
});

it("takes the testids the caller asks for, so an existing dialog keeps its own", () => {
  render(
    <DialogShell
      label="Confirm"
      onClose={jest.fn()}
      testId="confirm-dialog"
      backdropTestId="confirm-dialog-backdrop"
    >
      <p>body</p>
    </DialogShell>
  );
  expect(screen.getByTestId("confirm-dialog")).toBeInTheDocument();
  expect(screen.getByTestId("confirm-dialog-backdrop")).toBeInTheDocument();
});

it("focuses the element the caller nominates, not the panel", () => {
  const Harness: React.FC = () => {
    const ref = React.useRef<HTMLInputElement | null>(null);
    return (
      <DialogShell label="Add user" onClose={jest.fn()} initialFocusRef={ref}>
        <input data-testid="first" ref={ref} />
      </DialogShell>
    );
  };
  render(<Harness />);
  expect(document.activeElement).toBe(screen.getByTestId("first"));
});

it("focuses the panel itself when no element was nominated", () => {
  render(
    <DialogShell label="Add user" onClose={jest.fn()}>
      <p>body</p>
    </DialogShell>
  );
  expect(document.activeElement).toBe(screen.getByRole("dialog"));
});

it("keeps Tab inside the dialog", () => {
  render(
    <DialogShell label="Add user" onClose={jest.fn()}>
      <button data-testid="a">a</button>
      <button data-testid="b">b</button>
    </DialogShell>
  );
  const a = screen.getByTestId("a");
  const b = screen.getByTestId("b");

  b.focus();
  fireEvent.keyDown(screen.getByRole("dialog"), { key: "Tab" });
  expect(document.activeElement).toBe(a);

  a.focus();
  fireEvent.keyDown(screen.getByRole("dialog"), { key: "Tab", shiftKey: true });
  expect(document.activeElement).toBe(b);
});

// A dialog holding a request open must not be dismissable behind the request's
// back: ConfirmDialog passes `dismissible={!busy}` for exactly this.
it("ignores Escape and the backdrop while it is not dismissible", () => {
  const onClose = jest.fn();
  render(
    <DialogShell label="Ban user" onClose={onClose} dismissible={false}>
      <p>body</p>
    </DialogShell>
  );
  fireEvent.keyDown(document, { key: "Escape" });
  fireEvent.click(screen.getByTestId("dialog-shell-backdrop"));
  expect(onClose).not.toHaveBeenCalled();
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});

it("takes dismissals again once it becomes dismissible", () => {
  const onClose = jest.fn();
  const { rerender } = render(
    <DialogShell label="Ban user" onClose={onClose} dismissible={false}>
      <p>body</p>
    </DialogShell>
  );
  fireEvent.keyDown(document, { key: "Escape" });
  expect(onClose).not.toHaveBeenCalled();

  rerender(
    <DialogShell label="Ban user" onClose={onClose}>
      <p>body</p>
    </DialogShell>
  );
  fireEvent.keyDown(document, { key: "Escape" });
  expect(onClose).toHaveBeenCalledTimes(1);
});

it("locks the page behind it and restores the scroll on unmount", () => {
  document.body.style.overflow = "";
  const { unmount } = render(
    <DialogShell label="Add user" onClose={jest.fn()}>
      <p>body</p>
    </DialogShell>
  );
  expect(document.body.style.overflow).toBe("hidden");
  unmount();
  expect(document.body.style.overflow).toBe("");
});
