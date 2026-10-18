import "@testing-library/jest-dom";
import React, { useState } from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { makeStore } from "../../store";
import CommunityFilterSheet from "./CommunityFilterSheet";
import { CommunityFilters } from "./lib/buildCommunityQuery";
import { DEFAULT_FILTERS } from "./lib/filterStorage";

// `t` answers with nothing, so every control below is found by the English
// fallback the component ships -- which is also what a member sees in a locale
// that has not been translated yet.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "" }),
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const requestedUrls: string[] = [];
const originalFetch = global.fetch;

beforeEach(() => {
  requestedUrls.length = 0;
  (global as any).fetch = jest.fn((input: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    requestedUrls.push(url);
    const body = url.indexOf("/count") >= 0
      ? { success: true, data: { count: 7 } }
      : url.indexOf("/topics") >= 0
      ? { success: true, data: [{ _id: "t1", name: "Music" }, { _id: "t2", name: "Travel" }] }
      : { success: true, data: [] };
    return Promise.resolve(
      new Response(JSON.stringify(body), {
        status: 200,
        headers: { "content-type": "application/json" },
      })
    );
  });
});

afterEach(() => {
  global.fetch = originalFetch;
  jest.clearAllMocks();
});

const SIGNED_IN = {
  auth: {
    userInfo: {
      user: { _id: "u1", name: "Me", native_language: "English", language_to_learn: "Korean" },
      token: "t",
    },
  },
};

const countRequests = () => requestedUrls.filter((url) => url.indexOf("/count") >= 0);

function renderSheet(
  value: CommunityFilters = { ...DEFAULT_FILTERS },
  extra: Partial<React.ComponentProps<typeof CommunityFilterSheet>> = {}
) {
  const onChange = jest.fn();
  const onApply = jest.fn();
  const onClear = jest.fn();
  const onClose = jest.fn();
  const utils = render(
    <Provider store={makeStore(SIGNED_IN)}>
      <CommunityFilterSheet
        open
        value={value}
        onChange={onChange}
        onApply={onApply}
        onClear={onClear}
        onClose={onClose}
        isVip
        {...extra}
      />
    </Provider>
  );
  return { ...utils, onChange, onApply, onClear, onClose };
}

/** The sheet as the page drives it: a draft that actually changes. */
const Harness: React.FC<{ initial?: CommunityFilters }> = ({ initial = {} }) => {
  const [value, setValue] = useState<CommunityFilters>(initial);
  return (
    <CommunityFilterSheet
      open
      value={value}
      onChange={setValue}
      onApply={jest.fn()}
      onClear={jest.fn()}
      onClose={jest.fn()}
      isVip
    />
  );
};

const selects = (container: HTMLElement) =>
  Array.from(container.querySelectorAll("select"));

