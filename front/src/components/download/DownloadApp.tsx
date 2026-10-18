import React, { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { detectPlatform } from "../../utils/platform";
import StoreLink, { StoreId, storeHref } from "../growth/StoreLink";
import { trackEvent } from "../../analytics/track";
import { gaEvent } from "../../analytics/ga";
import SurfaceCard from "../../design/SurfaceCard";
import { SITE_ORIGIN } from "../../seo/pages";
import brandLogo from "../../assets/logo.png";

// What the QR carries. `src=qr` separates a camera scan from a click in the
// analytics; `go=1` is what makes the phone hop straight to its store, since
// someone who scanned a code is already asking for the app.
const QR_TARGET = `${SITE_ORIGIN}/download?src=qr&go=1`;
const QR_SIZE = 192;

const DownloadApp: React.FC = () => {
  const { t } = useTranslation();
  const { search } = useLocation();

  // "other" until the user agent says otherwise, and it only says so after
  // mount: reading navigator during render would bake one platform into the
  // prerendered HTML and React 18 does not repair a mismatch while hydrating.
  const [platform, setPlatform] = useState<"ios" | "android" | "other">("other");
  const [qr, setQr] = useState("");

  useEffect(() => {
    setPlatform(detectPlatform(navigator.userAgent));
  }, []);

  // The old page redirected every mobile visitor on arrival, which left it
  // unreadable and un-indexable (spec §5.3). The hop is now opt-in: only the
  // surfaces that mean "take me to the store" append `go=1`. A desktop has no
  // store to open, so it just reads the page.
  // Reuses the platform decided above (one user-agent read) -- it settles a
  // render after mount, and the effect re-runs when it does.
  useEffect(() => {
    if (!/(^|[?&])go=1(&|$)/.test(search)) return;
    if (platform === "ios" || platform === "android") {
      // The hop is a store tap too -- a QR scan or a carousel CTA must count
      // like a badge click, or the funnel under-reports its best sources.
      try {
        trackEvent("store_tap", { placement: "download-page", platform });
        gaEvent("store_tap", { placement: "download-page", platform });
      } catch {
        // never let a tracker cost the install
      }
      window.location.assign(storeHref(platform, "download-page"));
    }
  }, [search, platform]);

  // ~10KB of QR generator that nobody needs until the page is on screen, so it
  // is pulled in a chunk of its own after mount. The box below is rendered
  // either way, at its final size, so the prerendered page does not reflow
  // when the image arrives -- and so a failed load costs nothing but the code.
  useEffect(() => {
    let alive = true;
    import("qrcode")
      .then((mod) => {
        const lib: any = (mod as any).default && (mod as any).default.toDataURL ? (mod as any).default : mod;
        return lib.toDataURL(QR_TARGET, { margin: 1, width: QR_SIZE });
      })
      .then((url: string) => {
        if (alive && url) setQr(url);
      })
      .catch(() => {
        /* the badges above are the real call to action; the QR is a convenience */
      });
    return () => {
      alive = false;
    };
  }, []);

  // Mobile visitors see their own store first. Both badges always render: the
  // detection is a guess, and the other store is one line down.
  const stores: StoreId[] = platform === "android" ? ["android", "ios"] : ["ios", "android"];

  const reasons = [
    {
      key: "tutor",
      icon: "🎓",
      title: t("download.reasons.tutor.title") || "An AI tutor in every chat",
      body:
        t("download.reasons.tutor.body") ||
        "Corrections and explanations on the messages you actually send.",
    },
    {
      key: "voice",
      icon: "🎙️",
      title: t("download.reasons.voice.title") || "Voice rooms and calls",
      body:
        t("download.reasons.voice.body") ||
        "Practise out loud with people learning your language right now.",
    },
    {
      key: "translate",
      icon: "🌍",
      title: t("download.reasons.translate.title") || "Instant translation",
      body:
        t("download.reasons.translate.body") ||
        "Write in your language, they read it in theirs, and you learn from the difference.",
    },
  ];

  return (
    <div className="bg-surface px-[1rem] py-12 dark:bg-cardbg-dark sm:py-16">
      <div className="mx-auto max-w-3xl text-center">
        <img src={brandLogo} alt="" aria-hidden className="mx-auto h-16 w-16 rounded-2xl" />
        <h1 className="mt-[1rem] text-3xl font-extrabold text-gray-900 dark:text-gray-50 sm:text-4xl">
          {t("download.title") || "Download BananaTalk"}
        </h1>
        <p className="mx-auto mt-[0.75rem] max-w-xl text-base leading-relaxed text-gray-600 dark:text-gray-300">
          {t("download.subtitle") ||
            "Free language exchange with native speakers in 137 languages, on iPhone and Android."}
        </p>

        {/* The badge's two lines stack from here rather than from a
            stylesheet: StoreLink ships the lockup's markup and leaves the skin
            to its caller, and this is the only page wearing the big version. */}
        <div className="mt-8 flex flex-col items-center gap-[0.75rem] sm:flex-row sm:justify-center">
          {stores.map((store) => (
            <StoreLink
              key={store}
              store={store}
              placement="download-page"
              variant="badge"
              className={`w-full max-w-[280px] justify-center rounded-2xl px-6 py-3.5 text-left sm:w-auto [&>div]:flex [&>div]:flex-col [&_.btn-label]:text-[0.7rem] [&_.btn-label]:opacity-80 [&_.btn-store]:text-[1.0625rem] [&_.btn-store]:font-semibold [&_.btn-store]:leading-tight ${
                store === "ios"
                  ? "bg-gray-900 text-white dark:bg-gray-50 dark:text-gray-900"
                  : "border-[1px] border-gray-300 text-gray-900 dark:border-gray-600 dark:text-gray-50"
              }`}
            />
          ))}
        </div>

        <p
          data-testid="download-free"
          className="mt-[1rem] text-sm font-semibold text-gray-500 dark:text-gray-400"
        >
          {t("download.free") || "Free. No card."}
        </p>

        {/* The box exists in the prerendered HTML at its final size; the image
            drops into it after mount. */}
        <div className="mt-10 flex flex-col items-center">
          <div
            data-testid="download-qr"
            className="flex items-center justify-center rounded-2xl border-[1px] border-gray-200 bg-white p-[0.75rem] dark:border-gray-700"
            style={{ width: QR_SIZE, height: QR_SIZE }}
          >
            {qr ? (
              <img
                src={qr}
                width={QR_SIZE - 24}
                height={QR_SIZE - 24}
                alt={t("download.qrAlt") || "QR code to download BananaTalk"}
              />
            ) : null}
          </div>
          <p className="mt-[0.75rem] text-sm text-gray-500 dark:text-gray-400">
            {t("download.scan") || "Scan with your phone camera"}
          </p>
        </div>

        <div className="mt-12 grid gap-[1rem] text-left sm:grid-cols-3">
          {reasons.map((reason) => (
            <SurfaceCard key={reason.key} padding="lg">
              <span aria-hidden className="text-2xl">
                {reason.icon}
              </span>
              <h2 className="mt-[0.5rem] text-base font-extrabold text-gray-900 dark:text-gray-50">
                {reason.title}
              </h2>
              <p className="mt-[0.25rem] text-sm leading-relaxed text-gray-600 dark:text-gray-300">
                {reason.body}
              </p>
            </SurfaceCard>
          ))}
        </div>
      </div>
    </div>
  );
};

export default DownloadApp;
