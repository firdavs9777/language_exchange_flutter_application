import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import WallpaperPicker from "./WallpaperPicker";
import { CHAT_WALLPAPERS } from "../../design/chatWallpapers";

const mockSetTheme = jest.fn();
const mockNotifyError = jest.fn();
const mockNotifySuccess = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("../../store/slices/chatSlice", () => ({
  useSetConversationThemeMutation: () => [mockSetTheme, { isLoading: false }],
}));

jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: {
    success: (message: string) => mockNotifySuccess(message),
    error: (message: string) => mockNotifyError(message),
  },
}));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const rejected = () => ({
  unwrap: () => Promise.reject({ data: { message: "nope" } }),
});

const onClose = jest.fn();

function renderPicker(props: any = {}) {
  return render(
    <WallpaperPicker
      conversationId="c1"
      currentPreset="default"
      onClose={onClose}
      {...props}
    />
  );
}

beforeEach(() => {
  mockSetTheme.mockReturnValue(resolved());
});

describe("WallpaperPicker", () => {
  it("offers Default plus every free preset the app ships", () => {
    renderPicker();
    expect(screen.getByTestId("wallpaper-default")).toBeInTheDocument();
    CHAT_WALLPAPERS.forEach((wallpaper) => {
      expect(screen.getByTestId(`wallpaper-${wallpaper.name}`)).toBeInTheDocument();
    });
  });

  it("ships no coin-gated premium preset", () => {
    renderPicker();
    const premium = screen
      .getAllByTestId(/^wallpaper-/)
      .filter((el) => (el.getAttribute("data-testid") || "").indexOf("premium") !== -1);
    expect(premium).toEqual([]);
  });

  it("paints each swatch from the preset's own token, not an inline colour", () => {
    renderPicker();
    const swatch = screen.getByTestId("wallpaper-gradient_ocean");
    expect(swatch.querySelector(".chat-wallpaper-swatch")).toHaveAttribute(
      "data-chat-theme",
      "gradient_ocean"
    );
    expect(swatch.innerHTML).not.toMatch(/#[0-9a-fA-F]{3,8}/);
  });

  it("previews the chosen preset before it is saved", () => {
    renderPicker();
    expect(screen.getByTestId("wallpaper-preview")).toHaveAttribute(
      "data-chat-theme",
      "default"
    );
    fireEvent.click(screen.getByTestId("wallpaper-cream"));
    expect(screen.getByTestId("wallpaper-preview")).toHaveAttribute(
      "data-chat-theme",
      "cream"
    );
    expect(screen.getByTestId("wallpaper-cream")).toHaveAttribute(
      "aria-pressed",
      "true"
    );
    // Choosing is not saving.
    expect(mockSetTheme).not.toHaveBeenCalled();
  });

  it("saves the preset with the colours the app reads back", async () => {
    renderPicker();
    fireEvent.click(screen.getByTestId("wallpaper-gradient_sunset"));
    fireEvent.click(screen.getByTestId("wallpaper-apply"));

    await waitFor(() => expect(mockSetTheme).toHaveBeenCalled());
    expect(mockSetTheme).toHaveBeenCalledWith({
      conversationId: "c1",
      theme: {
        preset: "gradient_sunset",
        gradientColors: ["#ff512f", "#dd2476"],
      },
    });
    await waitFor(() => expect(onClose).toHaveBeenCalled());
  });

  it("clearing the wallpaper saves the bare default preset", async () => {
    renderPicker({ currentPreset: "cream" });
    fireEvent.click(screen.getByTestId("wallpaper-default"));
    fireEvent.click(screen.getByTestId("wallpaper-apply"));

    await waitFor(() => expect(mockSetTheme).toHaveBeenCalled());
    expect(mockSetTheme).toHaveBeenCalledWith({
      conversationId: "c1",
      theme: { preset: "default" },
    });
  });

  it("starts on the wallpaper the conversation already has", () => {
    renderPicker({ currentPreset: "navy" });
    expect(screen.getByTestId("wallpaper-navy")).toHaveAttribute(
      "aria-pressed",
      "true"
    );
    expect(screen.getByTestId("wallpaper-preview")).toHaveAttribute(
      "data-chat-theme",
      "navy"
    );
  });

  it("keeps the dialog open and says so when the save fails", async () => {
    mockSetTheme.mockReturnValue(rejected());
    renderPicker();
    fireEvent.click(screen.getByTestId("wallpaper-teal"));
    fireEvent.click(screen.getByTestId("wallpaper-apply"));

    await waitFor(() => expect(mockNotifyError).toHaveBeenCalled());
    expect(onClose).not.toHaveBeenCalled();
  });

  it("cannot save without a conversation to save it on", () => {
    renderPicker({ conversationId: "" });
    expect(screen.getByTestId("wallpaper-apply")).toBeDisabled();
  });

  it("says when the chat wears a Premium wallpaper chosen in the app", () => {
    renderPicker({ currentPreset: "premium_galaxy" });
    expect(screen.getByTestId("wallpaper-premium-hint")).toHaveTextContent("Premium wallpaper");
    expect(screen.getByTestId("wallpaper-preview")).toHaveAttribute("data-chat-theme", "premium_galaxy");
  });

  it("says nothing about premium for a free preset", () => {
    renderPicker({ currentPreset: "navy" });
    expect(screen.queryByTestId("wallpaper-premium-hint")).toBeNull();
  });
});
