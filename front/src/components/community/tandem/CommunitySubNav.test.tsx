import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import CommunitySubNav, { CommunityNavTab } from "./CommunitySubNav";
jest.mock("../../../utils/webFlags", () => ({ useWebFlag: () => false, useWebFlagState: () => ({ on: false, ready: true }) }));

// `t` returns the key, so every assertion below is about behaviour and
// structure rather than about copy (the copy lives in the locale files).
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => key }),
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

function renderNav(props: Partial<React.ComponentProps<typeof CommunitySubNav>> = {}) {
  const onTabChange = jest.fn();
  const onOpenFilters = jest.fn();
  const onSearchChange = jest.fn();
  const utils = render(
    <MemoryRouter>
      <CommunitySubNav
        activeTab={"all" as CommunityNavTab}
        onTabChange={onTabChange}
        searchValue=""
        onSearchChange={onSearchChange}
        onOpenFilters={onOpenFilters}
        {...props}
      />
    </MemoryRouter>
  );
  return { ...utils, onTabChange, onOpenFilters, onSearchChange };
}

describe("the community sub-nav", () => {
  it("offers the five in-page tabs inside one tablist, in app order", () => {
    renderNav();

    const tabs = screen.getAllByRole("tab");
    expect(tabs.map((tab) => tab.textContent)).toEqual([
      "communityMain.tabs.forYou",
      "communityMain.tabs.all",
      "communityMain.tabs.serious",
      "communityMain.tabs.online",
      "communityMain.tabs.new",
    ]);
  });

  it("marks only the active tab as selected", () => {
    renderNav({ activeTab: "online" as CommunityNavTab });

    const selected = screen
      .getAllByRole("tab")
      .filter((tab) => tab.getAttribute("aria-selected") === "true");
    expect(selected).toHaveLength(1);
    expect(selected[0]).toHaveTextContent("communityMain.tabs.online");
  });

  it("hands an in-page tab back to the page instead of navigating", () => {
    const { onTabChange } = renderNav();

    fireEvent.click(screen.getByText("communityMain.tabs.forYou"));
    expect(onTabChange).toHaveBeenCalledWith("foryou");

    fireEvent.click(screen.getByText("communityMain.tabs.new"));
    expect(onTabChange).toHaveBeenLastCalledWith("new");
  });

  // Nearby and Topics are whole pages of their own. As links they can be
  // opened in a new tab, middle-clicked and read correctly by a screen reader
  // -- none of which a button pretending to be a tab can do.
  it("sends Nearby and Topics to their own routes as real links", () => {
    renderNav();

    expect(screen.getByText("communityMain.subnav.nearby").closest("a")).toHaveAttribute(
      "href",
      "/community/nearby"
    );
    expect(screen.getByText("communityMain.subnav.topics").closest("a")).toHaveAttribute(
      "href",
      "/topics"
    );
    // ...and they are not tabs.
    expect(screen.getAllByRole("tab")).toHaveLength(5);
  });

  // A page you are leaving should not first rewrite the URL you are leaving:
  // stamping `?tab=nearby` onto /communities on the way out means Back drops
  // you on the list with a tab nobody chose instead of the one you were on.
  it("writes no tab state on the way to Nearby or Topics", () => {
    const { onTabChange } = renderNav({ activeTab: "online" as CommunityNavTab });

    fireEvent.click(screen.getByText("communityMain.subnav.nearby"));
    fireEvent.click(screen.getByText("communityMain.subnav.topics"));

    expect(onTabChange).not.toHaveBeenCalled();
  });

  it("keeps the six destinations on one scrollable line for a phone", () => {
    const { container } = renderNav();

    const scroller = container.querySelector(".community-subnav__container > div");
    expect(scroller?.className).toContain("overflow-x-auto");
    expect(scroller?.className).toContain("flex-nowrap");
  });

  it("pulls the active tab back into view when it changes", () => {
    const scrollIntoView = jest.fn();
    (window as any).HTMLElement.prototype.scrollIntoView = scrollIntoView;

    const { rerender } = renderNav({ activeTab: "all" as CommunityNavTab });
    scrollIntoView.mockClear();

    rerender(
      <MemoryRouter>
        <CommunitySubNav
          activeTab={"new" as CommunityNavTab}
          onTabChange={jest.fn()}
          searchValue=""
          onSearchChange={jest.fn()}
          onOpenFilters={jest.fn()}
        />
      </MemoryRouter>
    );

    expect(scrollIntoView).toHaveBeenCalled();
    delete (window as any).HTMLElement.prototype.scrollIntoView;
  });

  it("still opens the filter sheet and reports the search box", () => {
    const { onOpenFilters, onSearchChange } = renderNav({ activeFilterCount: 2 });

    fireEvent.click(screen.getByLabelText("communityMain.subnav.filtersWithCount"));
    expect(onOpenFilters).toHaveBeenCalled();

    fireEvent.change(screen.getByPlaceholderText("communityMain.subnav.searchPlaceholder"), {
      target: { value: "anna" },
    });
    expect(onSearchChange).toHaveBeenCalledWith("anna");
  });

  // "For you" is the server's answer, not a query the member can edit.
  it("hides the filter button when the page says there is nothing to filter", () => {
    renderNav({ showFilterButton: false });

    expect(screen.queryByLabelText("communityMain.subnav.filtersLabel")).not.toBeInTheDocument();
  });

  it("shows a visitors pill with the count", () => {
    renderNav({ visitorsCount: 12 });
    const pill = screen.getByTestId("subnav-visitors");
    expect(pill).toHaveTextContent("12");
    expect(pill).toHaveAttribute("href", "/visitors");
    expect(pill).toHaveAccessibleName();
  });

  it("shows no pill when nobody has visited", () => {
    renderNav({ visitorsCount: 0 });
    expect(screen.queryByTestId("subnav-visitors")).not.toBeInTheDocument();
  });

  it("shows no pill when the count is absent", () => {
    renderNav({});
    expect(screen.queryByTestId("subnav-visitors")).not.toBeInTheDocument();
  });
});
