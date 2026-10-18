import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import MutualInterests, { sharedTopics, hasMutualInterests } from "./MutualInterests";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

it("keeps only the topics both people picked", () => {
  expect(
    sharedTopics({ topics: ["music", "travel", "food"] }, { topics: ["Travel", "hiking", "music"] })
  ).toEqual(["Travel", "music"]);
});

it("reads the object shape a populated topic list uses", () => {
  expect(sharedTopics({ topics: [{ id: "music" }] }, { topics: [{ name: "Music" }] })).toEqual([
    "Music",
  ]);
});

it("renders a chip per shared topic with the count", () => {
  render(
    <MutualInterests
      viewer={{ topics: ["music", "travel"] }}
      user={{ topics: ["travel", "music", "cooking"] }}
    />
  );
  expect(screen.getByTestId("mutual-interests")).toHaveTextContent("2 in common");
  expect(screen.getAllByTestId("mutual-interest-chip")).toHaveLength(2);
});

it("renders nothing when nothing is shared", () => {
  const { container } = render(
    <MutualInterests viewer={{ topics: ["music"] }} user={{ topics: ["hiking"] }} />
  );
  expect(container).toBeEmptyDOMElement();
});

it("renders nothing when either side has no topics at all", () => {
  const { container } = render(<MutualInterests viewer={{ topics: [] }} user={{ topics: ["music"] }} />);
  expect(container).toBeEmptyDOMElement();
});

it("renders nothing to a signed-out visitor", () => {
  const { container } = render(<MutualInterests user={{ topics: ["music"] }} />);
  expect(container).toBeEmptyDOMElement();
});


// Same contract as the other three sections. This one reuses the `sharedTopics`
// selector the component already exported, so there is one rule, not two.
describe("hasMutualInterests", () => {
  const withTopics = (topics: string[]) => ({ topics });

  const cases: Array<[string, any, any, boolean]> = [
    ["no viewer", undefined, withTopics(["Film"]), false],
    ["nothing shared", withTopics(["Chess"]), withTopics(["Film"]), false],
    ["one shared", withTopics(["Film"]), withTopics(["Film"]), true],
    ["empty both sides", withTopics([]), withTopics([]), false],
  ];

  cases.forEach(([label, viewer, user, expected]) => {
    it(`agrees with the component for ${label}`, () => {
      expect(hasMutualInterests(viewer, user)).toBe(expected);
      const { container } = render(<MutualInterests viewer={viewer} user={user} />);
      expect(container.firstChild === null).toBe(!expected);
    });
  });

  it("drops its own card in bare mode", () => {
    const { container } = render(
      <MutualInterests viewer={withTopics(["Film"])} user={withTopics(["Film"])} bare />
    );
    expect(container.querySelector("[data-testid='surface-card']")).toBeNull();
  });
});
