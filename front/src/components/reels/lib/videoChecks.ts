import { VideoConfig } from "../../../store/slices/reelsSlice";

export const REEL_ACCEPT = "video/*";

const EXT_TYPES: { [ext: string]: string } = {
  mp4: "video/mp4",
  mov: "video/quicktime",
  avi: "video/x-msvideo",
  webm: "video/webm",
  "3gp": "video/3gpp",
  m4v: "video/x-m4v",
};

/** Type and size against GET /moments/video-config; the duration is separate. */
export function checkReelFile(
  file: { type: string; name: string; size: number },
  config: VideoConfig
): "ok" | "type" | "size" {
  const ext = (file.name.split(".").pop() || "").toLowerCase();
  const type = file.type || EXT_TYPES[ext] || "";
  if (!type || config.allowedTypes.indexOf(type) < 0) return "type";
  if (file.size > config.maxSize) return "size";
  return "ok";
}

/**
 * The video's length in seconds from its metadata, or null when the browser
 * cannot say (MediaRecorder WebM reports Infinity; undecodable codecs error).
 * Null is allowed through: the server measures every upload and refuses a
 * reel over 180 s with REEL_TOO_LONG.
 */
export function readVideoDuration(file: File): Promise<number | null> {
  return new Promise((resolve) => {
    let url = "";
    try {
      url = URL.createObjectURL(file);
    } catch (e) {
      resolve(null);
      return;
    }
    const video: any = document.createElement("video");
    const done = (value: number | null) => {
      try {
        URL.revokeObjectURL(url);
      } catch (e) {
        // ignore
      }
      resolve(value);
    };
    video.preload = "metadata";
    video.muted = true;
    video.onloadedmetadata = () => {
      const d = Number(video.duration);
      done(isFinite(d) && d > 0 ? d : null);
    };
    video.onerror = () => done(null);
    video.src = url;
  });
}
