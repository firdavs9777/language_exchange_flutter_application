import React from "react";
import { render, screen } from "@testing-library/react";
import HighlightStoryViewer from "./HighlightStoryViewer";
import "@testing-library/jest-dom";
import { act } from "react-dom/test-utils";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const highlight = {
  _id: "h1",
  title: "Seoul",
  stories: [
    { _id: "s1", mediaType: "text", text: "First story", backgroundColor: "#000" },
    { _id: "s2", mediaType: "text", text: "Second story", backgroundColor: "#000" },
  ],
};

it("steps through the highlight with the arrow keys", () => {
  render(<HighlightStoryViewer highlight={highlight} onClose={jest.fn()} />);
  expect(screen.getByText("First story")).toBeInTheDocument();
  act(() => { window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight" })); });
  expect(screen.getByText("Second story")).toBeInTheDocument();
  act(() => { window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowLeft" })); });
  expect(screen.getByText("First story")).toBeInTheDocument();
});

it("closes when stepping past the last story", () => {
  const onClose = jest.fn();
  render(<HighlightStoryViewer highlight={{ ...highlight, stories: [highlight.stories[0]] }} onClose={onClose} />);
  act(() => { window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight" })); });
  expect(onClose).toHaveBeenCalledTimes(1);
});

it("shows the current story's place under the title", () => {
  render(
    <HighlightStoryViewer
      highlight={{
        ...highlight,
        stories: [{ ...highlight.stories[0], location: { name: "Busan" } }, highlight.stories[1]],
      }}
      onClose={jest.fn()}
    />
  );
  expect(screen.getByTestId("highlight-story-location")).toHaveTextContent("Busan");
  act(() => { window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight" })); });
  expect(screen.queryByTestId("highlight-story-location")).toBeNull();
});
