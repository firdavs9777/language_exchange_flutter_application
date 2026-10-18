import { renderHook } from "@testing-library/react";
import { useTargetLanguage } from "./useTargetLanguage";

let mockLanguage = "en";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (k: string) => k,
    i18n: { language: mockLanguage, changeLanguage: jest.fn() },
  }),
}));

describe("useTargetLanguage", () => {
  afterEach(() => {
    mockLanguage = "en";
  });

  it("returns 'en' for the English UI language", () => {
    mockLanguage = "en";
    const { result } = renderHook(() => useTargetLanguage());
    expect(result.current).toBe("en");
  });

  it("returns 'ko' for the Korean UI language (i18n resource key for kor.json)", () => {
    mockLanguage = "ko";
    const { result } = renderHook(() => useTargetLanguage());
    expect(result.current).toBe("ko");
  });

  it("returns 'zh' for the underscore-spelled zh_TW resource key (backend has no zh-TW)", () => {
    mockLanguage = "zh_TW";
    const { result } = renderHook(() => useTargetLanguage());
    expect(result.current).toBe("zh");
  });

  it("returns 'zh' for the hyphen spelling too, not 'zh-TW' (unsupported by the backend's translation validator/service)", () => {
    mockLanguage = "zh-TW";
    const { result } = renderHook(() => useTargetLanguage());
    expect(result.current).toBe("zh");
  });

  it("returns bare 'zh' for Simplified Chinese", () => {
    mockLanguage = "zh";
    const { result } = renderHook(() => useTargetLanguage());
    expect(result.current).toBe("zh");
  });

  // Since the locale split dropped `load: "languageOnly"`, i18n.language is no
  // longer guaranteed to be a bare code: a browser reporting "ko-KR" leaves it
  // spelled that way while the bundle in force is "ko". The request body still
  // has to carry a bare ISO 639-1 code.
  it("returns 'ko' for a region code like 'ko-KR'", () => {
    mockLanguage = "ko-KR";
    const { result } = renderHook(() => useTargetLanguage());
    expect(result.current).toBe("ko");
  });

  it("returns 'en' for 'en-US'", () => {
    mockLanguage = "en-US";
    const { result } = renderHook(() => useTargetLanguage());
    expect(result.current).toBe("en");
  });

  it("falls back to 'en' for an unmappable/empty language", () => {
    mockLanguage = "";
    const { result } = renderHook(() => useTargetLanguage());
    expect(result.current).toBe("en");
  });
});
