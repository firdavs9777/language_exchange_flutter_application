// Test helper: what the mocked useGetAppConfigQuery returns. Every Phase 4
// flag-off test uses it, so "flag off", "loading" and "app-config failed"
// mean the same thing in every suite.
//
//   jest.mock("../../store/slices/appConfigSlice", () =>
//     require("../../utils/testing/mockWebFlags").appConfigSliceMock());
//   mockAppConfig({ webReelsEnabled: true, reelsEnabled: true });
let current: any = { data: {}, isError: false };
export const appConfigCalls: any[][] = [];

export function mockAppConfig(flags: { [k: string]: any } | "loading" | "error"): void {
  if (flags === "loading") current = { data: undefined, isError: false, isLoading: true };
  else if (flags === "error") current = { data: undefined, isError: true, isLoading: false };
  else current = { data: flags, isError: false, isLoading: false };
}

export const ALL_WEB_FLAGS_ON = {
  webReelsEnabled: true,
  webGatheringsEnabled: true,
  webVoiceRoomsEnabled: true,
  webLanguageRoomsEnabled: true,
  webCallsEnabled: true,
  webAppleSigninEnabled: true,
  reelsEnabled: true,
  gatheringsEnabled: true,
  roomsEnabled: true,
};

export const ALL_WEB_FLAGS_OFF = {
  webReelsEnabled: false,
  webGatheringsEnabled: false,
  webVoiceRoomsEnabled: false,
  webLanguageRoomsEnabled: false,
  webCallsEnabled: false,
  webAppleSigninEnabled: false,
  reelsEnabled: true,
  gatheringsEnabled: true,
  roomsEnabled: true,
};

export function appConfigSliceMock() {
  return {
    useGetAppConfigQuery: (...args: any[]) => {
      appConfigCalls.push(args);
      return current;
    },
  };
}
