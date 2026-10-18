import { computeWaveform } from "./audioWaveform";

const originalAC = (window as any).AudioContext;
afterEach(() => {
  (window as any).AudioContext = originalAC;
});

it("returns null when the browser has no AudioContext", async () => {
  (window as any).AudioContext = undefined;
  (window as any).webkitAudioContext = undefined;
  await expect(computeWaveform(new Blob(["x"]), 10)).resolves.toBe(null);
});

it("turns samples into `bars` peaks between 0 and 1", async () => {
  const samples = new Float32Array(1000);
  for (let i = 0; i < 1000; i += 1) samples[i] = i < 500 ? 0.1 : -0.8;
  (window as any).AudioContext = function () {
    return {
      decodeAudioData: (_buf: ArrayBuffer) => Promise.resolve({ getChannelData: () => samples }),
      close: () => Promise.resolve(),
    };
  };
  const blob: any = { arrayBuffer: () => Promise.resolve(new ArrayBuffer(8)) };
  const bars = await computeWaveform(blob, 10);
  expect(bars).toHaveLength(10);
  bars!.forEach((v) => {
    expect(v).toBeGreaterThanOrEqual(0);
    expect(v).toBeLessThanOrEqual(1);
  });
  expect(bars![0]).toBeLessThan(bars![9]);
  expect(bars![9]).toBe(1);
});

it("returns null when decoding fails (never blocks the send)", async () => {
  (window as any).AudioContext = function () {
    return { decodeAudioData: () => Promise.reject(new Error("bad")), close: () => Promise.resolve() };
  };
  const blob: any = { arrayBuffer: () => Promise.resolve(new ArrayBuffer(8)) };
  await expect(computeWaveform(blob, 10)).resolves.toBe(null);
});
