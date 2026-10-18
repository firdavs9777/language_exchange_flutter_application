import { baseMime, extForMime } from "./recorderMime";

/**
 * The recorded blob as it should be uploaded: its type without codec
 * parameters (the upload whitelist compares the base type) and a file name
 * whose extension matches, e.g. voice-note.m4a for audio/mp4.
 */
export function audioUpload(blob: Blob, baseName: string): { blob: Blob; filename: string } {
  const type = baseMime(blob.type);
  const out = blob.type === type ? blob : new Blob([blob], { type });
  return { blob: out, filename: `${baseName}.${extForMime(type)}` };
}
