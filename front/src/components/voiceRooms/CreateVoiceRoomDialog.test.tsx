import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import CreateVoiceRoomDialog, { buildCreateBody } from "./CreateVoiceRoomDialog";

const mockCreate = jest.fn();
jest.mock("../../store/slices/voiceRoomsSlice", () => ({
  useCreateVoiceRoomMutation: () => [mockCreate, { isLoading: false }],
  voiceRoomErrorText: (err: any) => (err && err.status === 403 ? "Creating voice rooms needs a VIP plan." : "Something went wrong. Try again."),
}));
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

beforeEach(() => mockCreate.mockReset());

it("builds the app's body: trimmed title, clamped size, ISO start only in the future", () => {
  const future = new Date(Date.now() + 3600 * 1000);
  const local = new Date(future.getTime() - future.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  expect(
    buildCreateBody({ title: "  Evening Korean ", description: "", language: "Korean", category: "language_practice", maxParticipants: 80, when: local })
  ).toEqual({
    title: "Evening Korean",
    topic: "language_exchange",
    language: "Korean",
    category: "language_practice",
    maxParticipants: 50,
    scheduledFor: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
  });
  expect(buildCreateBody({ title: "x", description: "d", language: "ko", category: "", maxParticipants: 1, when: "" })).toEqual({
    title: "x",
    description: "d",
    topic: "language_exchange",
    language: "ko",
    maxParticipants: 2,
  });
});

it("creates and hands back the new room id", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.resolve({ success: true, data: { _id: "r9" } }) });
  const onCreated = jest.fn();
  render(<CreateVoiceRoomDialog open defaultLanguage="Korean" onClose={jest.fn()} onCreated={onCreated} />);
  expect((screen.getByTestId("create-voice-room-language") as HTMLInputElement).value).toBe("Korean");
  expect(screen.getByTestId("create-voice-room-submit")).toBeDisabled();
  fireEvent.change(screen.getByTestId("create-voice-room-title"), { target: { value: "Evening Korean" } });
  fireEvent.click(screen.getByTestId("create-voice-room-submit"));
  await waitFor(() => expect(onCreated).toHaveBeenCalledWith("r9"));
  expect(mockCreate).toHaveBeenCalledWith(expect.objectContaining({ title: "Evening Korean", language: "Korean", maxParticipants: 8 }));
});

it("shows the VIP refusal inside the dialog", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.reject({ status: 403, data: { error: "Voice rooms are not available for your account type." } }) });
  render(<CreateVoiceRoomDialog open defaultLanguage="Korean" onClose={jest.fn()} onCreated={jest.fn()} />);
  fireEvent.change(screen.getByTestId("create-voice-room-title"), { target: { value: "Room" } });
  fireEvent.click(screen.getByTestId("create-voice-room-submit"));
  await waitFor(() => expect(screen.getByTestId("create-voice-room-error")).toHaveTextContent("VIP"));
});

it("renders nothing when closed", () => {
  render(<CreateVoiceRoomDialog open={false} defaultLanguage="" onClose={jest.fn()} onCreated={jest.fn()} />);
  expect(screen.queryByTestId("create-voice-room-dialog")).not.toBeInTheDocument();
});
