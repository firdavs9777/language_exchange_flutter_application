import { checkVideo, DEFAULT_VIDEO_LIMITS, limitsFromConfig } from "./videoLimits";

const file = (type: string, size: number) => ({ type, size } as any as File);

it("accepts a video inside the limits", () => {
  expect(checkVideo(file("video/mp4", 10), DEFAULT_VIDEO_LIMITS, 30)).toBe("ok");
});

it("refuses one over the size cap before uploading", () => {
  expect(checkVideo(file("video/mp4", DEFAULT_VIDEO_LIMITS.maxSize + 1), DEFAULT_VIDEO_LIMITS, 30)).toBe("tooBig");
});

it("refuses one over the duration cap when the duration is known", () => {
  expect(checkVideo(file("video/mp4", 10), DEFAULT_VIDEO_LIMITS, 601)).toBe("tooLong");
  expect(checkVideo(file("video/mp4", 10), DEFAULT_VIDEO_LIMITS, null)).toBe("ok");
});

it("refuses a type the server does not take", () => {
  expect(checkVideo(file("video/x-matroska", 10), DEFAULT_VIDEO_LIMITS, 30)).toBe("badType");
});

it("reads the server's config and keeps the defaults for anything missing", () => {
  const limits = limitsFromConfig({ data: { video: { maxDuration: 180, maxSize: 100 } } });
  expect(limits.maxDuration).toBe(180);
  expect(limits.maxSize).toBe(100);
  expect(limits.allowedTypes).toEqual(DEFAULT_VIDEO_LIMITS.allowedTypes);
  expect(limitsFromConfig(undefined)).toEqual(DEFAULT_VIDEO_LIMITS);
});
