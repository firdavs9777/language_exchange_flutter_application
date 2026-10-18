import { pickRecorderMime, extForMime, baseMime } from "./recorderMime";

const originalMR = (window as any).MediaRecorder;
afterEach(() => {
  (window as any).MediaRecorder = originalMR;
});

function withSupported(types: string[] | "throws") {
  (window as any).MediaRecorder = {
    isTypeSupported: (type: string) => {
      if (types === "throws") throw new Error("nope");
      return types.indexOf(type) > -1;
    },
  };
}

it("prefers AAC in MP4 (plays in the iOS app without conversion)", () => {
  withSupported(["audio/mp4", "audio/webm;codecs=opus"]);
  expect(pickRecorderMime()).toEqual({ mimeType: "audio/mp4", ext: "m4a" });
});

it("falls back to Opus in WebM on Chrome/Firefox", () => {
  withSupported(["audio/webm;codecs=opus", "audio/webm"]);
  expect(pickRecorderMime()).toEqual({ mimeType: "audio/webm;codecs=opus", ext: "webm" });
});

it("then plain WebM, then Ogg", () => {
  withSupported(["audio/webm"]);
  expect(pickRecorderMime()).toEqual({ mimeType: "audio/webm", ext: "webm" });
  withSupported(["audio/ogg;codecs=opus"]);
  expect(pickRecorderMime()).toEqual({ mimeType: "audio/ogg;codecs=opus", ext: "ogg" });
});

it("lets the browser choose when it supports none of them, or cannot say", () => {
  withSupported([]);
  expect(pickRecorderMime()).toEqual({ mimeType: undefined, ext: "webm" });
  withSupported("throws");
  expect(pickRecorderMime()).toEqual({ mimeType: undefined, ext: "webm" });
  (window as any).MediaRecorder = undefined;
  expect(pickRecorderMime()).toEqual({ mimeType: undefined, ext: "webm" });
});

it("maps a recorder's actual type to a file extension", () => {
  expect(extForMime("audio/mp4")).toBe("m4a");
  expect(extForMime("audio/mp4;codecs=mp4a.40.2")).toBe("m4a");
  expect(extForMime("audio/aac")).toBe("aac");
  expect(extForMime("audio/ogg;codecs=opus")).toBe("ogg");
  expect(extForMime("audio/mpeg")).toBe("mp3");
  expect(extForMime("audio/webm;codecs=opus")).toBe("webm");
  expect(extForMime("")).toBe("webm");
});

it("strips codec parameters for the upload's Content-Type", () => {
  expect(baseMime("audio/webm;codecs=opus")).toBe("audio/webm");
  expect(baseMime("")).toBe("audio/webm");
});
