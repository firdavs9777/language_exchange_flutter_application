/** The server's caps (utils/videoUtils.js), used until /video-config answers. */
export interface VideoLimits {
  maxDuration: number;
  maxSize: number;
  allowedTypes: string[];
}

export const DEFAULT_VIDEO_LIMITS: VideoLimits = {
  maxDuration: 600,
  maxSize: 1024 * 1024 * 1024,
  allowedTypes: ["video/mp4", "video/quicktime", "video/x-msvideo", "video/webm", "video/3gpp", "video/x-m4v"],
};

export function limitsFromConfig(response: any): VideoLimits {
  const video = response && response.data && response.data.video;
  if (!video) return DEFAULT_VIDEO_LIMITS;
  return {
    maxDuration: Number(video.maxDuration) || DEFAULT_VIDEO_LIMITS.maxDuration,
    maxSize: Number(video.maxSize) || DEFAULT_VIDEO_LIMITS.maxSize,
    allowedTypes:
      Array.isArray(video.allowedTypes) && video.allowedTypes.length
        ? video.allowedTypes
        : DEFAULT_VIDEO_LIMITS.allowedTypes,
  };
}

export type VideoCheck = "ok" | "tooBig" | "tooLong" | "badType";

export function checkVideo(file: File, limits: VideoLimits, durationSeconds: number | null): VideoCheck {
  const type = (file.type || "").split(";")[0];
  if (type && limits.allowedTypes.indexOf(type) === -1) return "badType";
  if (file.size > limits.maxSize) return "tooBig";
  if (durationSeconds !== null && durationSeconds > limits.maxDuration) return "tooLong";
  return "ok";
}

/** The file's duration from its metadata, or null when the browser can't tell (2 s cap). */
export function readVideoDuration(file: File): Promise<number | null> {
  return new Promise((resolve) => {
    if (typeof document === "undefined" || !(URL as any).createObjectURL) {
      resolve(null);
      return;
    }
    const url = URL.createObjectURL(file);
    const video = document.createElement("video");
    let done = false;
    const finish = (value: number | null) => {
      if (done) return;
      done = true;
      URL.revokeObjectURL(url);
      resolve(value);
    };
    video.preload = "metadata";
    video.onloadedmetadata = () => finish(isFinite(video.duration) ? video.duration : null);
    video.onerror = () => finish(null);
    setTimeout(() => finish(null), 2000);
    video.src = url;
  });
}
