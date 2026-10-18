import React from "react";
import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import QuestionResponsesSheet from "./QuestionResponsesSheet";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

let mockResponsesState: any = { data: undefined, isLoading: true, error: undefined };
jest.mock("../../store/slices/storiesSlice", () => ({
  useGetQuestionResponsesQuery: () => mockResponsesState,
}));

const NOW = new Date("2026-09-24T12:00:00Z").getTime();

const renderSheet = (onClose = jest.fn()) => {
  render(
    <MemoryRouter>
      <QuestionResponsesSheet storyId="story-1" onClose={onClose} />
    </MemoryRouter>
  );
  return onClose;
};

beforeEach(() => {
  jest.spyOn(Date, "now").mockReturnValue(NOW);
  mockResponsesState = { data: undefined, isLoading: true, error: undefined };
});

afterEach(() => jest.restoreAllMocks());

describe("QuestionResponsesSheet", () => {
  it("shows a loading state while the request is in flight", () => {
    renderSheet();
    expect(screen.getByTestId("story-responses-loading")).toBeInTheDocument();
  });

  it("shows the prompt and every answer", () => {
    mockResponsesState = {
      isLoading: false,
      error: undefined,
      data: {
        success: true,
        data: {
          prompt: "Ask me anything",
          responses: [
            {
              user: { _id: "u-1", name: "Mina", images: ["https://cdn/m.jpg"] },
              text: "What's your favourite city?",
              respondedAt: "2026-09-24T11:30:00Z",
              isAnonymous: false,
            },
          ],
        },
      },
    };
    renderSheet();

    expect(screen.getByTestId("story-responses-prompt")).toHaveTextContent(
      "Ask me anything"
    );
    expect(screen.getAllByTestId("story-response-row")).toHaveLength(1);
    expect(screen.getByText("What's your favourite city?")).toBeInTheDocument();
    expect(screen.getByText("Mina")).toBeInTheDocument();
    expect(screen.getByText("30m ago")).toBeInTheDocument();
  });

  it("links a named respondent to their profile", () => {
    mockResponsesState = {
      isLoading: false,
      error: undefined,
      data: {
        success: true,
        data: {
          prompt: "Ask me anything",
          responses: [
            {
              user: { _id: "u-1", name: "Mina" },
              text: "Hi",
              respondedAt: "2026-09-24T11:59:00Z",
              isAnonymous: false,
            },
          ],
        },
      },
    };
    renderSheet();
    expect(screen.getByTestId("story-response-author")).toHaveAttribute(
      "href",
      "/community/u-1"
    );
  });

  it("masks an anonymous answer: no name, no avatar image, no profile link", () => {
    mockResponsesState = {
      isLoading: false,
      error: undefined,
      data: {
        success: true,
        data: {
          prompt: "Ask me anything",
          responses: [
            {
              // The backend still populates `user` for an anonymous answer;
              // the sheet must not leak it.
              user: { _id: "u-7", name: "Secret Sam", images: ["https://cdn/s.jpg"] },
              text: "Do you like kimchi?",
              respondedAt: "2026-09-24T11:59:00Z",
              isAnonymous: true,
            },
          ],
        },
      },
    };
    renderSheet();

    expect(screen.getByText("Do you like kimchi?")).toBeInTheDocument();
    expect(screen.getByText("Anonymous")).toBeInTheDocument();
    expect(screen.queryByText("Secret Sam")).not.toBeInTheDocument();
    expect(screen.queryByTestId("story-response-author")).not.toBeInTheDocument();
    expect(screen.queryByTestId("avatar-image")).not.toBeInTheDocument();
  });

  it("shows an empty state when nobody has answered", () => {
    mockResponsesState = {
      isLoading: false,
      error: undefined,
      data: { success: true, data: { prompt: "Ask me anything", responses: [] } },
    };
    renderSheet();
    expect(screen.getByTestId("story-responses-empty")).toBeInTheDocument();
  });

  it("shows an error state when the request fails", () => {
    mockResponsesState = { isLoading: false, error: { status: 403 }, data: undefined };
    renderSheet();
    expect(screen.getByTestId("story-responses-error")).toBeInTheDocument();
  });

  it("closes from its own close button", () => {
    mockResponsesState = {
      isLoading: false,
      error: undefined,
      data: { success: true, data: { prompt: "", responses: [] } },
    };
    const onClose = renderSheet();
    screen.getByTestId("story-responses-close").click();
    expect(onClose).toHaveBeenCalled();
  });
});
