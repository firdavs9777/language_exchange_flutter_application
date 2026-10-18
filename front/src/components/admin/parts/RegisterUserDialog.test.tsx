import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import RegisterUserDialog, { generatePassword } from "./RegisterUserDialog";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockCreate = jest.fn();
const mockCreateState = { isLoading: false, error: undefined as any, reset: jest.fn() };

jest.mock("../../../store/slices/adminSlice", () => ({
  useCreateUserMutation: () => [mockCreate, mockCreateState],
}));

const CREATED = { id: "u42", name: "Ada Lovelace", email: "ada@example.com", role: "user" };

beforeEach(() => {
  mockCreate.mockReset().mockImplementation(() => ({ unwrap: () => Promise.resolve(CREATED) }));
  mockCreateState.isLoading = false;
  mockCreateState.error = undefined;
});

const set = (testId: string, value: string) =>
  fireEvent.change(screen.getByTestId(testId), { target: { value } });

/** A checkbox toggles from a plain click; overriding `checked` first fights it. */
const toggle = (testId: string) => fireEvent.click(screen.getByTestId(testId));

/** Every field the backend requires, filled with something it would accept. */
const fillValid = () => {
  set("register-user-name", "Ada Lovelace");
  set("register-user-email", "Ada@Example.com");
  set("register-user-password", "Str0ngPassw0rd");
  set("register-user-gender", "female");
  set("register-user-birth-year", "1990");
  set("register-user-birth-month", "1");
  set("register-user-birth-day", "2");
  set("register-user-native", "English");
  set("register-user-learning", "Korean");
};

const submit = () => fireEvent.click(screen.getByTestId("register-user-submit"));

describe("generatePassword", () => {
  it("is 14 characters with a letter, a digit and a symbol", () => {
    for (let i = 0; i < 25; i += 1) {
      const pw = generatePassword();
      expect(pw).toHaveLength(14);
      expect(pw).toMatch(/[a-z]/);
      expect(pw).toMatch(/[A-Z]/);
      expect(pw).toMatch(/[0-9]/);
      expect(pw).toMatch(/[^A-Za-z0-9]/);
    }
  });

  it("does not hand out the same password twice", () => {
    const seen = new Set<string>();
    for (let i = 0; i < 25; i += 1) seen.add(generatePassword());
    expect(seen.size).toBeGreaterThan(20);
  });
});

it("renders every field the create endpoint requires", () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  [
    "register-user-name",
    "register-user-email",
    "register-user-password",
    "register-user-gender",
    "register-user-birth-year",
    "register-user-birth-month",
    "register-user-birth-day",
    "register-user-native",
    "register-user-learning",
    "register-user-role",
    "register-user-verified",
    "register-user-bio",
  ].forEach((id) => expect(screen.getByTestId(id)).toBeInTheDocument());
});

it("marks the email verified by default", () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  expect(screen.getByTestId("register-user-verified")).toBeChecked();
});

it("refuses to send an empty form and says which fields are missing", () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  submit();
  expect(mockCreate).not.toHaveBeenCalled();
  expect(screen.getByTestId("register-user-error-name")).toBeInTheDocument();
  expect(screen.getByTestId("register-user-error-email")).toBeInTheDocument();
  expect(screen.getByTestId("register-user-error-password")).toBeInTheDocument();
  expect(screen.getByTestId("register-user-error-gender")).toBeInTheDocument();
  expect(screen.getByTestId("register-user-error-birth")).toBeInTheDocument();
  expect(screen.getByTestId("register-user-error-native")).toBeInTheDocument();
  expect(screen.getByTestId("register-user-error-learning")).toBeInTheDocument();
});

it("rejects an address that is not an email", () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  set("register-user-email", "ada@example");
  submit();
  expect(mockCreate).not.toHaveBeenCalled();
  expect(screen.getByTestId("register-user-error-email")).toHaveTextContent(/valid email/i);
});

it("rejects a password the app itself would reject", () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  set("register-user-password", "short");
  submit();
  expect(mockCreate).not.toHaveBeenCalled();
  expect(screen.getByTestId("register-user-error-password")).toBeInTheDocument();
});

it("rejects the same language on both sides", () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  set("register-user-learning", "English");
  submit();
  expect(mockCreate).not.toHaveBeenCalled();
  expect(screen.getByTestId("register-user-error-learning")).toHaveTextContent(
    /cannot be the same/i
  );
});

it("offers no birth year that would make the account under 18", () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  const years = Array.prototype.slice
    .call(screen.getByTestId("register-user-birth-year").querySelectorAll("option"))
    .map((o: any) => o.value)
    .filter(Boolean)
    .map(Number);
  const oldest18 = new Date().getFullYear() - 18;
  expect(Math.max.apply(null, years)).toBe(oldest18);
  expect(years).not.toContain(oldest18 + 1);
});

