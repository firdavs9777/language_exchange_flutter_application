import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import ActiveFilterChips from "./ActiveFilterChips";
import { CommunityFilters } from "./lib/buildCommunityQuery";

function renderChips(
  value: CommunityFilters,
  topicLabels?: Record<string, string>
) {
  const onRemove = jest.fn();
  const onClear = jest.fn();
  const utils = render(
    <ActiveFilterChips
      value={value}
      onRemove={onRemove}
      onClear={onClear}
      topicLabels={topicLabels}
    />
  );
  return { ...utils, onRemove, onClear };
}

describe("the active filter chips", () => {
  // The row is the member's receipt for what they asked for. Nothing to show
  // means nothing on screen -- not an empty strip of padding.
  it("renders nothing when no filter is set", () => {
    const { container } = renderChips({});
    expect(container).toBeEmptyDOMElement();
  });

  it("shows a chip for every filter that is actually narrowing the list", () => {
    renderChips({
      minAge: 25,
      maxAge: 40,
      gender: "female",
      nativeLanguage: "Korean",
      learningLanguage: "English",
      country: "South Korea",
      languageLevel: "B2",
      topicsAtLeast: 3,
      onlineOnly: true,
      newUsersOnly: true,
      search: "anna",
    });

    expect(screen.getByText("Min age: 25")).toBeInTheDocument();
    expect(screen.getByText("Max age: 40")).toBeInTheDocument();
    expect(screen.getByText("Gender: female")).toBeInTheDocument();
    expect(screen.getByText("Native: Korean")).toBeInTheDocument();
    expect(screen.getByText("Learning: English")).toBeInTheDocument();
    expect(screen.getByText("Country: South Korea")).toBeInTheDocument();
    expect(screen.getByText("Level: B2")).toBeInTheDocument();
    expect(screen.getByText("Shared topics ≥ 3")).toBeInTheDocument();
    expect(screen.getByText("Online now")).toBeInTheDocument();
    expect(screen.getByText("New users only")).toBeInTheDocument();
    expect(screen.getByText("Search: anna")).toBeInTheDocument();
  });

  // The defaults are the whole population: an 18-100 age range is not a
  // filter, and showing it as one would mean the row is never empty.
  it("says nothing about an age range that excludes nobody", () => {
    const { container } = renderChips({ minAge: 18, maxAge: 100 });
    expect(container).toBeEmptyDOMElement();
  });

  it("names topics by their label, and removes one at a time", () => {
    const { onRemove } = renderChips(
      { topics: ["t1", "t2"] },
      { t1: "Music", t2: "Travel" }
    );

    expect(screen.getByText("Topic: Music")).toBeInTheDocument();
    fireEvent.click(screen.getByText("Topic: Travel"));
    expect(onRemove).toHaveBeenCalledWith("topics", "t2");
  });

  it("falls back to the topic id when no label has arrived yet", () => {
    renderChips({ topics: ["t9"] });
    expect(screen.getByText("Topic: t9")).toBeInTheDocument();
  });

  it("removes exactly the filter whose chip was tapped", () => {
    const { onRemove } = renderChips({ gender: "male", country: "Japan" });

    fireEvent.click(screen.getByText("Country: Japan"));
    expect(onRemove).toHaveBeenCalledTimes(1);
    expect(onRemove).toHaveBeenCalledWith("country", undefined);
  });

  it("offers one way out of all of them", () => {
    const { onClear } = renderChips({ gender: "male" });

    fireEvent.click(screen.getByText("Clear"));
    expect(onClear).toHaveBeenCalled();
  });
});
