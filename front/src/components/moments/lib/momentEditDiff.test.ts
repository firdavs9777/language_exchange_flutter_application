import { momentEditDiff, editableFrom } from "./momentEditDiff";

const moment = {
  title: "Busan",
  description: "Sunset",
  mood: "happy",
  tags: ["sea", "sun"],
  category: "travel",
  language: "ko",
  privacy: "public",
  backgroundColor: "",
  location: { formattedAddress: "Busan, Korea", type: "Point", coordinates: [129, 35] },
  scheduledFor: null,
};

describe("momentEditDiff", () => {
  it("an untouched moment has nothing to send", () => {
    expect(momentEditDiff(editableFrom(moment), editableFrom(moment))).toEqual({});
  });

  it("missing server fields read as their defaults", () => {
    const sparse = editableFrom({ description: "x" });
    expect(sparse).toEqual(
      expect.objectContaining({ title: "", mood: "", tags: [], category: "general", privacy: "public", location: null })
    );
    expect(momentEditDiff(sparse, editableFrom({ description: "x" }))).toEqual({});
  });

  it("sends only what changed", () => {
    const original = editableFrom(moment);
    expect(momentEditDiff(original, { ...original, mood: "sad" })).toEqual({ mood: "sad" });
    expect(momentEditDiff(original, { ...original, tags: ["sea", "sun"] })).toEqual({});
    expect(momentEditDiff(original, { ...original, tags: ["sea"] })).toEqual({ tags: ["sea"] });
    expect(momentEditDiff(original, { ...original, location: null })).toEqual({ location: null });
  });

  it("trims text before comparing", () => {
    const original = editableFrom(moment);
    expect(momentEditDiff(original, { ...original, title: " Busan " })).toEqual({});
    expect(momentEditDiff(original, { ...original, description: " New " })).toEqual({ description: "New" });
  });
});
