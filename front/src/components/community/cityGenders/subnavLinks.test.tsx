import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { mockAppConfig } from "../../../utils/testing/mockWebFlags";
import CommunitySubNav from "../tandem/CommunitySubNav";

jest.mock("../../../store/slices/appConfigSlice", () => require("../../../utils/testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));

const nav = () =>
  render(
    <MemoryRouter>
      <CommunitySubNav activeTab="all" onTabChange={jest.fn()} searchValue="" onSearchChange={jest.fn()} onOpenFilters={jest.fn()} />
    </MemoryRouter>
  );

it("links City and Genders while the language-rooms flag is on", () => {
  mockAppConfig({ webLanguageRoomsEnabled: true, roomsEnabled: true });
  nav();
  expect(screen.getByTestId("subnav-city")).toHaveAttribute("href", "/community/city");
  expect(screen.getByTestId("subnav-genders")).toHaveAttribute("href", "/community/genders");
});

it.each([[{ webLanguageRoomsEnabled: false, roomsEnabled: true }], [{ webLanguageRoomsEnabled: true, roomsEnabled: false }], ["loading"], ["error"]])(
  "hides them for %j",
  (cfg: any) => {
    mockAppConfig(cfg);
    nav();
    expect(screen.queryByTestId("subnav-city")).not.toBeInTheDocument();
    expect(screen.queryByTestId("subnav-genders")).not.toBeInTheDocument();
  }
);