describe("the filter sheet's controls", () => {
  it("is not on the page at all when it is closed, and asks the server nothing", () => {
    const { container } = render(
      <Provider store={makeStore(SIGNED_IN)}>
        <CommunityFilterSheet
          open={false}
          value={{}}
          onChange={jest.fn()}
          onApply={jest.fn()}
          onClear={jest.fn()}
          onClose={jest.fn()}
        />
      </Provider>
    );
    expect(container).toBeEmptyDOMElement();
    expect(requestedUrls).toEqual([]);
  });


  it("turns on perfect partners (reciprocal)", () => {
    const { onChange } = renderSheet();
    fireEvent.click(screen.getByText("Perfect partners only"));
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ reciprocal: true }));
  });
  it("moves the minimum age", () => {
    const { onChange } = renderSheet();
    fireEvent.change(screen.getByLabelText("Minimum age"), { target: { value: "25" } });
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ minAge: 25 }));
  });

  it("moves the maximum age", () => {
    const { onChange } = renderSheet();
    fireEvent.change(screen.getByLabelText("Maximum age"), { target: { value: "40" } });
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ maxAge: 40 }));
  });

  // The two handles share a track: dragging one past the other would invert
  // the range, so each is clamped by the other.
  it("will not let the minimum cross the maximum", () => {
    const { onChange } = renderSheet({ minAge: 18, maxAge: 30 });
    fireEvent.change(screen.getByLabelText("Minimum age"), { target: { value: "55" } });
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ minAge: 30 }));
  });

  it("picks a gender, and unsets it again with Any", () => {
    const { onChange } = renderSheet();
    fireEvent.click(screen.getByRole("button", { name: "Female" }));
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ gender: "female" }));

    onChange.mockClear();
    // Two sections offer an "Any": gender first, then the CEFR level.
    fireEvent.click(screen.getAllByRole("button", { name: "Any" })[0]);
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ gender: undefined }));
  });

  it("sets the partner's native language from the first select", () => {
    const { container, onChange } = renderSheet();
    fireEvent.change(selects(container)[0], { target: { value: "Korean" } });
    expect(onChange).toHaveBeenCalledWith(
      expect.objectContaining({ nativeLanguage: "Korean" })
    );
  });

  it("sets the language the partner is learning from the second select", () => {
    const { container, onChange } = renderSheet();
    fireEvent.change(selects(container)[1], { target: { value: "English" } });
    expect(onChange).toHaveBeenCalledWith(
      expect.objectContaining({ learningLanguage: "English" })
    );
  });

  // A list, not a text box: free text was matched by substring, so "Korea"
  // found both Koreas and "Niger" found Nigeria.
  it("picks the country from a list of real countries", () => {
    const { onChange } = renderSheet();
    const select = screen.getByTestId("filter-country") as HTMLSelectElement;
    expect(select.tagName).toBe("SELECT");
    expect(Array.from(select.options).some((o) => o.value === "North Korea")).toBe(true);

    fireEvent.change(select, { target: { value: "Japan" } });
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ country: "Japan" }));
  });

  // "Any" is no country filter at all, not `country=""`.
  it("drops the country filter on Any", () => {
    const { onChange } = renderSheet({ country: "Japan" });
    fireEvent.change(screen.getByTestId("filter-country"), { target: { value: "" } });
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ country: undefined }));
  });

  // A link or saved filter from the text-box days can carry a value the list
  // does not have. It stays selected and visible rather than silently
  // reading as "Any" while still filtering.
  it("keeps a country typed before the list existed", () => {
    renderSheet({ country: "Korea" });
    const select = screen.getByTestId("filter-country") as HTMLSelectElement;
    expect(select.value).toBe("Korea");
  });

  it("sets a CEFR level and takes it off again", () => {
    const { onChange } = renderSheet();
    fireEvent.click(screen.getByRole("button", { name: "B2" }));
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ languageLevel: "B2" }));

    onChange.mockClear();
    fireEvent.click(screen.getAllByRole("button", { name: "Any" })[1]);
    expect(onChange).toHaveBeenCalledWith(
      expect.objectContaining({ languageLevel: undefined })
    );
  });

  it("adds and removes topics by name", async () => {
    const { container } = render(
      <Provider store={makeStore(SIGNED_IN)}>
        <Harness />
      </Provider>
    );

    fireEvent.click(await screen.findByRole("button", { name: "Music" }));
    fireEvent.click(screen.getByRole("button", { name: "Travel" }));
    // Both selected: tapping Music again must leave Travel alone.
    fireEvent.click(screen.getByRole("button", { name: "Music" }));

    const selected = Array.from(container.querySelectorAll("button"))
      .filter((button) => /bg-teal-500/.test(button.className))
      .map((button) => button.textContent);
    expect(selected).toContain("Travel");
    expect(selected).not.toContain("Music");
  });

  it("asks for a minimum number of mutual interests", () => {
    const { onChange } = renderSheet();
    fireEvent.change(screen.getByLabelText("Mutual interests"), { target: { value: "3" } });
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ topicsAtLeast: 3 }));
  });

  it("flips the two toggles onto the right filters", () => {
    const { onChange } = renderSheet();

    fireEvent.click(screen.getByText("Online now"));
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ onlineOnly: true }));

    onChange.mockClear();
    fireEvent.click(screen.getByText("New users only"));
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ newUsersOnly: true }));
  });

  it("hands the draft up on Apply", () => {
    const value = { gender: "male", onlineOnly: true };
    const { onApply } = renderSheet(value);

    fireEvent.click(screen.getByRole("button", { name: "Apply" }));
    expect(onApply).toHaveBeenCalledWith(value);
  });

  // "Clear all" has two jobs: empty the sheet on screen AND tell the page, so
  // the list behind it stops filtering too.
  it("resets the draft and the page on Clear all", () => {
    const { onChange, onClear } = renderSheet({ gender: "male", country: "Japan" });

    fireEvent.click(screen.getByRole("button", { name: "Clear all" }));
    expect(onChange).toHaveBeenCalledWith({ ...DEFAULT_FILTERS });
    expect(onClear).toHaveBeenCalled();
  });
});

