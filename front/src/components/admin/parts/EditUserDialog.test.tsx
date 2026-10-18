import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import EditUserDialog from "./EditUserDialog";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const mockUpdate = jest.fn();
const mockUpdateState = { isLoading: false, error: undefined as any, reset: jest.fn() };

jest.mock("../../../store/slices/adminSlice", () => ({
  useUpdateUserMutation: () => [mockUpdate, mockUpdateState],
}));

const USER = {
  _id: "u1",
  name: "Ada Lovelace",
  bio: "Analytical engine",
  gender: "female",
  native_language: "English",
  language_to_learn: "Korean",
  userMode: "regular",
  vipSubscription: { isActive: false, endDate: null },
};

const VIP_USER = {
  ...USER,
  userMode: "vip",
  vipSubscription: { isActive: true, endDate: "2026-12-01T00:00:00.000Z" },
};

beforeEach(() => {
  mockUpdate.mockReset().mockImplementation(() => ({ unwrap: () => Promise.resolve(USER) }));
  mockUpdateState.isLoading = false;
  mockUpdateState.error = undefined;
});

const set = (testId: string, value: string) =>
  fireEvent.change(screen.getByTestId(testId), { target: { value } });

const submit = () => fireEvent.click(screen.getByTestId("edit-user-submit"));

it("prefills every field from the user it was given", () => {
  render(<EditUserDialog user={USER} onClose={jest.fn()} />);
  expect((screen.getByTestId("edit-user-name") as HTMLInputElement).value).toBe("Ada Lovelace");
  expect((screen.getByTestId("edit-user-bio") as HTMLTextAreaElement).value).toBe(
    "Analytical engine"
  );
  expect((screen.getByTestId("edit-user-gender") as HTMLSelectElement).value).toBe("female");
  expect((screen.getByTestId("edit-user-native") as HTMLSelectElement).value).toBe("English");
  expect((screen.getByTestId("edit-user-learning") as HTMLSelectElement).value).toBe("Korean");
  expect(screen.getByTestId("edit-user-vip")).not.toBeChecked();
});

it("sends the id and only the fields that changed", async () => {
  render(<EditUserDialog user={USER} onClose={jest.fn()} />);
  set("edit-user-name", "Ada L.");
  submit();
  await waitFor(() => expect(mockUpdate).toHaveBeenCalled());
  expect(mockUpdate).toHaveBeenCalledWith({ id: "u1", name: "Ada L." });
});

it("sends every edited field together", async () => {
  render(<EditUserDialog user={USER} onClose={jest.fn()} />);
  set("edit-user-name", "Ada L.");
  set("edit-user-bio", "Countess of Lovelace");
  set("edit-user-gender", "other");
  set("edit-user-native", "French");
  set("edit-user-learning", "Japanese");
  submit();
  await waitFor(() => expect(mockUpdate).toHaveBeenCalled());
  expect(mockUpdate).toHaveBeenCalledWith({
    id: "u1",
    name: "Ada L.",
    bio: "Countess of Lovelace",
    gender: "other",
    native_language: "French",
    language_to_learn: "Japanese",
  });
});

it("grants VIP for 30 days by default", async () => {
  render(<EditUserDialog user={USER} onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("edit-user-vip"));
  expect((screen.getByTestId("edit-user-vip-days") as HTMLInputElement).value).toBe("30");
  submit();
  await waitFor(() => expect(mockUpdate).toHaveBeenCalled());
  expect(mockUpdate).toHaveBeenCalledWith({ id: "u1", vip: { grant: true, days: 30 } });
});

it("grants VIP for the day count the moderator typed", async () => {
  render(<EditUserDialog user={USER} onClose={jest.fn()} />);
  fireEvent.click(screen.getByTestId("edit-user-vip"));
  set("edit-user-vip-days", "90");
  submit();
  await waitFor(() => expect(mockUpdate).toHaveBeenCalled());
  expect(mockUpdate).toHaveBeenCalledWith({ id: "u1", vip: { grant: true, days: 90 } });
});

it("revokes VIP when the toggle goes off for a VIP user", async () => {
  render(<EditUserDialog user={VIP_USER} onClose={jest.fn()} />);
  expect(screen.getByTestId("edit-user-vip")).toBeChecked();
  fireEvent.click(screen.getByTestId("edit-user-vip"));
  submit();
  await waitFor(() => expect(mockUpdate).toHaveBeenCalled());
  expect(mockUpdate).toHaveBeenCalledWith({ id: "u1", vip: { grant: false } });
});

it("leaves vip out of the body when the toggle was never touched", async () => {
  render(<EditUserDialog user={VIP_USER} onClose={jest.fn()} />);
  set("edit-user-name", "Ada L.");
  submit();
  await waitFor(() => expect(mockUpdate).toHaveBeenCalled());
  expect(mockUpdate).toHaveBeenCalledWith({ id: "u1", name: "Ada L." });
});

it("sends nothing at all when nothing was edited", () => {
  const onClose = jest.fn();
  render(<EditUserDialog user={USER} onClose={onClose} />);
  submit();
  expect(mockUpdate).not.toHaveBeenCalled();
  expect(onClose).toHaveBeenCalled();
});

it("refuses to make the two languages the same", () => {
  render(<EditUserDialog user={USER} onClose={jest.fn()} />);
  set("edit-user-learning", "English");
  submit();
  expect(mockUpdate).not.toHaveBeenCalled();
  expect(screen.getByTestId("edit-user-error-learning")).toHaveTextContent(
    /cannot be the same/i
  );
});

it("refuses an empty name", () => {
  render(<EditUserDialog user={USER} onClose={jest.fn()} />);
  set("edit-user-name", "   ");
  submit();
  expect(mockUpdate).not.toHaveBeenCalled();
  expect(screen.getByTestId("edit-user-error-name")).toBeInTheDocument();
});

it("closes once the edit lands", async () => {
  const onClose = jest.fn();
  render(<EditUserDialog user={USER} onClose={onClose} />);
  set("edit-user-name", "Ada L.");
  submit();
  await waitFor(() => expect(onClose).toHaveBeenCalled());
});

it("stays open on a failure and shows the backend's message", async () => {
  mockUpdate.mockImplementation(() => ({
    unwrap: () =>
      Promise.reject({
        status: 400,
        data: { message: "Native language and language to learn cannot be the same" },
      }),
  }));
  const onClose = jest.fn();
  render(<EditUserDialog user={USER} onClose={onClose} />);
  set("edit-user-name", "Ada L.");
  submit();
  await waitFor(() =>
    expect(screen.getByTestId("edit-user-form-error")).toHaveTextContent(
      "Native language and language to learn cannot be the same"
    )
  );
  expect(onClose).not.toHaveBeenCalled();
});

it("closes from Cancel without sending anything", () => {
  const onClose = jest.fn();
  render(<EditUserDialog user={USER} onClose={onClose} />);
  fireEvent.click(screen.getByTestId("edit-user-cancel"));
  expect(onClose).toHaveBeenCalled();
  expect(mockUpdate).not.toHaveBeenCalled();
});
