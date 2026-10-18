import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import NewChat from "./NewChat";

const mockNavigate = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("../../store/slices/usersSlice", () => ({
  useSearchUsersQuery: (_arg: any, opts: any) =>
    opts && opts.skip
      ? { data: undefined, isLoading: false }
      : { data: { data: [{ _id: "u2", name: "Ada", imageUrls: [] }] }, isLoading: false },
  useSearchUsersByUsernameQuery: () => ({ data: undefined, isLoading: false }),
  useGetUserByIdQuery: () => ({ data: undefined, isLoading: false }),
}));

afterEach(() => jest.clearAllMocks());

it("opens /chat/<userId> for the picked person and creates nothing", () => {
  render(
    <MemoryRouter>
      <NewChat />
    </MemoryRouter>
  );
  fireEvent.change(screen.getByRole("textbox"), { target: { value: "Ada" } });
  fireEvent.click(screen.getByText("Ada"));
  expect(mockNavigate).toHaveBeenCalledWith("/chat/u2");
});
