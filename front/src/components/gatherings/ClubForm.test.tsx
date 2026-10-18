import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import ClubForm from "./ClubForm";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
const mockCreate = jest.fn();
const mockUpdate = jest.fn();
let mockQuery: any = { data: undefined, isLoading: false, isError: false };
jest.mock("../../store/slices/gatheringsSlice", () => ({
  useCreateClubMutation: () => [mockCreate, { isLoading: false }],
  useUpdateClubMutation: () => [mockUpdate, { isLoading: false }],
  useGetClubQuery: () => mockQuery,
}));
jest.mock("../../store/slices/communitySlice", () => ({ useGetLanguagesQuery: () => ({ data: { data: [] } }) }));
jest.mock("../community/lib/languageOptions", () => ({
  languageOptions: () => [{ value: "Korean", label: "Korean" }],
}));

function Where() {
  return <div data-testid="where">{useLocation().pathname}</div>;
}
function renderForm(path: string) {
  const store = configureStore({ reducer: { auth: (s: any = { userInfo: { user: { _id: "me", language_to_learn: "Korean" } } }) => s } });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Routes>
          <Route path="/clubs/new" element={<ClubForm mode="create" />} />
          <Route path="/clubs/:id/edit" element={<ClubForm mode="edit" />} />
          <Route path="/clubs/:id" element={<Where />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}
const type = (id: string, value: string) => fireEvent.change(screen.getByTestId(id), { target: { value } });

beforeEach(() => {
  mockCreate.mockReset();
  mockUpdate.mockReset();
  mockQuery = { data: undefined, isLoading: false, isError: false };
});

it("creates a club with the app's four fields and opens it", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.resolve({ _id: "c9" }) });
  renderForm("/clubs/new");
  expect(screen.queryByTestId("cf-city")).not.toBeInTheDocument();
  type("cf-name", "  Seoul readers ");
  type("cf-description", "Books");
  type("cf-interest", "books");
  fireEvent.click(screen.getByTestId("cf-submit"));
  await waitFor(() =>
    expect(mockCreate).toHaveBeenCalledWith({ name: "Seoul readers", description: "Books", language: "Korean", interest: "books" })
  );
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/clubs/c9"));
});

it("requires a name (<= 80) and a language; interest <= 60", () => {
  renderForm("/clubs/new");
  fireEvent.click(screen.getByTestId("cf-submit"));
  expect(screen.getByTestId("cf-error-name")).toHaveTextContent("Give your club a name.");
  type("cf-name", "x".repeat(81));
  type("cf-interest", "y".repeat(61));
  fireEvent.change(screen.getByTestId("cf-language"), { target: { value: "" } });
  fireEvent.click(screen.getByTestId("cf-submit"));
  expect(screen.getByTestId("cf-error-name")).toHaveTextContent("80");
  expect(screen.getByTestId("cf-error-interest")).toHaveTextContent("60");
  expect(screen.getByTestId("cf-error-language")).toBeInTheDocument();
  expect(mockCreate).not.toHaveBeenCalled();
});

const existing = {
  _id: "c1",
  name: "Seoul readers",
  description: "Books",
  language: "korean",
  languageLabel: "Korean",
  interest: "books",
  city: null,
  place: null,
  memberCount: 3,
  members: [],
  viewerCanManage: true,
  viewerIsMember: true,
  viewerIsOwner: true,
};

it("edits only what changed, with city and meeting place; language is shown but fixed", async () => {
  mockQuery = { data: existing, isLoading: false, isError: false };
  mockUpdate.mockReturnValue({ unwrap: () => Promise.resolve(existing) });
  renderForm("/clubs/c1/edit");
  expect(screen.getByTestId("cf-language")).toBeDisabled();
  type("cf-city", "Seoul");
  type("cf-place-name", "Cafe Ink");
  fireEvent.click(screen.getByTestId("cf-submit"));
  await waitFor(() =>
    expect(mockUpdate).toHaveBeenCalledWith({ id: "c1", body: { city: "Seoul", place: { name: "Cafe Ink", address: null } } })
  );
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/clubs/c1"));
});

it("clearing the city sends null", async () => {
  mockQuery = { data: { ...existing, city: "Seoul" }, isLoading: false, isError: false };
  mockUpdate.mockReturnValue({ unwrap: () => Promise.resolve(existing) });
  renderForm("/clubs/c1/edit");
  type("cf-city", "");
  fireEvent.click(screen.getByTestId("cf-submit"));
  await waitFor(() => expect(mockUpdate).toHaveBeenCalledWith({ id: "c1", body: { city: null } }));
});

it("only the owner or an organizer can edit", () => {
  mockQuery = { data: { ...existing, viewerCanManage: false }, isLoading: false, isError: false };
  renderForm("/clubs/c1/edit");
  expect(screen.getByTestId("cf-not-allowed")).toBeInTheDocument();
});

it("shows a server refusal in the form", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.reject({ status: "FETCH_ERROR" }) });
  renderForm("/clubs/new");
  type("cf-name", "Club");
  fireEvent.click(screen.getByTestId("cf-submit"));
  await waitFor(() => expect(screen.getByTestId("cf-server-error")).toHaveTextContent("You're offline"));
});
