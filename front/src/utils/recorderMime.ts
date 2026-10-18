/**
 * Which audio type to ask MediaRecorder for.
 *
 * AAC in MP4 first: it is what the app records and what iOS (AVPlayer, via
 * just_audio) plays; Safari and recent Chrome can make it. Then Opus in
 * WebM/Ogg for Chrome/Firefox -- backend Phase 1 transcodes those to AAC.
 * Never a type the browser refuses: `new MediaRecorder(s, {mimeType})` with an
 * unsupported type THROWS (Safari < 18.4 with audio/webm), which is how web
 * recording broke there. With nothing supported, let the browser choose and
 * read `recorder.mimeType` afterwards (`extForMime`).
 */
export interface RecorderMime {
  mimeType: string | undefined;
  ext: string;
}

const CANDIDATES: RecorderMime[] = [
  { mimeType: "audio/mp4", ext: "m4a" },
  { mimeType: "audio/webm;codecs=opus", ext: "webm" },
  { mimeType: "audio/webm", ext: "webm" },
  { mimeType: "audio/ogg;codecs=opus", ext: "ogg" },
];

export function pickRecorderMime(): RecorderMime {
  const MR: any = typeof window !== "undefined" ? (window as any).MediaRecorder : undefined;
  if (!MR || typeof MR.isTypeSupported !== "function") return { mimeType: undefined, ext: "webm" };
  for (let i = 0; i < CANDIDATES.length; i += 1) {
    try {
      if (MR.isTypeSupported(CANDIDATES[i].mimeType)) return { ...CANDIDATES[i] };
    } catch (err) {
      return { mimeType: undefined, ext: "webm" };
    }
  }
  return { mimeType: undefined, ext: "webm" };
}

/** The type without codec parameters -- what the upload whitelist matches on. */
export function baseMime(mime: string): string {
  const base = (mime || "").split(";")[0].trim();
  return base || "audio/webm";
}

export function extForMime(mime: string): string {
  const base = baseMime(mime);
  if (base === "audio/mp4" || base === "audio/x-m4a" || base === "audio/m4a") return "m4a";
  if (base === "audio/aac" || base === "audio/x-aac") return "aac";
  if (base === "audio/ogg") return "ogg";
  if (base === "audio/mpeg" || base === "audio/mp3") return "mp3";
  return "webm";
}
