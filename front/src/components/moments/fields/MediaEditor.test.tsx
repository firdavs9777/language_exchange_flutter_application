import "@testing-library/jest-dom";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import MediaEditor from "./MediaEditor";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
jest.mock("../media/VoiceNoteRecorder", () => (props: any) => (
  <button type="button" onClick={() => props.onComplete(new Blob(["x"]), 3.2, [1, 2])}>
    finish recording
  </button>
));
jest.mock("../media/MomentVideoPlayer", () => () => <div>video</div>);
jest.mock("../media/VoiceNotePlayer", () => () => <div>voice</div>);

const mockUploadVideo = jest.fn();
const mockDeleteVideo = jest.fn();
const mockUploadAudio = jest.fn();
const mockDeleteAudio = jest.fn();
jest.mock("../../../store/slices/momentsSlice", () => ({
  useUploadMomentVideoMutation: () => [mockUploadVideo, { isLoading: false }],
  useDeleteMomentVideoMutation: () => [mockDeleteVideo, { isLoading: false }],
  useUploadMomentAudioMutation: () => [mockUploadAudio, { isLoading: false }],
  useDeleteMomentAudioMutation: () => [mockDeleteAudio, { isLoading: false }],
}));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn() },
}));

const ok = () => ({ unwrap: () => Promise.resolve({}) });
beforeEach(() => {
  [mockUploadVideo, mockDeleteVideo, mockUploadAudio, mockDeleteAudio].forEach((m) => m.mockReturnValue(ok()));
});

const videoMoment = { _id: "m1", mediaType: "video", video: { url: "https://cdn/v.mp4" } };
const audioMoment = { _id: "m2", mediaType: "audio", audio: { url: "https://cdn/a.webm", duration: 3, waveform: [] } };

it("removing the video asks first, and only a confirm deletes it", async () => {
  render(<MediaEditor moment={videoMoment} />);
  fireEvent.click(screen.getByRole("button", { name: "Remove" }));
  expect(screen.getByRole("dialog")).toBeInTheDocument();
  expect(mockDeleteVideo).not.toHaveBeenCalled();
  fireEvent.click(screen.getByRole("button", { name: "Cancel" }));
  expect(mockDeleteVideo).not.toHaveBeenCalled();

  fireEvent.click(screen.getByRole("button", { name: "Remove" }));
  fireEvent.click(screen.getAllByRole("button", { name: "Remove" }).slice(-1)[0]);
  await waitFor(() => expect(mockDeleteVideo).toHaveBeenCalledWith("m1"));
  expect(mockDeleteAudio).not.toHaveBeenCalled();
});

it("replacing the video uploads the chosen file", async () => {
  render(<MediaEditor moment={videoMoment} />);
  const file = new File(["v"], "clip.mp4", { type: "video/mp4" });
  fireEvent.change(screen.getByTestId("replace-video-input"), { target: { files: [file] } });
  await waitFor(() => expect(mockUploadVideo).toHaveBeenCalled());
  const { momentId, formData } = mockUploadVideo.mock.calls[0][0];
  expect(momentId).toBe("m1");
  expect(formData.get("video")).toBe(file);
});

it("removing the voice note uses the audio endpoint", async () => {
  render(<MediaEditor moment={audioMoment} />);
  fireEvent.click(screen.getByRole("button", { name: "Remove" }));
  fireEvent.click(screen.getAllByRole("button", { name: "Remove" }).slice(-1)[0]);
  await waitFor(() => expect(mockDeleteAudio).toHaveBeenCalledWith("m2"));
});

it("replacing the voice note records a new one and uploads it", async () => {
  render(<MediaEditor moment={audioMoment} />);
  fireEvent.click(screen.getByRole("button", { name: "Replace" }));
  fireEvent.click(screen.getByRole("button", { name: "finish recording" }));
  await waitFor(() => expect(mockUploadAudio).toHaveBeenCalled());
  const { momentId, formData } = mockUploadAudio.mock.calls[0][0];
  expect(momentId).toBe("m2");
  expect(formData.get("duration")).toBe("3.2");
  expect(formData.get("waveform")).toBe("[1,2]");
});

it("image and text moments have no media editor", () => {
  const { container } = render(<MediaEditor moment={{ _id: "m3", mediaType: "image" }} />);
  expect(container).toBeEmptyDOMElement();
});
