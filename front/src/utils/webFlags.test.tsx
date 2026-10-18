import "@testing-library/jest-dom";
import React from "react";
import { render, screen } from "@testing-library/react";
import { mockAppConfig, appConfigCalls } from "./testing/mockWebFlags";
import { useWebFlagState, isWebFlagOn, WEB_FLAG_REQUIRES } from "./webFlags";

jest.mock("../store/slices/appConfigSlice", () => require("./testing/mockWebFlags").appConfigSliceMock());
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "ko" } }),
}));

function Probe({ flag }: { flag: any }) {
  const s = useWebFlagState(flag);
  return <span data-testid="state">{`${s.on}/${s.ready}`}</span>;
}
const state = () => screen.getByTestId("state").textContent;

beforeEach(() => {
  appConfigCalls.length = 0;
});

it("is off and not ready while app-config loads", () => {
  mockAppConfig("loading");
  render(<Probe flag="webCallsEnabled" />);
  expect(state()).toBe("false/false");
});

it("is off and ready when app-config failed (everything stays hidden)", () => {
  mockAppConfig("error");
  render(<Probe flag="webCallsEnabled" />);
  expect(state()).toBe("false/true");
});

it("is off when the flag is missing (an older backend) or false", () => {
  mockAppConfig({});
  render(<Probe flag="webVoiceRoomsEnabled" />);
  expect(state()).toBe("false/true");
});

it("is on only for a literal true", () => {
  mockAppConfig({ webVoiceRoomsEnabled: "true" });
  const { unmount } = render(<Probe flag="webVoiceRoomsEnabled" />);
  expect(state()).toBe("false/true");
  unmount();
  mockAppConfig({ webVoiceRoomsEnabled: true });
  render(<Probe flag="webVoiceRoomsEnabled" />);
  expect(state()).toBe("true/true");
});

it("needs the global switch too where the spec names one", () => {
  expect(WEB_FLAG_REQUIRES).toEqual({
    webReelsEnabled: "reelsEnabled",
    webGatheringsEnabled: "gatheringsEnabled",
    webLanguageRoomsEnabled: "roomsEnabled",
  });
  expect(isWebFlagOn({ webReelsEnabled: true, reelsEnabled: false }, "webReelsEnabled")).toBe(false);
  expect(isWebFlagOn({ webReelsEnabled: true, reelsEnabled: true }, "webReelsEnabled")).toBe(true);
  expect(isWebFlagOn({ webGatheringsEnabled: true }, "webGatheringsEnabled")).toBe(false);
  expect(isWebFlagOn({ webLanguageRoomsEnabled: true, roomsEnabled: true }, "webLanguageRoomsEnabled")).toBe(true);
  // Voice rooms, calls and Apple have no global switch (spec §4).
  expect(isWebFlagOn({ webCallsEnabled: true }, "webCallsEnabled")).toBe(true);
  expect(isWebFlagOn(undefined, "webCallsEnabled")).toBe(false);
});

it("shares the announcements' cache entry and re-reads on focus", () => {
  mockAppConfig({});
  render(<Probe flag="webReelsEnabled" />);
  expect(appConfigCalls[0][0]).toEqual({ platform: "web", lang: "ko" });
  expect(appConfigCalls[0][1]).toEqual({ refetchOnFocus: true });
});
