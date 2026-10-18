import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import ProfileLanguages, { hasLanguages } from "./ProfileLanguages";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

it("renders the exchange pill for a native and a learning language", () => {
  render(
    <ProfileLanguages
      user={{ native_language: "Korean", language_to_learn: "English" }}
    />
  );
  expect(screen.getByTestId("profile-languages")).toBeInTheDocument();
  expect(screen.getByTestId("language-pill")).toBeInTheDocument();
  expect(screen.getByTestId("language-pill-native")).toHaveTextContent("KO");
  expect(screen.getByTestId("language-pill-learning")).toHaveTextContent("EN");
});

it("names both languages in full beside the pill", () => {
  render(
    <ProfileLanguages
      user={{ native_language: "Korean", language_to_learn: "English" }}
    />
  );
  expect(screen.getByTestId("language-native")).toHaveTextContent("Korean");
  expect(screen.getByTestId("language-learning")).toHaveTextContent("English");
});

it("shows the CEFR level and its dots when the profile has one", () => {
  render(
    <ProfileLanguages
      user={{
        native_language: "Korean",
        language_to_learn: "English",
        languageLevel: "B2",
      }}
    />
  );
  expect(screen.getByTestId("language-level")).toHaveTextContent("B2");
  expect(screen.getAllByTestId("language-pill-dot")).toHaveLength(3);
});

it("renders no level and no dots when the level is unknown", () => {
  render(
    <ProfileLanguages
      user={{ native_language: "Korean", language_to_learn: "English" }}
    />
  );
  expect(screen.queryByTestId("language-level")).not.toBeInTheDocument();
  expect(screen.queryAllByTestId("language-pill-dot")).toHaveLength(0);
});

it("renders the pill from the native side alone", () => {
  render(<ProfileLanguages user={{ native_language: "Korean" }} />);
  expect(screen.getByTestId("profile-languages")).toBeInTheDocument();
  expect(screen.queryByTestId("language-learning")).not.toBeInTheDocument();
});

it("lists extra learning languages as strings", () => {
  render(
    <ProfileLanguages
      user={{
        native_language: "Korean",
        language_to_learn: "English",
        learningLanguages: ["Japanese", "Spanish"],
      }}
    />
  );
  const extras = screen.getAllByTestId("language-extra");
  expect(extras).toHaveLength(2);
  expect(extras[0]).toHaveTextContent("Japanese");
  expect(extras[1]).toHaveTextContent("Spanish");
});

it("lists extra learning languages given as objects, with their level", () => {
  render(
    <ProfileLanguages
      user={{
        native_language: "Korean",
        language_to_learn: "English",
        learningLanguages: [{ language: "Japanese", level: "A2" }],
      }}
    />
  );
  expect(screen.getByTestId("language-extra")).toHaveTextContent("Japanese");
  expect(screen.getByTestId("language-extra")).toHaveTextContent("A2");
});

it("does not repeat the primary learning language among the extras", () => {
  render(
    <ProfileLanguages
      user={{
        native_language: "Korean",
        language_to_learn: "English",
        learningLanguages: ["english", "Japanese"],
      }}
    />
  );
  expect(screen.getAllByTestId("language-extra")).toHaveLength(1);
  expect(screen.getByTestId("language-extra")).toHaveTextContent("Japanese");
});

it("renders nothing when the profile has no languages", () => {
  const { container } = render(<ProfileLanguages user={{}} />);
  expect(container).toBeEmptyDOMElement();
});

it("renders nothing without a user", () => {
  const { container } = render(<ProfileLanguages />);
  expect(container).toBeEmptyDOMElement();
});


// The page draws one card around all four info sections and asks each whether
// it has anything BEFORE drawing, because a parent cannot see that a child
// returned null. These pin the predicate to the component's own rendering.
describe("hasLanguages", () => {
  const cases: Array<[string, any, boolean]> = [
    ["nothing", {}, false],
    ["a native language", { native_language: "English" }, true],
    ["a learning language", { language_to_learn: "Korean" }, true],
    ["both", { native_language: "English", language_to_learn: "Korean" }, true],
    ["whitespace only", { native_language: "  ", language_to_learn: " " }, false],
  ];

  cases.forEach(([label, user, expected]) => {
    it(`agrees with the component for ${label}`, () => {
      expect(hasLanguages(user)).toBe(expected);
      const { container } = render(<ProfileLanguages user={user} />);
      expect(container.firstChild === null).toBe(!expected);
    });
  });

  it("drops its own card in bare mode", () => {
    const { container } = render(
      <ProfileLanguages user={{ native_language: "English" }} bare />
    );
    expect(container.querySelector("[data-testid='surface-card']")).toBeNull();
  });
});
