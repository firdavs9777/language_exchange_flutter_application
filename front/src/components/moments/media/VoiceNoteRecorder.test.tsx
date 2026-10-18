import "@testing-library/jest-dom";
import { render, waitFor } from "@testing-library/react";
import VoiceNoteRecorder from "./VoiceNoteRecorder";

const ctorCalls: any[] = [];
class FakeRecorder {
  static isTypeSupported = (t: string) => t === "audio/mp4";
  mimeType: string;
  state = "inactive";
  ondataavailable: any = null;
  onstop: any = null;
  constructor(_stream: any, options?: any) {
    ctorCalls.push(options);
    this.mimeType = (options && options.mimeType) || "audio/webm";
  }
  start() { this.state = "recording"; }
  stop() { this.state = "inactive"; if (this.onstop) this.onstop(); }
}

beforeEach(() => {
  ctorCalls.length = 0;
  (window as any).MediaRecorder = FakeRecorder;
  (navigator as any).mediaDevices = {
    getUserMedia: jest.fn(() => Promise.resolve({ getTracks: () => [{ stop: jest.fn() }] })),
  };
});
afterEach(() => {
  delete (window as any).MediaRecorder;
  delete (navigator as any).mediaDevices;
});

it("asks MediaRecorder for audio/mp4 when the browser supports it (moments#2)", async () => {
  render(<VoiceNoteRecorder onComplete={jest.fn()} onCancel={jest.fn()} />);
  await waitFor(() => expect(ctorCalls).toHaveLength(1));
  expect(ctorCalls[0]).toEqual({ mimeType: "audio/mp4" });
});

it("falls back to the browser default when the typed constructor throws (Safari < 18.4)", async () => {
  const Throwing: any = function (this: any, stream: any, options?: any) {
    if (options && options.mimeType) throw new Error("NotSupportedError");
    return new (FakeRecorder as any)(stream);
  };
  Throwing.isTypeSupported = () => true;
  (window as any).MediaRecorder = Throwing;
  const { findByTestId } = render(<VoiceNoteRecorder onComplete={jest.fn()} onCancel={jest.fn()} />);
  expect(await findByTestId("voice-note-recorder")).toBeInTheDocument();
  expect(ctorCalls[ctorCalls.length - 1]).toBeUndefined();
});
