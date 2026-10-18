import React from "react";
import { useTranslation } from "react-i18next";
import { trackEvent } from "../../analytics/track";
import { gaEvent } from "../../analytics/ga";

// Store URLs live in ./storeUrls (React-free); re-exported so existing
// `import { APP_STORE_URL } from "./StoreLink"` call sites keep working.
import { APP_STORE_URL, PLAY_STORE_URL } from "./storeUrls";
export { APP_STORE_URL, PLAY_STORE_URL, STORE_HOSTS } from "./storeUrls";

export type StoreId = "ios" | "android";

/** Where the tap happened. One value per surface, and it becomes utm_campaign. */
export type StorePlacement =
  | "hero"
  | "pricing"
  | "final-cta"
  | "download-page"
  | "sticky-banner"
  | "popup"
  | "promo-carousel"
  | "footer"
  | "meet"
  | "learn-korean"
  | "communities"
  | "invite";

export type StoreVariant = "badge" | "button";

export interface StoreLinkProps {
  store: StoreId;
  placement: StorePlacement;
  variant?: StoreVariant;
  className?: string;
  children?: React.ReactNode;
}

const STORE_URL: Record<StoreId, string> = {
  ios: APP_STORE_URL,
  android: PLAY_STORE_URL,
};

const UTM_SOURCE = "banatalk.com";
const UTM_MEDIUM = "web";

/**
 * The store URL with the campaign attached. The Play URL already carries
 * `?id=com.bananatalk.app`, so the separator is decided per URL: a second `?`
 * would swallow the package id and land the visitor on the store's home page.
 */
export function storeHref(store: StoreId, placement: StorePlacement): string {
  const base = STORE_URL[store];
  const query =
    `utm_source=${UTM_SOURCE}&utm_medium=${UTM_MEDIUM}` +
    `&utm_campaign=${encodeURIComponent(placement)}`;
  return `${base}${base.indexOf("?") === -1 ? "?" : "&"}${query}`;
}

// Both marks are the monochrome glyphs the stores publish for use on a dark or
// light pill; they size from the surrounding font or from the caller's CSS.
const StoreGlyph: React.FC<{ store: StoreId }> = ({ store }) => (
  <svg
    aria-hidden
    viewBox="0 0 24 24"
    width="24"
    height="24"
    fill="currentColor"
    className="shrink-0"
  >
    {store === "ios" ? (
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
    ) : (
      <path d="M3.18 23.77c-.35-.17-.57-.5-.6-.87L2.55 1.14c-.03-.37.14-.73.45-.93l9.55 11.25L3.18 23.77zm1.39.27l9.12-10.75 2.77 3.27-11.14 7.22c-.23.15-.49.23-.75.26zm12.88-8.44l-2.73-3.22 2.73-3.22 3.11 2.01c.72.47.72 1.23 0 1.69l-3.11 2.74zM4.57.03l11.14 7.22-2.77 3.27L3.81.77C4.04.35 4.3.14 4.57.03z" />
    )}
  </svg>
);

// Layout only. Every caller keeps its own skin -- background, radius, padding --
// by passing `className`, which is what lets one component serve the hero pill,
// the footer chip and the download page badge without any of them changing.
const BASE_CLASS: Record<StoreVariant, string> = {
  badge: "inline-flex items-center gap-3",
  button: "inline-flex items-center justify-center",
};

const StoreLink: React.FC<StoreLinkProps> = ({
  store,
  placement,
  variant = "button",
  className,
  children,
}) => {
  const { t } = useTranslation();

  const name =
    store === "ios"
      ? t("growth.store.appStore") || "App Store"
      : t("growth.store.googlePlay") || "Google Play";
  const prefix =
    store === "ios"
      ? t("growth.store.downloadOnThe") || "Download on the"
      : t("growth.store.getItOn") || "Get it on";

  // Fire and forget, then let the browser follow the href. Neither tracker is
  // allowed to cost an install, so a throwing one is swallowed and
  // preventDefault() is never called.
  const onClick = () => {
    try {
      trackEvent("store_tap", { placement, platform: store });
    } catch {
      /* measurement is never worth a lost install */
    }
    try {
      gaEvent("store_tap", { placement, platform: store });
    } catch {
      /* same */
    }
  };

  const classes = [BASE_CLASS[variant], className].filter(Boolean).join(" ");

  // A badge is the store's own lockup and never takes children; a button or a
  // text link falls back to the store name when the caller has no label.
  const content: React.ReactNode =
    variant === "badge" ? (
      <>
        <StoreGlyph store={store} />
        <div>
          <span className="btn-label">{prefix}</span>
          <span className="btn-store">{name}</span>
        </div>
      </>
    ) : children === undefined ? (
      name
    ) : (
      children
    );

  return (
    <a
      href={storeHref(store, placement)}
      target="_blank"
      rel="noopener noreferrer"
      data-testid={`store-link-${store}`}
      onClick={onClick}
      className={classes || undefined}
    >
      {content}
    </a>
  );
};

export default StoreLink;
