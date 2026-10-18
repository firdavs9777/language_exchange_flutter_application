import { checkReelFile, readVideoDuration } from "./videoChecks";

const config = { allowedTypes: ["video/mp4", "video/quicktime", "video/webm"], maxSize: 1000 };

it("accepts an allowed type within the size limit", () => {
  expect(checkReelFile({ type: "video/mp4", name: "a.mp4", size: 999 }, config)).toBe("ok");
});

it("accepts a known extension when the browser gives no type (some .mov on Windows)", () => {
  expect(checkReelFile({ type: "", name: "clip.MOV", size: 10 }, config)).toBe("ok");
});

it("refuses other types and oversized files", () => {
  expect(checkReelFile({ type: "image/gif", name: "a.gif", size: 10 }, config)).toBe("type");
  expect(checkReelFile({ type: "video/mp4", name: "a.mp4", size: 1001 }, config)).toBe("size");
});

describe("readVideoDuration", () => {
  const realCreate = document.createElement.bind(document);
  let fakeVideo: any;
  beforeEach(() => {
    (URL as any).createObjectURL = jest.fn(() => "blob:x");
    (URL as any).revokeObjectURL = jest.fn();
    fakeVideo = { set src(_v: string) { setTimeout(() => fakeVideo.onloadedmetadata && fakeVideo.onloadedmetadata(), 0); }, duration: 0 };
    jest.spyOn(document, "createElement").mockImplementation((tag: string) =>
      tag === "video" ? fakeVideo : realCreate(tag)
    );
  });
  afterEach(() => jest.restoreAllMocks());

  it("reads the duration from the file's metadata and frees the object URL", async () => {
    fakeVideo.duration = 95.2;
    await expect(readVideoDuration(new File(["x"], "a.mp4", { type: "video/mp4" }))).resolves.toBe(95.2);
    expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:x");
  });

  it("returns null when the browser cannot tell (WebM reports Infinity)", async () => {
    fakeVideo.duration = Infinity;
    await expect(readVideoDuration(new File(["x"], "a.webm", { type: "video/webm" }))).resolves.toBe(null);
  });

  it("returns null when the file cannot be decoded", async () => {
    fakeVideo = { set src(_v: string) { setTimeout(() => fakeVideo.onerror && fakeVideo.onerror(), 0); } };
    await expect(readVideoDuration(new File(["x"], "a.mp4", { type: "video/mp4" }))).resolves.toBe(null);
  });
});
