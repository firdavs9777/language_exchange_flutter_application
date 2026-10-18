import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import GatheringForm from "./GatheringForm";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "", i18n: { language: "en" } }) }));
jest.mock("../../design/notify", () => ({ __esModule: true, default: { success: jest.fn(), error: jest.fn() } }));

const mockCreate = jest.fn();
const mockUpdate = jest.fn();
let mockQuery: any = { data: undefined, isLoading: false, isError: false };
jest.mock("../../store/slices/gatheringsSlice", () => {
  const actual = jest.requireActual("../../store/slices/gatheringsSlice");
  return {
    GATHERING_TOPICS: actual.GATHERING_TOPICS,
    GATHERING_LEVELS: actual.GATHERING_LEVELS,
    gatheringEditBody: actual.gatheringEditBody,
    useCreateGatheringMutation: () => [mockCreate, { isLoading: false }],
    useUpdateGatheringMutation: () => [mockUpdate, { isLoading: false }],
    useGetGatheringQuery: () => mockQuery,
  };
});
jest.mock("../../store/slices/communitySlice", () => ({ useGetLanguagesQuery: () => ({ data: { data: [] } }) }));
jest.mock("../community/lib/languageOptions", () => ({
  languageOptions: () => [
    { value: "Korean", label: "Korean" },
    { value: "Japanese", label: "Japanese" },
  ],
}));

function Where() {
  const l = useLocation();
  return <div data-testid="where">{l.pathname}</div>;
}
function renderForm(path: string, mode: "create" | "edit") {
  const store = configureStore({
    reducer: { auth: (s: any = { userInfo: { user: { _id: "me", language_to_learn: "Korean" } } }) => s },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Routes>
          <Route path="/gatherings/new" element={<GatheringForm mode="create" />} />
          <Route path="/gatherings/:id/edit" element={<GatheringForm mode="edit" />} />
          <Route path="/gatherings/:id" element={<Where />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}
const type = (id: string, value: string) => fireEvent.change(screen.getByTestId(id), { target: { value } });
/** A datetime-local value n days from now at 19:30 (inside the 90-day window). */
function inDays(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() + n);
  const p = (x: number) => (x < 10 ? `0${x}` : String(x));
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T19:30`;
}

beforeEach(() => {
  mockCreate.mockReset();
  mockUpdate.mockReset();
  mockQuery = { data: undefined, isLoading: false, isError: false };
});

it("prefills like the app and creates, sending startsAt as UTC and the club from ?club=", async () => {
  mockCreate.mockReturnValue({ unwrap: () => Promise.resolve({ _id: "g9" }) });
  renderForm("/gatherings/new?club=c1", "create");
  expect((screen.getByTestId("gf-language") as HTMLSelectElement).value).toBe("Korean");
  expect((screen.getByTestId("gf-capacity") as HTMLInputElement).value).toBe("6");
  type("gf-title", "  Korean coffee chat  ");
  const when = inDays(2);
  type("gf-starts-at", when);
  fireEvent.change(screen.getByTestId("gf-topic"), { target: { value: "conversation" } });
  fireEvent.click(screen.getByTestId("gf-join-approval"));
  fireEvent.click(screen.getByTestId("gf-submit"));
  await waitFor(() => expect(mockCreate).toHaveBeenCalled());
  expect(mockCreate.mock.calls[0][0]).toEqual({
    title: "Korean coffee chat",
    language: "Korean",
    startsAt: new Date(when).toISOString(),
    description: "",
    durationMinutes: 60,
    capacity: 6,
    quorum: 3,
    joinMode: "approval",
    topic: "conversation",
    club: "c1",
  });
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/gatherings/g9"));
});

it("shows field errors and does not submit", () => {
  renderForm("/gatherings/new", "create");
  type("gf-title", "");
  fireEvent.click(screen.getByTestId("gf-submit"));
  expect(screen.getByTestId("gf-error-title")).toHaveTextContent("Give your gathering a title.");
  expect(mockCreate).not.toHaveBeenCalled();
});

it("clamps quorum when capacity drops below it", () => {
  renderForm("/gatherings/new", "create");
  type("gf-quorum", "5");
  type("gf-capacity", "4");
  expect((screen.getByTestId("gf-quorum") as HTMLInputElement).value).toBe("4");
});

it("shows the server's refusal inside the form", async () => {
  mockCreate.mockReturnValue({
    unwrap: () =>
      Promise.reject({ status: 403, data: { error: "You have cancelled or missed too many of your own gatherings to host a new one" } }),
  });
  renderForm("/gatherings/new", "create");
  type("gf-title", "Chat");
  type("gf-starts-at", inDays(2));
  fireEvent.click(screen.getByTestId("gf-submit"));
  await waitFor(() =>
    expect(screen.getByTestId("gf-server-error")).toHaveTextContent("too many of your gatherings were cancelled or missed")
  );
});

const existing = {
  _id: "g1",
  title: "Old title",
  description: "desc",
  language: "korean",
  languageLabel: "Korean",
  level: null,
  topic: "grammar",
  startsAt: "2030-11-01T10:00:00.000Z",
  durationMinutes: 60,
  capacity: 6,
  quorum: 3,
  joinMode: "open",
  status: "scheduled",
  going: 4,
  needed: 0,
  viewerIsHost: true,
  viewerIsAttending: true,
};

it("edits with only the changed fields and keeps quorum read-only", async () => {
  mockQuery = { data: existing, isLoading: false, isError: false };
  mockUpdate.mockReturnValue({ unwrap: () => Promise.resolve(existing) });
  renderForm("/gatherings/g1/edit", "edit");
  expect((screen.getByTestId("gf-title") as HTMLInputElement).value).toBe("Old title");
  expect(screen.getByTestId("gf-quorum")).toBeDisabled();
  type("gf-title", "New title");
  fireEvent.change(screen.getByTestId("gf-topic"), { target: { value: "" } });
  fireEvent.click(screen.getByTestId("gf-submit"));
  await waitFor(() => expect(mockUpdate).toHaveBeenCalledWith({ id: "g1", body: { title: "New title", topic: null } }));
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/gatherings/g1"));
});

it("refuses a capacity below the people already going, before asking the server", () => {
  mockQuery = { data: existing, isLoading: false, isError: false };
  renderForm("/gatherings/g1/edit", "edit");
  type("gf-capacity", "3");
  fireEvent.click(screen.getByTestId("gf-submit"));
  expect(screen.getByTestId("gf-error-capacity")).toHaveTextContent("4");
  expect(mockUpdate).not.toHaveBeenCalled();
});

it("saving with no change just goes back", async () => {
  mockQuery = { data: existing, isLoading: false, isError: false };
  renderForm("/gatherings/g1/edit", "edit");
  fireEvent.click(screen.getByTestId("gf-submit"));
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/gatherings/g1"));
  expect(mockUpdate).not.toHaveBeenCalled();
});

it("only the host can edit", () => {
  mockQuery = { data: { ...existing, viewerIsHost: false }, isLoading: false, isError: false };
  renderForm("/gatherings/g1/edit", "edit");
  expect(screen.getByTestId("gf-not-host")).toBeInTheDocument();
  expect(screen.queryByTestId("gathering-form")).not.toBeInTheDocument();
});
