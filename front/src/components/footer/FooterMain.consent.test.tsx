import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import FooterMain from "./FooterMain";
import { subscribeConsentManager } from "../../analytics/consent";

// The footer's own file (FooterMain.test.tsx) runs with the real, empty
// measurement id and asserts the control is absent. Here an id is present,
// which is the only state in which withdrawing consent means anything.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "" }),
  initReactI18next: { type: "3rdParty", init: () => {} },
}));
jest.mock("../../analytics/ga", () => ({ GA_MEASUREMENT_ID: "G-TEST", loadGa: jest.fn(), gaEvent: jest.fn() }));

it("offers Privacy choices and opens the consent manager", () => {
  let opened = 0;
  const off = subscribeConsentManager(() => { opened += 1; });
  render(<MemoryRouter><FooterMain /></MemoryRouter>);

  const button = screen.getByText("Privacy choices");
  expect(button).toBeInTheDocument();
  fireEvent.click(button);
  expect(opened).toBe(1);
  off();
});
