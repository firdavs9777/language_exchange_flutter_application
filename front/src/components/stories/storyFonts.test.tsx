import React from "react";
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import StoryCanvas from "./StoryCanvas";
import { OVERLAY_FONT_CLASS, storyBodyFontClass } from "./storyOverlays";

jest.mock("react-router-dom", () => ({
  Link: ({ to, children, ...rest }: any) => (
    <a href={to} {...rest}>
      {children}
    </a>
  ),
}));

const textStory = (fontStyle?: string) => ({
  _id: "s1",
  mediaType: "text",
  text: "Hello",
  backgroundColor: "#000000",
  textColor: "#FFFFFF",
  fontStyle,
});

describe("text-story body font (app ViewerTextStoryLayer)", () => {
  it.each([
    ["normal", "font-normal", ["italic", "font-semibold", "font-hand"]],
    ["bold", "font-bold", ["italic", "font-semibold"]],
    ["italic", "italic", ["font-serif", "font-semibold"]],
    ["handwriting", "font-hand", ["italic", "font-semibold"]],
  ])("paints %s the way the app does", (style, expected, absent) => {
    render(<StoryCanvas story={textStory(style as string)} />);
    const body = screen.getByTestId("story-text");
    expect(body.className).toContain(expected as string);
    (absent as string[]).forEach((cls) => expect(body.className.split(" ")).not.toContain(cls));
  });

  it("treats a missing or unknown style as normal (old stories)", () => {
    expect(storyBodyFontClass(undefined)).toBe(storyBodyFontClass("normal"));
    expect(storyBodyFontClass("serif")).toBe(storyBodyFontClass("normal"));
  });
});

describe("overlay faces (app viewer_overlay_layer)", () => {
  it("sans is medium weight, handwritten is the handwriting face in italic, not serif", () => {
    expect(OVERLAY_FONT_CLASS["sans-serif"]).toContain("font-medium");
    expect(OVERLAY_FONT_CLASS.handwritten).toContain("font-hand");
    expect(OVERLAY_FONT_CLASS.handwritten).toContain("italic");
    expect(OVERLAY_FONT_CLASS.handwritten).not.toContain("font-serif");
    expect(OVERLAY_FONT_CLASS.bold).toContain("font-bold");
    expect(OVERLAY_FONT_CLASS.serif).toContain("font-serif");
  });

  it("does not force every overlay to semibold", () => {
    render(
      <StoryCanvas
        story={{
          ...textStory("normal"),
          overlays: [
            { type: "text", content: "hi", x: 0.5, y: 0.5, scale: 1, color: "#FFFFFF", fontStyle: "sans-serif", bgMode: "none" },
          ],
        }}
      />
    );
    expect(screen.getByTestId("story-overlay-0").className.split(" ")).not.toContain("font-semibold");
  });
});
