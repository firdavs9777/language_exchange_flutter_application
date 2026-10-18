import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import PageMeta from "../../seo/PageMeta";
import StoreLink, { StoreId } from "../growth/StoreLink";
import SurfaceCard from "../../design/SurfaceCard";
import { detectPlatform } from "../../utils/platform";
import brandLogo from "../../assets/logo.png";

// /i/:code -- where an invite link lands for someone who does NOT have the app.
// (With the app installed, iOS/Android hand the URL to the app itself, which
// stores the code and claims it after the profile is complete.)
//
// Same shape the app accepts: base32 [A-Z2-7], 4-16 chars, case-insensitive.
// Anything else renders the generic "Join BananaTalk" page with no code.
const CODE_PATTERN = /^[A-Z2-7]{4,16}$/i;

export function parseInviteCode(raw: string | undefined): string | null {
  if (!raw || !CODE_PATTERN.test(raw)) return null;
  return raw.toUpperCase();
}

async function copyText(text: string): Promise<boolean> {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch {
    /* fall through to the textarea fallback */
  }
  try {
    const el = document.createElement("textarea");
    el.value = text;
    el.setAttribute("readonly", "");
    el.style.position = "fixed";
    el.style.opacity = "0";
    document.body.appendChild(el);
    el.select();
    const ok = document.execCommand("copy");
    document.body.removeChild(el);
    return ok;
  } catch {
    return false;
  }
}

const InvitePage: React.FC = () => {
  const { t } = useTranslation();
  const { code: rawCode } = useParams();
  const code = parseInviteCode(rawCode);
  const [copied, setCopied] = useState(false);
  // Decided after mount, like DownloadApp: reading navigator during render
  // would not match server markup.
  const [mobile, setMobile] = useState(false);

  useEffect(() => {
    setMobile(detectPlatform(navigator.userAgent) !== "other");
  }, []);

  useEffect(() => {
    if (!copied) return;
    const id = window.setTimeout(() => setCopied(false), 2000);
    return () => window.clearTimeout(id);
  }, [copied]);

  const title = code
    ? t("invite.title") || "You're invited to BananaTalk"
    : t("invite.genericTitle") || "Join BananaTalk";
  const subtitle =
    t("invite.subtitle") ||
    "Practice languages with real people. Join with your friend's invite code and you both get coins.";
  const stores: StoreId[] = ["ios", "android"];

  const onCopy = async () => {
    if (code && (await copyText(code))) setCopied(true);
  };

  return (
    <div className="bg-surface px-[1rem] py-12 dark:bg-cardbg-dark sm:py-16">
      <PageMeta noindex title={`${title} | BananaTalk`} />
      <div className="mx-auto max-w-xl text-center">
        <img src={brandLogo} alt="" aria-hidden className="mx-auto h-16 w-16 rounded-2xl" />
        <h1 className="mt-[1rem] text-3xl font-extrabold text-gray-900 dark:text-gray-50 sm:text-4xl">
          {title}
        </h1>
        <p className="mx-auto mt-[0.75rem] max-w-md text-base leading-relaxed text-gray-600 dark:text-gray-300">
          {subtitle}
        </p>

        {code && (
          <SurfaceCard padding="lg" className="mt-8">
            <p className="text-sm font-semibold text-gray-500 dark:text-gray-400">
              {t("invite.yourCode") || "Your invite code"}
            </p>
            <p
              data-testid="invite-code"
              className="mt-[0.5rem] break-all font-mono text-4xl font-extrabold tracking-widest text-gray-900 dark:text-gray-50 sm:text-5xl"
            >
              {code}
            </p>
            <button
              type="button"
              onClick={onCopy}
              className="mt-[1rem] rounded-2xl border-[1px] border-gray-300 px-6 py-2.5 text-sm font-semibold text-gray-900 dark:border-gray-600 dark:text-gray-50"
            >
              <span aria-live="polite">
                {copied ? t("invite.copied") || "Copied!" : t("invite.copy") || "Copy"}
              </span>
            </button>
          </SurfaceCard>
        )}

        <div className="mt-8 flex flex-col items-center gap-[0.75rem] sm:flex-row sm:justify-center">
          {stores.map((store) => (
            <StoreLink
              key={store}
              store={store}
              placement="invite"
              variant="badge"
              className={`w-full max-w-[280px] justify-center rounded-2xl px-6 py-3.5 text-left sm:w-auto [&>div]:flex [&>div]:flex-col [&_.btn-label]:text-[0.7rem] [&_.btn-label]:opacity-80 [&_.btn-store]:text-[1.0625rem] [&_.btn-store]:font-semibold [&_.btn-store]:leading-tight ${
                store === "ios"
                  ? "bg-gray-900 text-white dark:bg-gray-50 dark:text-gray-900"
                  : "border-[1px] border-gray-300 text-gray-900 dark:border-gray-600 dark:text-gray-50"
              }`}
            />
          ))}
        </div>

        {mobile && code && (
          <a
            data-testid="invite-open-app"
            href={`bananatalk://i/${code}`}
            className="mt-[1rem] inline-block text-sm font-semibold text-gray-900 underline dark:text-gray-50"
          >
            {t("invite.openInApp") || "Open in the app"}
          </a>
        )}

        <ol className="mx-auto mt-10 max-w-md space-y-[0.75rem] text-left text-base text-gray-700 dark:text-gray-200">
          <li>
            <span className="font-extrabold">1.</span> {t("invite.step1") || "Install BananaTalk"}
          </li>
          <li>
            <span className="font-extrabold">2.</span>{" "}
            {t("invite.step2") ||
              "Open this link again, or enter the code after you complete your profile"}
          </li>
        </ol>
      </div>
    </div>
  );
};

export default InvitePage;
