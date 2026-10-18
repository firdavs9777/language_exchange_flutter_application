/**
 * Peak amplitudes (0..1) for a recorded clip, the shape the app draws its
 * voice bars from (Message.media.waveform). Best effort: any failure -- no
 * AudioContext, a codec the browser can record but not decode -- returns null
 * and the note is sent without one (the app then draws default bars).
 */
export async function computeWaveform(blob: Blob, bars: number = 30): Promise<number[] | null> {
  const AC: any =
    typeof window !== "undefined"
      ? (window as any).AudioContext || (window as any).webkitAudioContext
      : undefined;
  if (!AC || !blob || typeof (blob as any).arrayBuffer !== "function") return null;
  let ctx: any = null;
  try {
    ctx = new AC();
    const buffer = await (blob as any).arrayBuffer();
    const audio = await ctx.decodeAudioData(buffer);
    const data: Float32Array = audio.getChannelData(0);
    if (!data || data.length === 0) return null;
    const step = Math.max(1, Math.floor(data.length / bars));
    const peaks: number[] = [];
    for (let i = 0; i < bars; i += 1) {
      let peak = 0;
      const end = Math.min(data.length, (i + 1) * step);
      for (let j = i * step; j < end; j += 1) {
        const v = Math.abs(data[j]);
        if (v > peak) peak = v;
      }
      peaks.push(peak);
    }
    const max = Math.max.apply(null, peaks) || 1;
    return peaks.map((p) => Math.round((p / max) * 100) / 100);
  } catch (err) {
    return null;
  } finally {
    if (ctx && typeof ctx.close === "function") ctx.close().catch(() => undefined);
  }
}
