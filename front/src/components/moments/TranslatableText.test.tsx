import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import TranslatableText from "./TranslatableText";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const ORIGINAL = "안녕하세요! 오늘 시간 있어요?";
const TRANSLATED = "Hi! Do you have time today?";

const setup = (props: any = {}) => {
  const onTranslate =
    props.onTranslate ||
    jest.fn().mockResolvedValue({ translatedText: TRANSLATED });
  const onRequireLogin = props.onRequireLogin || jest.fn();
  render(
    <TranslatableText
      text={props.text || ORIGINAL}
      fullText={props.fullText}
      onTranslate={onTranslate}
      isLoggedIn={props.isLoggedIn !== false}
      onRequireLogin={onRequireLogin}
      className={props.className}
      as={props.as}
    />
  );
  return { onTranslate, onRequireLogin };
};

describe("TranslatableText", () => {
  it("renders the original text as a button-like control", () => {
    setup();
    const control = screen.getByTestId("translatable-text");
    expect(control).toHaveTextContent(ORIGINAL);
    expect(control).toHaveAttribute("role", "button");
    expect(control).toHaveAttribute("tabindex", "0");
    expect(control).toHaveAttribute("aria-expanded", "false");
    expect(control).toHaveAttribute("aria-label", "Tap to translate");
  });

  it("toggles the translated line and only translates once across show/hide/show", async () => {
    const { onTranslate } = setup();
    const control = screen.getByTestId("translatable-text");

    fireEvent.click(control);
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        TRANSLATED
      )
    );
    expect(control).toHaveAttribute("aria-expanded", "true");

    // Second tap hides the line.
    fireEvent.click(control);
    expect(
      screen.queryByTestId("translatable-translation")
    ).not.toBeInTheDocument();
    expect(control).toHaveAttribute("aria-expanded", "false");

    // Third tap shows the cached result without refetching.
    fireEvent.click(control);
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        TRANSLATED
      )
    );
    expect(onTranslate).toHaveBeenCalledTimes(1);
  });

  it("shows a loading line first, then the translation", async () => {
    let resolveIt: (value: { translatedText: string }) => void = () => {};
    const onTranslate = jest.fn(
      () =>
        new Promise<{ translatedText: string }>((resolve) => {
          resolveIt = resolve;
        })
    );
    setup({ onTranslate });

    fireEvent.click(screen.getByTestId("translatable-text"));
    expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
      "Translating…"
    );

    resolveIt({ translatedText: TRANSLATED });
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        TRANSLATED
      )
    );
  });

  it("shows an inline error and retries on the next tap", async () => {
    const onTranslate = jest
      .fn()
      .mockRejectedValueOnce(new Error("boom"))
      .mockResolvedValueOnce({ translatedText: TRANSLATED });
    setup({ onTranslate });

    fireEvent.click(screen.getByTestId("translatable-text"));
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        "Couldn't translate. Tap to retry."
      )
    );

    fireEvent.click(screen.getByTestId("translatable-retry"));
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        TRANSLATED
      )
    );
    expect(onTranslate).toHaveBeenCalledTimes(2);
  });

  it("says the text is already in your language when nothing changed", async () => {
    const onTranslate = jest
      .fn()
      .mockResolvedValue({ translatedText: `  ${ORIGINAL} ` });
    setup({ onTranslate });

    fireEvent.click(screen.getByTestId("translatable-text"));
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        "Already in your language"
      )
    );
  });

  // The feed card renders a 200-character preview while the server translates
  // the whole moment, so the same-language check has to compare against the
  // untruncated body.
  it("compares against fullText, so a truncated same-language body is recognised", async () => {
    const full = `${ORIGINAL} 그리고 더 긴 이야기가 이어집니다.`;
    const onTranslate = jest.fn().mockResolvedValue({ translatedText: full });
    setup({ text: `${ORIGINAL}...`, fullText: full, onTranslate });

    fireEvent.click(screen.getByTestId("translatable-text"));
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        "Already in your language"
      )
    );
  });

  it("still recognises a match on the rendered preview when fullText is given", async () => {
    const onTranslate = jest.fn().mockResolvedValue({ translatedText: ORIGINAL });
    setup({ text: ORIGINAL, fullText: `${ORIGINAL} plus a tail`, onTranslate });

    fireEvent.click(screen.getByTestId("translatable-text"));
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        "Already in your language"
      )
    );
  });

  it("shows the translation when fullText differs from what came back", async () => {
    const onTranslate = jest
      .fn()
      .mockResolvedValue({ translatedText: TRANSLATED });
    setup({ text: `${ORIGINAL}...`, fullText: `${ORIGINAL} more`, onTranslate });

    fireEvent.click(screen.getByTestId("translatable-text"));
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        TRANSLATED
      )
    );
  });

  it("without fullText, compares against the rendered text as before", async () => {
    const onTranslate = jest
      .fn()
      .mockResolvedValue({ translatedText: `${ORIGINAL} and a longer tail` });
    setup({ text: ORIGINAL, onTranslate });

    fireEvent.click(screen.getByTestId("translatable-text"));
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        "and a longer tail"
      )
    );
  });

  it("asks a logged-out visitor to sign in and never translates", () => {
    const { onTranslate, onRequireLogin } = setup({ isLoggedIn: false });

    fireEvent.click(screen.getByTestId("translatable-text"));

    expect(onRequireLogin).toHaveBeenCalledTimes(1);
    expect(onTranslate).not.toHaveBeenCalled();
    expect(
      screen.queryByTestId("translatable-translation")
    ).not.toBeInTheDocument();
  });

  it("toggles with the Enter key", async () => {
    const { onTranslate } = setup();
    const control = screen.getByTestId("translatable-text");

    fireEvent.keyDown(control, { key: "Enter" });
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        TRANSLATED
      )
    );

    fireEvent.keyDown(control, { key: "Enter" });
    expect(
      screen.queryByTestId("translatable-translation")
    ).not.toBeInTheDocument();
    expect(onTranslate).toHaveBeenCalledTimes(1);
  });

  it("toggles with the Space key", async () => {
    setup();
    fireEvent.keyDown(screen.getByTestId("translatable-text"), { key: " " });
    await waitFor(() =>
      expect(screen.getByTestId("translatable-translation")).toHaveTextContent(
        TRANSLATED
      )
    );
  });

  it("renders the original text on the server (prerender safety)", () => {
    const html = renderToString(
      <TranslatableText
        text={ORIGINAL}
        onTranslate={jest.fn()}
        isLoggedIn={false}
        onRequireLogin={jest.fn()}
      />
    );
    expect(html).toContain(ORIGINAL);
  });
});
