import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import LanguageMatchCard, { matchTypeFor } from "./LanguageMatchCard";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const viewer = { native_language: "Korean", language_to_learn: "English" };

// One row per state of the app's MatchType enum
// (language_match_card.dart:9). Precedence matters as much as the mapping:
// a perfect pair must never be reported as a one-way pair.
const MATRIX: { type: string; target: any }[] = [
  { type: "perfect", target: { native_language: "English", language_to_learn: "Korean" } },
  { type: "youLearnTheirs", target: { native_language: "English", language_to_learn: "Spanish" } },
  { type: "theyLearnYours", target: { native_language: "French", language_to_learn: "Korean" } },
  { type: "sameNative", target: { native_language: "Korean", language_to_learn: "Japanese" } },
  { type: "none", target: { native_language: "French", language_to_learn: "Spanish" } },
];

describe("matchTypeFor", () => {
  MATRIX.forEach((row) => {
    it(`reads ${row.type} from the two language pairs`, () => {
      expect(matchTypeFor(viewer, row.target)).toBe(row.type);
    });
  });

  it("compares languages case-insensitively and ignores stray whitespace", () => {
    expect(
      matchTypeFor(
        { native_language: "korean", language_to_learn: "ENGLISH" },
        { native_language: "English", language_to_learn: "Korean" }
      )
    ).toBe("perfect");
    expect(
      matchTypeFor(
        { native_language: " Korean ", language_to_learn: "  English" },
        { native_language: "english ", language_to_learn: " korean" }
      )
    ).toBe("perfect");
  });

  it("never matches two profiles that left the field empty", () => {
    expect(matchTypeFor({ native_language: "", language_to_learn: "" }, { native_language: "", language_to_learn: "" })).toBe("none");
  });
});

describe("the card", () => {
  MATRIX.forEach((row) => {
    it(`marks the card ${row.type}`, () => {
      render(<LanguageMatchCard viewer={viewer} user={row.target} />);
      expect(screen.getByTestId("language-match-card")).toHaveAttribute("data-match", row.type);
    });
  });

  it("states the verdict for a perfect match", () => {
    render(<LanguageMatchCard viewer={viewer} user={MATRIX[0].target} />);
    expect(screen.getByTestId("language-match-message")).toHaveTextContent(
      "Perfect match — you can teach each other."
    );
  });

  it("says which language is the native one and which is being learnt", () => {
    render(<LanguageMatchCard viewer={viewer} user={MATRIX[0].target} />);
    expect(screen.getByTestId("language-match-native")).toHaveTextContent("Native");
    expect(screen.getByTestId("language-match-native")).toHaveTextContent("English");
    expect(screen.getByTestId("language-match-learning")).toHaveTextContent("Learning");
    expect(screen.getByTestId("language-match-learning")).toHaveTextContent("Korean");
  });

  it("shows the pair but no verdict when there is no match", () => {
    render(<LanguageMatchCard viewer={viewer} user={MATRIX[4].target} />);
    expect(screen.getByTestId("language-pill")).toBeInTheDocument();
    expect(screen.queryByTestId("language-match-message")).not.toBeInTheDocument();
  });

  it("renders nothing to a signed-out visitor", () => {
    const { container } = render(<LanguageMatchCard user={MATRIX[0].target} />);
    expect(container).toBeEmptyDOMElement();
  });

  it("renders nothing when the viewer has no languages of their own", () => {
    const { container } = render(
      <LanguageMatchCard viewer={{ _id: "me" }} user={MATRIX[0].target} />
    );
    expect(container).toBeEmptyDOMElement();
  });

  it("renders nothing when the profile is missing a language", () => {
    const { container } = render(
      <LanguageMatchCard viewer={viewer} user={{ native_language: "English" }} />
    );
    expect(container).toBeEmptyDOMElement();
  });
});
