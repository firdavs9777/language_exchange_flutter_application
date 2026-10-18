import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import MessageSearchDialog from "./MessageSearchDialog";

const mockSearch = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../../store/slices/chatSlice", () => ({
  useSearchMessagesQuery: (arg: any, opts: any) => mockSearch(arg, opts),
}));

const onClose = jest.fn();
const onJump = jest.fn();

function renderDialog() {
  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user: { _id: "me" }, token: "t" } }) => state },
  });
  return render(
    <Provider store={store}>
      <MessageSearchDialog partnerId="u2" partnerName="Ada" onClose={onClose} onJump={onJump} debounceMs={0} />
    </Provider>
  );
}

const lastArgs = () => mockSearch.mock.calls[mockSearch.mock.calls.length - 1];

beforeEach(() => {
  mockSearch.mockReturnValue({ data: undefined, isFetching: false, isError: false });
});
afterEach(() => jest.clearAllMocks());

it("does not search until two characters are typed", () => {
  renderDialog();
  expect(lastArgs()[1]).toEqual(expect.objectContaining({ skip: true }));
  expect(screen.getByText("Type at least 2 characters")).toBeInTheDocument();
});

it("searches this conversation only, by the other person's id", async () => {
  renderDialog();
  fireEvent.change(screen.getByTestId("chat-search-input"), { target: { value: "  market " } });
  await waitFor(() =>
    expect(lastArgs()).toEqual([
      { query: "market", conversationId: "u2", limit: 30 },
      expect.objectContaining({ skip: false }),
    ])
  );
});

it("lists results with who said it, and jumps to the one picked", async () => {
  mockSearch.mockReturnValue({
    data: {
      data: [
        { _id: "m1", message: "See you at the market", createdAt: "2026-09-20T10:00:00.000Z", sender: { _id: "u2", name: "Ada" } },
        { _id: "m2", message: "Which market?", createdAt: "2026-09-20T10:01:00.000Z", sender: "me" },
      ],
    },
    isFetching: false,
    isError: false,
  });
  renderDialog();
  fireEvent.change(screen.getByTestId("chat-search-input"), { target: { value: "market" } });

  const first = await screen.findByTestId("chat-search-result-m1");
  expect(first).toHaveTextContent("Ada");
  expect(first).toHaveTextContent("See you at the market");
  expect(screen.getByTestId("chat-search-result-m2")).toHaveTextContent("You");

  fireEvent.click(first);
  expect(onJump).toHaveBeenCalledWith("m1");
});

it("says when nothing matched", async () => {
  mockSearch.mockReturnValue({ data: { data: [] }, isFetching: false, isError: false });
  renderDialog();
  fireEvent.change(screen.getByTestId("chat-search-input"), { target: { value: "zebra" } });
  expect(await screen.findByText("No messages found")).toBeInTheDocument();
});

it("says when search itself failed (500, rate limit)", async () => {
  mockSearch.mockReturnValue({ data: undefined, isFetching: false, isError: true });
  renderDialog();
  fireEvent.change(screen.getByTestId("chat-search-input"), { target: { value: "zebra" } });
  expect(await screen.findByText("Search isn't available right now")).toBeInTheDocument();
});
