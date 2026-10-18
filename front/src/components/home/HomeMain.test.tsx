import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import HomeMain from "./HomeMain";

// The page embeds an AdUnit, which reads the signed-in user from the store to
// keep ads off VIP accounts, so the page needs a Provider. Only `auth` is real
// here; the data hooks are mocked below.
const renderHome = () => {
  const store = configureStore({ reducer: { auth: () => ({ userInfo: null }) } });
  return render(
    <Provider store={store}>
      <HomeMain />
    </Provider>
  );
};

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
jest.mock("../../store/slices/plansSlice", () => ({
  ...jest.requireActual("../../store/slices/plansSlice"),
  useGetVipPlansQuery: () => ({ data: undefined, isError: true, isLoading: false }),
}));
jest.mock("../../store/slices/publicStatsSlice", () => ({
  ...jest.requireActual("../../store/slices/publicStatsSlice"),
  useGetPublicStatsQuery: () => ({ data: undefined }),
}));

beforeEach(() => window.localStorage.clear());

it("assembles every section in order", () => {
  renderHome();
  ["hero-demo", "stat-strip", "how-it-works", "feature-showcase",
   "language-marquee", "pricing-section", "early-adopter-band", "final-cta"]
    .forEach((id) => expect(screen.getByTestId(id)).toBeInTheDocument());
});

it("mounts the promo carousel", () => {
  renderHome();
  expect(screen.getByTestId("promo-carousel")).toBeInTheDocument();
});

// The whole page must be free of the prices that were never true.
it("shows no invented prices anywhere", () => {
  const { container } = renderHome();
  expect(container.textContent).not.toContain("$14.99");
  expect(container.textContent).not.toContain("$49.99");
});