describe("the filter sheet's live count", () => {
  it("counts the matches for the filters it opened with", async () => {
    renderSheet({ gender: "female", onlineOnly: true });

    expect(await screen.findByText("7 matches")).toBeInTheDocument();
    expect(countRequests()[0]).toContain("gender=female");
    expect(countRequests()[0]).toContain("onlineOnly=true");
  });

  // Quick changes in a row must not each become a request.
  it("waits for the editing to settle before counting again", async () => {
    render(
      <Provider store={makeStore(SIGNED_IN)}>
        <Harness />
      </Provider>
    );
    await waitFor(() => expect(countRequests().length).toBe(1));

    const select = screen.getByTestId("filter-country");
    fireEvent.change(select, { target: { value: "Jamaica" } });
    fireEvent.change(select, { target: { value: "Jordan" } });
    fireEvent.change(select, { target: { value: "Japan" } });

    await waitFor(() => expect(countRequests().length).toBe(2));
    expect(countRequests()[1]).toContain("country=Japan");
  });
});

describe("the filter sheet's Copy link", () => {
  it("is absent when the page cannot produce a link", () => {
    renderSheet();
    expect(screen.queryByRole("button", { name: "Copy link" })).not.toBeInTheDocument();
  });

  it("copies the link when the sheet shows what the list shows", () => {
    const onCopyLink = jest.fn();
    renderSheet({ gender: "male" }, { onCopyLink, canCopyLink: true });

    fireEvent.click(screen.getByRole("button", { name: "Copy link" }));
    expect(onCopyLink).toHaveBeenCalled();
  });

  // A link describes a list. While the draft is unapplied there is no such
  // list, so the button says what to do instead of copying a URL that opens
  // something other than what the member is looking at.
  it("refuses to copy an unapplied draft, and says why", () => {
    const onCopyLink = jest.fn();
    renderSheet({ gender: "male" }, { onCopyLink, canCopyLink: false });

    const button = screen.getByRole("button", { name: "Apply filters first" });
    expect(button).toBeDisabled();
    fireEvent.click(button);
    expect(onCopyLink).not.toHaveBeenCalled();
    expect(screen.queryByRole("button", { name: "Copy link" })).not.toBeInTheDocument();
  });
});

// On Online and New the tab holds one of these switches down. A switch the
// member can flip, only for the tab to flip it back the moment they press
// Apply, is a dead control -- so it is disabled and says who owns it, and the
// count is measured with the lock in place so the number matches the list
// they would actually get.
describe("the filter sheet under a tab lock", () => {
  it("has no lock and no hint on All", () => {
    renderSheet();
    expect(screen.queryByTestId("filter-sheet-online-locked")).not.toBeInTheDocument();
    expect(screen.queryByTestId("filter-sheet-new-locked")).not.toBeInTheDocument();
    expect(screen.getByRole("switch", { name: /Online now/ })).not.toBeDisabled();
  });

  it("disables the Online switch and says which tab set it", () => {
    const { onChange } = renderSheet({ ...DEFAULT_FILTERS }, { lockedTab: "online" });

    const toggle = screen.getByRole("switch", { name: /Online now/ });
    expect(toggle).toBeDisabled();
    expect(toggle).toHaveAttribute("aria-checked", "true");
    expect(screen.getByTestId("filter-sheet-online-locked")).toHaveTextContent(
      "Set by the Online tab"
    );

    fireEvent.click(toggle);
    expect(onChange).not.toHaveBeenCalled();

    // The other switch is still the member's to set.
    expect(screen.getByRole("switch", { name: /New users only/ })).not.toBeDisabled();
    expect(screen.queryByTestId("filter-sheet-new-locked")).not.toBeInTheDocument();
  });

  it("disables the New switch on the New tab", () => {
    renderSheet({ ...DEFAULT_FILTERS }, { lockedTab: "new" });

    const toggle = screen.getByRole("switch", { name: /New users only/ });
    expect(toggle).toBeDisabled();
    expect(toggle).toHaveAttribute("aria-checked", "true");
    expect(screen.getByTestId("filter-sheet-new-locked")).toHaveTextContent(
      "Set by the New tab"
    );
    expect(screen.getByRole("switch", { name: /Online now/ })).not.toBeDisabled();
  });

  // The count has to answer the question the list is being asked, lock and all.
  it("counts with the tab's lock applied even when the draft does not carry it", async () => {
    renderSheet({ gender: "female" }, { lockedTab: "online" });

    expect(await screen.findByText("7 matches")).toBeInTheDocument();
    expect(countRequests()[0]).toContain("onlineOnly=true");
    expect(countRequests()[0]).toContain("gender=female");
  });
});

