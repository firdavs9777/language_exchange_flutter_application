import { audioUpload } from "./audioUpload";

it("names the upload after its real type and drops codec parameters", () => {
  const mp4 = audioUpload(new Blob(["x"], { type: "audio/mp4;codecs=mp4a.40.2" }), "voice-note");
  expect(mp4.filename).toBe("voice-note.m4a");
  expect(mp4.blob.type).toBe("audio/mp4");
});

it("an untyped blob is uploaded as WebM (the server transcodes it)", () => {
  const untyped = audioUpload(new Blob(["x"]), "voice-note");
  expect(untyped.filename).toBe("voice-note.webm");
  expect(untyped.blob.type).toBe("audio/webm");
});

it("keeps the same blob when its type is already clean", () => {
  const blob = new Blob(["x"], { type: "audio/ogg" });
  const out = audioUpload(blob, "n");
  expect(out.blob).toBe(blob);
  expect(out.filename).toBe("n.ogg");
});