it("rejects a birthday that has not come round yet in the 18th year", () => {
  // Pinned: "1 December 2008" is under 18 on this day and not on another.
  jest.useFakeTimers("modern" as any);
  jest.setSystemTime(new Date("2026-06-15T12:00:00.000Z"));
  try {
    render(<RegisterUserDialog onClose={jest.fn()} />);
    fillValid();
    set("register-user-birth-year", "2008");
    set("register-user-birth-month", "12");
    set("register-user-birth-day", "1");
    submit();
    expect(mockCreate).not.toHaveBeenCalled();
    expect(screen.getByTestId("register-user-error-birth")).toHaveTextContent(/18/);
  } finally {
    jest.useRealTimers();
  }
});

it("generates a 14-character password into the field", () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("register-user-generate"));
  const field = screen.getByTestId("register-user-password") as HTMLInputElement;
  expect(field.value).toHaveLength(14);
  expect(screen.getByTestId("register-user-copy")).toBeInTheDocument();
});

it("sends exactly the body the create endpoint documents", async () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  set("register-user-role", "admin");
  set("register-user-bio", "  Analytical engine  ");
  submit();
  await waitFor(() => expect(mockCreate).toHaveBeenCalled());
  expect(mockCreate).toHaveBeenCalledWith({
    name: "Ada Lovelace",
    email: "ada@example.com",
    password: "Str0ngPassw0rd",
    gender: "female",
    birth_year: 1990,
    birth_month: 1,
    birth_day: 2,
    native_language: "English",
    language_to_learn: "Korean",
    role: "admin",
    markVerified: true,
    bio: "Analytical engine",
  });
});

it("leaves the optional keys out when they were not filled in", async () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  toggle("register-user-verified");
  submit();
  await waitFor(() => expect(mockCreate).toHaveBeenCalled());
  const body = mockCreate.mock.calls[0][0];
  expect(body.bio).toBeUndefined();
  expect(body.role).toBe("user");
  expect(body.markVerified).toBe(false);
});

it("shows the new account, its password and the terms note once it is created", async () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  submit();
  const success = await screen.findByTestId("register-user-success");
  expect(success).toHaveTextContent("u42");
  expect(success).toHaveTextContent("ada@example.com");
  expect(screen.getByTestId("register-user-success-password")).toHaveTextContent(
    "Str0ngPassw0rd"
  );
  expect(success).toHaveTextContent(/terms/i);
  expect(screen.getByTestId("register-user-open-profile")).toHaveAttribute(
    "href",
    "/profile/u42"
  );
  expect(screen.queryByTestId("register-user-submit")).not.toBeInTheDocument();
});

it("resets to an empty form for the next person", async () => {
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  submit();
  await screen.findByTestId("register-user-success");
  fireEvent.click(screen.getByTestId("register-user-add-another"));
  expect(screen.getByTestId("register-user-submit")).toBeInTheDocument();
  expect((screen.getByTestId("register-user-email") as HTMLInputElement).value).toBe("");
  expect((screen.getByTestId("register-user-name") as HTMLInputElement).value).toBe("");
});

it("puts a duplicate email next to the email field", async () => {
  mockCreate.mockImplementation(() => ({
    unwrap: () =>
      Promise.reject({
        status: 409,
        data: { message: "A user with this email already exists", code: "EMAIL_EXISTS" },
      }),
  }));
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  submit();
  await waitFor(() =>
    expect(screen.getByTestId("register-user-error-email")).toHaveTextContent(
      "A user with this email already exists"
    )
  );
  expect(screen.queryByTestId("register-user-success")).not.toBeInTheDocument();
});

it("shows the backend's own message when it rejects the payload", async () => {
  mockCreate.mockImplementation(() => ({
    unwrap: () =>
      Promise.reject({
        status: 400,
        data: { message: "Native language and language to learn cannot be the same" },
      }),
  }));
  render(<RegisterUserDialog onClose={jest.fn()} />);
  fillValid();
  submit();
  await waitFor(() =>
    expect(screen.getByTestId("register-user-form-error")).toHaveTextContent(
      "Native language and language to learn cannot be the same"
    )
  );
});

it("closes from Cancel and from the backdrop", () => {
  const onClose = jest.fn();
  render(<RegisterUserDialog onClose={onClose} />);
  fireEvent.click(screen.getByTestId("register-user-cancel"));
  expect(onClose).toHaveBeenCalledTimes(1);
  fireEvent.click(screen.getByTestId("register-user-dialog-backdrop"));
  expect(onClose).toHaveBeenCalledTimes(2);
});
