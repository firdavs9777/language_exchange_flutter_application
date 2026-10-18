import { useTranslation } from "react-i18next";
import { useGetAppConfigQuery, AppConfig } from "../store/slices/appConfigSlice";

/**
 * The website-only feature flags (web parity spec §4). Server env
 * WEB_*_ENABLED -> /app-config booleans, default false. This module is the
 * only place the website reads them: a feature is hidden -- no nav entry, no
 * route, no button -- unless its flag is a literal `true`.
 */
export type WebFlag =
  | "webReelsEnabled"
  | "webGatheringsEnabled"
  | "webVoiceRoomsEnabled"
  | "webLanguageRoomsEnabled"
  | "webCallsEnabled"
  | "webAppleSigninEnabled";

/**
 * Global switches that still apply on top of the web flag (spec §4):
 * REELS_ENABLED, GATHERINGS_ENABLED, ROOMS_ENABLED (language rooms). Voice
 * rooms, calls and Apple sign-in have none.
 */
export const WEB_FLAG_REQUIRES: { [flag: string]: string } = {
  webReelsEnabled: "reelsEnabled",
  webGatheringsEnabled: "gatheringsEnabled",
  webLanguageRoomsEnabled: "roomsEnabled",
};

export function isWebFlagOn(config: AppConfig | undefined | null, flag: WebFlag): boolean {
  if (!config || config[flag] !== true) return false;
  const global = WEB_FLAG_REQUIRES[flag];
  return global ? config[global] === true : true;
}

export interface WebFlagState {
  on: boolean;
  /** false only while the first app-config request is in flight. */
  ready: boolean;
}

export function useWebFlagState(flag: WebFlag): WebFlagState {
  const { i18n } = useTranslation();
  // Some suites mock react-i18next without `i18n`; fall back to "en" so the
  // hook never crashes a screen that merely shows a flagged button.
  const lang = (i18n && i18n.language) || "en";
  // Same args as useWebAnnouncements: one cache entry, one request. Re-read on
  // window focus (setupListeners, Phase 3) so a flag the owner flips shows up
  // without a reload -- and a flag flipped off hides its entry points.
  const { data, isError } = useGetAppConfigQuery(
    { platform: "web", lang },
    { refetchOnFocus: true }
  );
  if (isError && !data) return { on: false, ready: true };
  if (!data) return { on: false, ready: false };
  return { on: isWebFlagOn(data, flag), ready: true };
}

export function useWebFlag(flag: WebFlag): boolean {
  return useWebFlagState(flag).on;
}
