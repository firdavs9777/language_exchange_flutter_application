import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter } from "react-router-dom";
import GendersPage from "./GendersPage";

const mockArgs: any[] = [];
const mockCountArgs: any[] = [];
jest.mock("../../../store/slices/communitySlice", () => ({
  useGetCommunityMembersQuery: (arg: any) => {
    mockArgs.push(arg);
    return { data: { data: [{ _id: `u-${arg.gender}`, name: arg.gender }] }, isLoading: false, isError: false, isFetching: false };
  },
  useGetCommunityCountQuery: (params: any) => {
    mockCountArgs.push(params);
    return { data: { data: { count: params.gender === "male" ? 120 : 340 } } };
  },
}));
jest.mock("../MemberCard", () => (p: any) => <div data-testid={`member-${p.user._id}`}>{p.user.name}</div>);
jest.mock("../WaveSheet", () => () => null);
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

function renderPage(user: any = { _id: "me", native_language: "English", language_to_learn: "Korean" }) {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter>
        <GendersPage />
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  mockArgs.length = 0;
  mockCountArgs.length = 0;
});

it("starts on women, like the app, with my languages matched", () => {
  renderPage();
  expect(mockArgs[mockArgs.length - 1]).toEqual({
    page: 1,
    limit: 20,
    gender: "female",
    nativeLanguage: "English",
    learningLanguage: "Korean",
    matchLanguage: "true",
  });
  expect(screen.getByTestId("member-u-female")).toBeInTheDocument();
});

it("shows both counts from the count endpoint with the same filter", () => {
  renderPage();
  expect(screen.getByTestId("genders-count-female")).toHaveTextContent("340");
  expect(screen.getByTestId("genders-count-male")).toHaveTextContent("120");
  expect(mockCountArgs).toContainEqual({ gender: "male", nativeLanguage: "English", learningLanguage: "Korean", matchLanguage: "true" });
});

it("switches to men", () => {
  renderPage();
  fireEvent.click(screen.getByTestId("genders-male"));
  expect(mockArgs[mockArgs.length - 1].gender).toBe("male");
  expect(screen.getByTestId("member-u-male")).toBeInTheDocument();
});

it("without languages on my profile, asks by gender alone", () => {
  renderPage({ _id: "me" });
  expect(mockArgs[mockArgs.length - 1]).toEqual({ page: 1, limit: 20, gender: "female" });
});
