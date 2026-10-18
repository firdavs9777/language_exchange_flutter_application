import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import WaveSheet from "./WaveSheet";

const mockSendWave = jest.fn();
const mockNavigate = jest.fn();
const mockToastError = jest.fn();
let mockIsLoading = false;

jest.mock("react-toastify", () => ({
  toast: { success: jest.fn(), error: (...args: any[]) => mockToastError(...args) },
  Bounce: {},
}));

// Resolve keys from eng.json (with {{name}} interpolation): the assertions
// below read what an English reader sees, and a missing key shows up as the
// raw key instead of quietly falling back.
jest.mock("react-i18next", () => {
  const eng = require("../../utils/locales/eng.json");
  const lookup = (key: string) =>
    key.split(".").reduce((node: any, part: string) => (node && typeof node === "object" ? node[part] : undefined), eng);
  return {
    useTranslation: () => ({
      t: (key: string, vars?: any) => {
        const raw = lookup(key);
        if (typeof raw !== "string") return key;
        return raw.replace(/{{\s*(\w+)\s*}}/g, (_: string, name: string) =>
          vars && vars[name] != null ? String(vars[name]) : ""
        );
      },
    }),
  };
});

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../store/slices/communitySlice", () => ({
  useSendWaveMutation: () => [
    mockSendWave,
    { isLoading: mockIsLoading },
  ],
}));

const targetUser = { _id: "user-2", name: "Bob", imageUrls: ["https://example.com/bob.jpg"] };

function renderSheet(props: any = {}) {
  return render(
    <MemoryRouter>
      <WaveSheet open={true} targetUser={targetUser} onClose={jest.fn()} {...props} />
    </MemoryRouter>
  );
}

const rejectWith = (status: number, data: any) =>
  mockSendWave.mockReturnValue({ unwrap: () => Promise.reject({ status, data }) });

describe("WaveSheet", () => {
  beforeEach(() => {
    mockSendWave.mockReset();
    mockNavigate.mockReset();
    mockToastError.mockReset();
    mockIsLoading = false;
  });

  it("renders nothing when closed", () => {
    renderSheet({ open: false });
    expect(screen.queryByTestId("wave-sheet")).not.toBeInTheDocument();
  });

  it("renders the title with the target user's name", () => {
    renderSheet();
    expect(screen.getByText("Send a wave to Bob")).toBeInTheDocument();
  });

  it("sends a wave with the composed message when Send is clicked", async () => {
    mockSendWave.mockReturnValue({
      unwrap: () => Promise.resolve({ success: true, data: { waveId: "w1", isMutual: false, message: "Wave sent!" } }),
    });
    const onClose = jest.fn();
    renderSheet({ onClose });

    fireEvent.click(screen.getByText("👋"));
    fireEvent.click(screen.getByTestId("wave-sheet-send"));

    await waitFor(() => expect(mockSendWave).toHaveBeenCalledWith({
      targetUserId: "user-2",
      message: "👋 Hi!",
    }));
    await waitFor(() => expect(onClose).toHaveBeenCalled());
  });

  it("shows an already-waved state and disables Send on ALREADY_WAVED", async () => {
    rejectWith(400, { success: false, error: "already waved", code: "ALREADY_WAVED" });
    renderSheet();

    fireEvent.click(screen.getByTestId("wave-sheet-send"));

    await waitFor(() =>
      expect(screen.getByText("You already waved at Bob")).toBeInTheDocument()
    );
    expect(screen.getByTestId("wave-sheet-send")).toBeDisabled();
  });

  describe("the daily cap (community#8)", () => {
    it("opens the VIP dialog instead of a toast on 429 wave_cap", async () => {
      rejectWith(429, {
        success: false,
        error: "Daily wave limit reached (5). Upgrade to VIP for unlimited waves.",
        code: "wave_cap",
      });
      renderSheet();
      fireEvent.click(screen.getByTestId("wave-sheet-send"));

      expect(await screen.findByText("Daily wave limit reached")).toBeInTheDocument();
      expect(mockToastError).not.toHaveBeenCalled();
      expect(screen.queryByTestId("wave-sheet")).not.toBeInTheDocument();
    });

    it("See VIP closes the sheet and opens the VIP page", async () => {
      rejectWith(429, { success: false, error: "cap", code: "wave_cap" });
      const onClose = jest.fn();
      renderSheet({ onClose });
      fireEvent.click(screen.getByTestId("wave-sheet-send"));
      fireEvent.click(await screen.findByTestId("confirm-dialog-confirm"));

      expect(onClose).toHaveBeenCalled();
      expect(mockNavigate).toHaveBeenCalledWith("/settings/vip");
    });

    it("Not now just closes", async () => {
      rejectWith(429, { success: false, error: "cap", code: "wave_cap" });
      const onClose = jest.fn();
      renderSheet({ onClose });
      fireEvent.click(screen.getByTestId("wave-sheet-send"));
      fireEvent.click(await screen.findByTestId("confirm-dialog-cancel"));

      expect(onClose).toHaveBeenCalled();
      expect(mockNavigate).not.toHaveBeenCalled();
    });

    it("keeps the plain toast for a 429 without the code (the rate limiter)", async () => {
      rejectWith(429, { success: false, error: "Too many requests" });
      renderSheet();
      fireEvent.click(screen.getByTestId("wave-sheet-send"));

      await waitFor(() => expect(mockToastError).toHaveBeenCalled());
      expect(screen.queryByText("Daily wave limit reached")).not.toBeInTheDocument();
    });
  });

  it("tells the caller about a sent wave and about ALREADY_WAVED", async () => {
    const onWaved = jest.fn();
    mockSendWave.mockReturnValue({
      unwrap: () => Promise.resolve({ success: true, data: { waveId: "w1", isMutual: true } }),
    });
    renderSheet({ onWaved });
    fireEvent.click(screen.getByTestId("wave-sheet-send"));
    await waitFor(() => expect(onWaved).toHaveBeenCalledWith("user-2", true));

    onWaved.mockReset();
    rejectWith(400, { success: false, error: "already", code: "ALREADY_WAVED" });
    renderSheet({ onWaved });
    fireEvent.click(screen.getAllByTestId("wave-sheet-send")[1]);
    await waitFor(() => expect(onWaved).toHaveBeenCalledWith("user-2", false));
  });
});
