import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import CoverEditor, { COVER_MAX_BYTES } from "./CoverEditor";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: jest.fn() } }));
const mockSetG = jest.fn();
const mockRemoveG = jest.fn();
const mockSetC = jest.fn();
const mockRemoveC = jest.fn();
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useSetGatheringCoverMutation: () => [mockSetG, { isLoading: false }],
  useRemoveGatheringCoverMutation: () => [mockRemoveG, { isLoading: false }],
  useSetClubCoverMutation: () => [mockSetC, { isLoading: false }],
  useRemoveClubCoverMutation: () => [mockRemoveC, { isLoading: false }],
}));

const ok = () => ({ unwrap: () => Promise.resolve({}) });
beforeEach(() => {
  [mockSetG, mockRemoveG, mockSetC, mockRemoveC].forEach((m) => {
    m.mockReset();
    m.mockReturnValue(ok());
  });
});
const pick = (file: File) => fireEvent.change(screen.getByTestId("cover-input"), { target: { files: [file] } });

it("uploads a gathering cover", async () => {
  render(<CoverEditor kind="gathering" id="g1" hasCover={false} />);
  const file = new File(["x"], "c.jpg", { type: "image/jpeg" });
  pick(file);
  await waitFor(() => expect(mockSetG).toHaveBeenCalledWith({ id: "g1", file }));
  expect(screen.queryByTestId("cover-remove")).not.toBeInTheDocument();
});

it("uploads and removes a club cover", async () => {
  render(<CoverEditor kind="club" id="c1" hasCover />);
  const file = new File(["x"], "c.webp", { type: "image/webp" });
  pick(file);
  await waitFor(() => expect(mockSetC).toHaveBeenCalledWith({ id: "c1", file }));
  fireEvent.click(screen.getByTestId("cover-remove"));
  await waitFor(() => expect(mockRemoveC).toHaveBeenCalledWith("c1"));
});

it("refuses a type the server does not take, and a file over 10 MB", () => {
  render(<CoverEditor kind="gathering" id="g1" hasCover={false} />);
  pick(new File(["x"], "c.heic", { type: "image/heic" }));
  expect(screen.getByTestId("cover-error")).toHaveTextContent("JPEG, PNG, GIF or WebP");
  const big = new File(["x"], "big.jpg", { type: "image/jpeg" });
  Object.defineProperty(big, "size", { value: COVER_MAX_BYTES + 1 });
  pick(big);
  expect(screen.getByTestId("cover-error")).toHaveTextContent("10 MB");
  expect(mockSetG).not.toHaveBeenCalled();
});