describe("languages come from the catalog (community#4)", () => {
  const CATALOG = [
    { code: "en", name: "English", nativeName: "English" },
    { code: "ko", name: "Korean", nativeName: "한국어" },
    { code: "uz", name: "Uzbek", nativeName: "Oʻzbek" },
    { code: "ar", name: "Arabic", nativeName: "العربية" },
    { code: "ar-EG", name: "Arabic (Egypt)", nativeName: "العربية (مصر)" },
  ];

  beforeEach(() => {
    const previous = (global as any).fetch;
    (global as any).fetch = jest.fn((input: any) => {
      const url = typeof input === "string" ? input : input?.url || "";
      if (/\/api\/v1\/languages(\?|$)/.test(url)) {
        requestedUrls.push(url);
        return Promise.resolve(
          new Response(JSON.stringify({ success: true, data: CATALOG }), {
            status: 200,
            headers: { "content-type": "application/json" },
          })
        );
      }
      return previous(input);
    });
  });

  const optionValues = (select: Element) =>
    Array.from(select.querySelectorAll("option")).map((o) => (o as HTMLOptionElement).value);

  it("offers Uzbek and one Arabic, sending the English name", async () => {
    const { container, onChange } = renderSheet();
    await waitFor(() => expect(optionValues(selects(container)[0])).toContain("Uzbek"));
    expect(optionValues(selects(container)[0]).filter((v) => v === "Arabic")).toHaveLength(1);
    expect(optionValues(selects(container)[0])).not.toContain("Arabic (Egypt)");
    fireEvent.change(selects(container)[0], { target: { value: "Uzbek" } });
    expect(onChange).toHaveBeenCalledWith(expect.objectContaining({ nativeLanguage: "Uzbek" }));
  });

  it("keeps a value from an old link that the catalog no longer lists", async () => {
    const { container } = renderSheet({ ...DEFAULT_FILTERS, learningLanguage: "Klingon" });
    await waitFor(() => expect(optionValues(selects(container)[1])).toContain("Uzbek"));
    expect(optionValues(selects(container)[1])).toContain("Klingon");
  });
});

describe("the country filter is VIP-only", () => {
  it("is locked behind a VIP badge for a free member and leaves the count", async () => {
    const onUpgrade = jest.fn();
    renderSheet({ country: "Japan", gender: "female" }, { isVip: false, onUpgrade });
    const select = screen.getByTestId("filter-country") as HTMLSelectElement;
    expect(select).toBeDisabled();
    expect(select.value).toBe("");
    expect(screen.getAllByText("Country filter is a VIP feature").length).toBeGreaterThan(0);
    fireEvent.click(screen.getByTestId("filter-country-vip"));
    expect(onUpgrade).toHaveBeenCalled();
    await waitFor(() => expect(countRequests().length).toBe(1));
    expect(countRequests()[0]).toContain("gender=female");
    expect(countRequests()[0]).not.toContain("country=");
  });

  it("is a normal picker for VIP", () => {
    renderSheet({ country: "Japan" });
    expect(screen.getByTestId("filter-country")).not.toBeDisabled();
    expect(screen.queryByTestId("filter-country-vip")).not.toBeInTheDocument();
  });
});
