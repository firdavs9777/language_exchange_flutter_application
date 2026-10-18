import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import QuickFilterChips from "./QuickFilterChips";
import { CommunityFilters } from "./lib/buildCommunityQuery";

// A miniature i18next: it answers from a dictionary and interpolates
// `{{language}}`, so the suite can tell "the chip asked for the right key with
// the right value" apart from "the chip pasted English together itself".
const DICT: Record<string, string> = {
  "communityMain.chips.recentlyActive": "Zuletzt aktiv",
  "communityMain.chips.onlineNow": "Jetzt online",
  "communityMain.chips.speaks": "Spricht {{language}}",
  "communityMain.chips.learning": "Lernt {{language}}",
};

let mockTranslate = true;

jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, options?: Record<string, any>) => {
      if (!mockTranslate) return "";
      const template = DICT[key];
      if (!template) return "";
      return template.replace(/\{\{(\w+)\}\}/g, (_match, name) =>
        String(options?.[name] ?? "")
      );
    },
  }),
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const ME = { native_language: "English", language_to_learn: "Korean" };

function renderChips(filters: CommunityFilters = {}, sort?: "recently_active") {
  const onChange = jest.fn();
  const onSortChange = jest.fn();
  const utils = render(
    <QuickFilterChips
      filters={filters}
      sort={sort}
      me={ME}
      onChange={onChange}
      onSortChange={onSortChange}
    />
  );
  return { ...utils, onChange, onSortChange };
}

beforeEach(() => {
  mockTranslate = true;
});

describe("the quick filter chips", () => {
  it("takes all four labels from the locale, not from the source", () => {
    renderChips();

    expect(screen.getByText("Zuletzt aktiv")).toBeInTheDocument();
    expect(screen.getByText("Jetzt online")).toBeInTheDocument();
    // The language name is interpolated, not concatenated: the word order
    // around it is not the same in every language.
    expect(screen.getByText("Spricht Korean")).toBeInTheDocument();
    expect(screen.getByText("Lernt English")).toBeInTheDocument();
  });

  it("falls back to English when a locale has nothing to say", () => {
    mockTranslate = false;
    renderChips();

    expect(screen.getByText("Recently active")).toBeInTheDocument();
    expect(screen.getByText("Online now")).toBeInTheDocument();
    expect(screen.getByText("Speaks Korean")).toBeInTheDocument();
    expect(screen.getByText("Learning English")).toBeInTheDocument();
  });

  it("toggles the sort rather than a filter for Recently active", () => {
    const { onSortChange, onChange } = renderChips();

    fireEvent.click(screen.getByText("Zuletzt aktiv"));
    expect(onSortChange).toHaveBeenCalledWith("recently_active");
    expect(onChange).not.toHaveBeenCalled();
  });

  it("turns the sort back off when it is already on", () => {
    const { onSortChange } = renderChips({}, "recently_active");

    fireEvent.click(screen.getByText("Zuletzt aktiv"));
    expect(onSortChange).toHaveBeenCalledWith(undefined);
  });

  it("toggles onlineOnly and keeps every other filter", () => {
    const { onChange } = renderChips({ gender: "female" });

    fireEvent.click(screen.getByText("Jetzt online"));
    expect(onChange).toHaveBeenCalledWith({ gender: "female", onlineOnly: true });
  });

  // The inverted mapping lives in buildCommunityQuery; here the chip only has
  // to put my learning language into `nativeLanguage` ("partner speaks it").
  it("maps Speaks to the partner's native language", () => {
    const { onChange } = renderChips();

    fireEvent.click(screen.getByText("Spricht Korean"));
    expect(onChange).toHaveBeenCalledWith({ nativeLanguage: "Korean" });
  });

  it("maps Learning to the partner's learning language", () => {
    const { onChange } = renderChips();

    fireEvent.click(screen.getByText("Lernt English"));
    expect(onChange).toHaveBeenCalledWith({ learningLanguage: "English" });
  });

  it("reflects the applied filters in aria-pressed", () => {
    renderChips({ onlineOnly: true, nativeLanguage: "Korean" });

    expect(screen.getByText("Jetzt online").closest("button")).toHaveAttribute(
      "aria-pressed",
      "true"
    );
    expect(screen.getByText("Spricht Korean").closest("button")).toHaveAttribute(
      "aria-pressed",
      "true"
    );
    expect(screen.getByText("Lernt English").closest("button")).toHaveAttribute(
      "aria-pressed",
      "false"
    );
  });

  it("drops the language chips for a member who has not set that language", () => {
    render(
      <QuickFilterChips
        filters={{}}
        me={{ native_language: "English" }}
        onChange={jest.fn()}
        onSortChange={jest.fn()}
      />
    );

    expect(screen.queryByText(/Spricht/)).not.toBeInTheDocument();
    expect(screen.getByText("Lernt English")).toBeInTheDocument();
  });
});
