import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import WaveSheet from "./WaveSheet";

const mockSendWave = jest.fn();
let mockIsLoading = false;

jest.mock("react-toastify", () => ({
  toast: { success: jest.fn(), error: jest.fn() },
  Bounce: {},
}));

jest.mock("../../store/slices/communitySlice", () => ({
  useSendWaveMutation: () => [
    mockSendWave,
    { isLoading: mockIsLoading },
  ],
}));

const targetUser = { _id: "user-2", name: "Bob", imageUrls: ["https://example.com/bob.jpg"] };

describe("WaveSheet", () => {
  beforeEach(() => {
    mockSendWave.mockReset();
    mockIsLoading = false;
  });

  it("renders nothing when closed", () => {
    render(<WaveSheet open={false} targetUser={targetUser} onClose={jest.fn()} />);
    expect(screen.queryByTestId("wave-sheet")).not.toBeInTheDocument();
  });

  it("renders the title with the target user's name", () => {
    render(<WaveSheet open={true} targetUser={targetUser} onClose={jest.fn()} />);
    expect(screen.getByText("Send a wave to Bob")).toBeInTheDocument();
  });

  it("sends a wave with the composed message when Send is clicked", async () => {
    mockSendWave.mockReturnValue({
      unwrap: () => Promise.resolve({ success: true, data: { waveId: "w1", isMutual: false, message: "Wave sent!" } }),
    });
    const onClose = jest.fn();
    render(<WaveSheet open={true} targetUser={targetUser} onClose={onClose} />);

    fireEvent.click(screen.getByText("👋"));
    fireEvent.click(screen.getByTestId("wave-sheet-send"));

    await waitFor(() => expect(mockSendWave).toHaveBeenCalledWith({
      targetUserId: "user-2",
      message: "👋 Hi!",
    }));
    await waitFor(() => expect(onClose).toHaveBeenCalled());
  });

  it("shows an already-waved state and disables Send on ALREADY_WAVED", async () => {
    mockSendWave.mockReturnValue({
      unwrap: () =>
        Promise.reject({
          status: 400,
          data: { success: false, error: "already waved", code: "ALREADY_WAVED" },
        }),
    });
    render(<WaveSheet open={true} targetUser={targetUser} onClose={jest.fn()} />);

    fireEvent.click(screen.getByTestId("wave-sheet-send"));

    await waitFor(() =>
      expect(screen.getByText("You already waved at Bob")).toBeInTheDocument()
    );
    expect(screen.getByTestId("wave-sheet-send")).toBeDisabled();
  });
});
