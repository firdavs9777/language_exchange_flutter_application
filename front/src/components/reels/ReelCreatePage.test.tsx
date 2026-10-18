import "@testing-library/jest-dom";
import React from "react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { render, screen, fireEvent, waitFor, act } from "@testing-library/react";
import ReelCreatePage from "./ReelCreatePage";

const mockCreate = jest.fn();
const mockUpload = jest.fn();
const mockDelete = jest.fn();
let mockDuration: number | null = 30;
jest.mock("../../store/slices/momentsSlice", () => ({
  useCreateMomentMutation: () => [mockCreate, { isLoading: false }],
  useUploadMomentVideoMutation: () => [mockUpload, { isLoading: false }],
  useDeleteMomentMutation: () => [mockDelete, { isLoading: false }],
}));
jest.mock("../../store/slices/reelsSlice", () => ({
  useGetReelVideoConfigQuery: () => ({ data: { allowedTypes: ["video/mp4"], maxSize: 5000 } }),
}));
jest.mock("./lib/videoChecks", () => {
  const actual = jest.requireActual("./lib/videoChecks");
  return { ...actual, readVideoDuration: () => Promise.resolve(mockDuration) };
});
jest.mock("./ReelPolicyGate", () => ({ __esModule: true, default: (p: any) => <>{p.children}</> }));
jest.mock("../moments/fields/LanguageField", () => ({
  __esModule: true,
  default: (p: any) => <input data-testid="lang" value={p.value} onChange={(e) => p.onChange(e.target.value)} />,
}));
jest.mock("react-toastify", () => ({ toast: { success: jest.fn(), error: jest.fn() } }));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const ok = (data: any) => ({ unwrap: () => Promise.resolve(data) });
const fail = (err: any) => ({ unwrap: () => Promise.reject(err) });

function renderPage() {
  (URL as any).createObjectURL = jest.fn(() => "blob:preview");
  (URL as any).revokeObjectURL = jest.fn();
  render(
    <MemoryRouter initialEntries={["/reels/new"]}>
      <Routes>
        <Route path="/reels/new" element={<ReelCreatePage />} />
        <Route path="/moment/:id" element={<div data-testid="moment-page" />} />
      </Routes>
    </MemoryRouter>
  );
}

async function pick(file: File) {
  await act(async () => {
    fireEvent.change(screen.getByTestId("reel-file"), { target: { files: [file] } });
  });
}
const mp4 = (size = 100) => new File([new Uint8Array(size)], "clip.mp4", { type: "video/mp4" });

beforeEach(() => {
  mockDuration = 30;
  [mockCreate, mockUpload, mockDelete].forEach((m) => m.mockReset());
  mockCreate.mockReturnValue(ok({ success: true, data: { _id: "m1" } }));
  mockUpload.mockReturnValue(ok({ success: true }));
  mockDelete.mockReturnValue(ok({ success: true }));
});

it("posts a public reel with isReel:true, then uploads the video as `video`", async () => {
  renderPage();
  expect(screen.getByTestId("reel-post")).toBeDisabled();
  await pick(mp4());
  expect(screen.getByTestId("reel-preview")).toHaveAttribute("src", "blob:preview");
  fireEvent.change(screen.getByTestId("reel-caption"), { target: { value: "  My first reel  " } });
  fireEvent.change(screen.getByTestId("lang"), { target: { value: "ko" } });
  await act(async () => {
    fireEvent.click(screen.getByTestId("reel-post"));
  });
  expect(mockCreate).toHaveBeenCalledWith({
    description: "My first reel",
    privacy: "public",
    category: "general",
    language: "ko",
    isReel: true,
  });
  const { momentId, formData } = mockUpload.mock.calls[0][0];
  expect(momentId).toBe("m1");
  expect((formData as FormData).get("video")).toBeInstanceOf(File);
  await waitFor(() => expect(screen.getByTestId("moment-page")).toBeInTheDocument());
});

it("refuses a video over 3 minutes before uploading anything", async () => {
  mockDuration = 181;
  renderPage();
  await pick(mp4());
  expect(screen.getByTestId("reel-create-error")).toHaveTextContent("3:00");
  expect(screen.getByTestId("reel-post")).toBeDisabled();
  expect(mockCreate).not.toHaveBeenCalled();
});

it("allows a video whose length the browser cannot read (the server checks it)", async () => {
  mockDuration = null;
  renderPage();
  await pick(mp4());
  expect(screen.queryByTestId("reel-create-error")).not.toBeInTheDocument();
  expect(screen.getByTestId("reel-post")).not.toBeDisabled();
});

it("refuses a wrong type or an oversized file", async () => {
  renderPage();
  await pick(new File(["x"], "a.gif", { type: "image/gif" }));
  expect(screen.getByTestId("reel-create-error")).toBeInTheDocument();
  await pick(mp4(6000));
  expect(screen.getByTestId("reel-create-error")).toBeInTheDocument();
  expect(screen.getByTestId("reel-post")).toBeDisabled();
});

it("deletes the empty reel and says why when the server finds it too long", async () => {
  mockUpload.mockReturnValue(fail({ status: 400, data: { code: "REEL_TOO_LONG", error: "Reels must be 180 seconds or under" } }));
  renderPage();
  await pick(mp4());
  await act(async () => {
    fireEvent.click(screen.getByTestId("reel-post"));
  });
  await waitFor(() => expect(mockDelete).toHaveBeenCalledWith("m1"));
  expect(screen.getByTestId("reel-create-error")).toHaveTextContent("3 minutes");
  expect(screen.queryByTestId("moment-page")).not.toBeInTheDocument();
});

it("keeps the form when creating the moment fails (posting limit, network)", async () => {
  mockCreate.mockReturnValue(fail({ status: 429, data: { error: "Daily moment limit reached" } }));
  renderPage();
  await pick(mp4());
  await act(async () => {
    fireEvent.click(screen.getByTestId("reel-post"));
  });
  expect(mockUpload).not.toHaveBeenCalled();
  expect(screen.getByTestId("reel-create-error")).toHaveTextContent("Daily moment limit reached");
  expect(screen.getByTestId("reel-post")).not.toBeDisabled();
});
