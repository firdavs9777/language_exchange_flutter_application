import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import CityPage from "./CityPage";
import { COUNTRY_PINS } from "./countryPins";

const mockArgs: any[] = [];
let mockResult: any = { data: { data: [] }, isLoading: false, isError: false, isFetching: false };
jest.mock("../../../store/slices/communitySlice", () => ({
  useGetCommunityMembersQuery: (arg: any, opts: any) => {
    mockArgs.push({ arg, opts });
    return opts && opts.skip ? { data: undefined, isLoading: false } : mockResult;
  },
}));
jest.mock("../MemberCard", () => (p: any) => <div data-testid={`member-${p.user._id}`}>{p.user.name}</div>);
jest.mock("../WaveSheet", () => () => null);
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderPage() {
  const store = configureStore({
    reducer: { auth: (s: any = { userInfo: { user: { _id: "me", native_language: "English", language_to_learn: "Korean" } } }) => s },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <CityPage />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockArgs.length = 0;
  mockResult = { data: { data: [] }, isLoading: false, isError: false, isFetching: false };
});

it("offers the app's 30 countries, in its order", () => {
  expect(COUNTRY_PINS).toHaveLength(30);
  expect(COUNTRY_PINS[0]).toEqual({ name: "South Korea", flag: "🇰🇷", iso: "KR" });
  expect(COUNTRY_PINS[29].name).toBe("Bangladesh");
  expect(COUNTRY_PINS.map((p) => p.name)).toContain("Uzbekistan");
  renderPage();
  expect(screen.getByTestId("city-country-South Korea")).toHaveTextContent("South Korea");
});

it("asks for nothing until a country or a city is chosen", () => {
  renderPage();
  expect(mockArgs.every((c) => c.opts && c.opts.skip)).toBe(true);
});

it("a country asks /auth/users with its English name and my languages", () => {
  mockResult = { data: { data: [{ _id: "u1", name: "Jisoo" }] }, isLoading: false, isError: false, isFetching: false };
  renderPage();
  fireEvent.click(screen.getByTestId("city-country-Japan"));
  const last = mockArgs[mockArgs.length - 1];
  expect(last.opts.skip).toBe(false);
  expect(last.arg).toEqual({
    page: 1,
    limit: 20,
    country: "Japan",
    nativeLanguage: "English",
    learningLanguage: "Korean",
    matchLanguage: "true",
  });
  expect(screen.getByTestId("member-u1")).toBeInTheDocument();
});

it("a typed city replaces the country and is sent as search, like the app", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("city-country-Japan"));
  fireEvent.change(screen.getByTestId("city-search"), { target: { value: " Busan " } });
  fireEvent.click(screen.getByTestId("city-search-go"));
  const last = mockArgs[mockArgs.length - 1].arg;
  expect(last.search).toBe("Busan");
  expect(last.country).toBeUndefined();
});

it("says so when no one is there", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("city-country-Nigeria"));
  expect(screen.getByTestId("city-empty")).toBeInTheDocument();
});
