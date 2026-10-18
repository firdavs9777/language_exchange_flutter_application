import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { HelmetProvider } from "react-helmet-async";
import LanguageCard from "./LanguageCard";

const mockProfile = jest.fn();
const mockShare = jest.fn();
const mockOpenInApp = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../store/slices/communitySlice", () => ({
  useGetPublicUserProfileQuery: (arg: any, opts: any) => mockProfile(arg, opts),
}));

jest.mock("../linking/shareContent", () => ({
  shareContent: (opts: any) => {
    mockShare(opts);
    return Promise.resolve();
  },
}));

jest.mock("../linking/openInAppAction", () => ({
  openInApp: (opts: any) => mockOpenInApp(opts),
}));

const ADA = {
  _id: "u2",
  name: "Ada",
  native_language: "Korean",
  language_to_learn: "English",
  languageLevel: "B1",
  imageUrls: ["https://cdn.test/a.jpg"],
  location: { country: "South Korea" },
  intents: ["learn", "meet"],
  topics: ["music", "travel", "food", "movies", "sports", "art", "books"],
  bio: "Coffee, cats and K-dramas.",
};

const loaded = (user: any) => ({ data: { success: true, data: user }, isLoading: false, error: undefined });

function renderCard(path = "/card/u2", viewerId: string | null = null) {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: viewerId ? { user: { _id: viewerId } } : null }) => state,
    },
  });
  render(
    <HelmetProvider>
      <Provider store={store}>
        <MemoryRouter initialEntries={[path]}>
          <Routes>
            <Route path="/card/:userId" element={<LanguageCard />} />
          </Routes>
        </MemoryRouter>
      </Provider>
    </HelmetProvider>
  );
}

beforeEach(() => {
  mockProfile.mockReturnValue(loaded(ADA));
});

describe("LanguageCard", () => {
  it("reads the PUBLIC profile, so it works for anyone with the link", () => {
    renderCard();
    expect(mockProfile).toHaveBeenCalledWith("u2", expect.objectContaining({ skip: false }));
  });

  it("shows who they are and what they trade", () => {
    renderCard();
    expect(screen.getByTestId("card-name")).toHaveTextContent("Ada");
    expect(screen.getByTestId("card-speaks")).toHaveTextContent("Korean");
    expect(screen.getByTestId("card-learning")).toHaveTextContent("English");
    expect(screen.getByTestId("card-level")).toHaveTextContent("B1");
    expect(screen.getByTestId("card-country")).toHaveTextContent("South Korea");
    expect(screen.getByTestId("card-bio")).toHaveTextContent("Coffee, cats and K-dramas.");
  });

  it("shows learn / meet, never dating", () => {
    mockProfile.mockReturnValue(loaded({ ...ADA, intents: ["learn", "date"] }));
    renderCard();
    expect(screen.getByTestId("card-intent-learn")).toBeInTheDocument();
    expect(screen.queryByTestId("card-intent-date")).not.toBeInTheDocument();
  });

  it("keeps the topics to a handful, so the card stays a card", () => {
    renderCard();
    expect(screen.getAllByTestId("card-topic")).toHaveLength(5);
  });

  it("leaves out what the profile does not have, rather than drawing empty rows", () => {
    mockProfile.mockReturnValue(
      loaded({ _id: "u2", name: "Ada", native_language: "Korean", language_to_learn: "English" })
    );
    renderCard();
    expect(screen.queryByTestId("card-level")).not.toBeInTheDocument();
    expect(screen.queryByTestId("card-country")).not.toBeInTheDocument();
    expect(screen.queryByTestId("card-bio")).not.toBeInTheDocument();
    expect(screen.queryByTestId("card-intents")).not.toBeInTheDocument();
    expect(screen.queryByTestId("card-topics")).not.toBeInTheDocument();
  });

  describe("what a stranger can do", () => {
    it("opens their profile in the app — the store on a phone without it", () => {
      renderCard("/card/u2", null);
      fireEvent.click(screen.getByTestId("card-cta-app"));
      expect(mockOpenInApp).toHaveBeenCalledWith(
        expect.objectContaining({ type: "profile", id: "u2" })
      );
    });

    it("can carry on in the browser instead", () => {
      renderCard("/card/u2", null);
      expect(screen.getByTestId("card-cta-web")).toHaveAttribute("href", "/community/u2");
    });
  });

  it("lets a signed-in member message them straight away", () => {
    renderCard("/card/u2", "me");
    expect(screen.getByTestId("card-cta-message")).toHaveAttribute("href", "/chat/u2");
    expect(screen.queryByTestId("card-cta-app")).not.toBeInTheDocument();
  });

  describe("your own card", () => {
    it("is shared as a card link, with an invitation as the text", () => {
      renderCard("/card/u2", "u2");
      fireEvent.click(screen.getByTestId("card-share"));
      expect(mockShare).toHaveBeenCalledWith(
        expect.objectContaining({ type: "card", id: "u2" })
      );
    });

    it("offers no message button to yourself", () => {
      renderCard("/card/u2", "u2");
      expect(screen.queryByTestId("card-cta-message")).not.toBeInTheDocument();
      expect(screen.getByTestId("card-edit")).toHaveAttribute("href", "/profile/edit");
    });
  });

  it("opens from a link that came back with the share text glued on", () => {
    // The exact link reported from production.
    renderCard("/card/6a7eb3d492fdab67baeed15f%20Practice%20English%20with%20me%20on%20BananaTalk");
    expect(mockProfile).toHaveBeenCalledWith(
      "6a7eb3d492fdab67baeed15f",
      expect.objectContaining({ skip: false })
    );
  });

  it("shows a skeleton while loading", () => {
    mockProfile.mockReturnValue({ data: undefined, isLoading: true, error: undefined });
    renderCard();
    expect(screen.getByTestId("card-loading")).toBeInTheDocument();
  });

  it("says so, and points somewhere useful, when the person is not there", () => {
    mockProfile.mockReturnValue({ data: undefined, isLoading: false, error: { status: 404 } });
    renderCard();
    expect(screen.getByTestId("card-missing")).toBeInTheDocument();
    expect(screen.getByTestId("card-missing-link")).toHaveAttribute("href", "/communities");
  });
});
