import React from "react";
import { Link, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { toast } from "react-toastify";
import {
  ArrowRight,
  GraduationCap,
  MapPin,
  MessageCircle,
  Pencil,
  Share2,
  Smartphone,
  Users,
} from "lucide-react";
import PageMeta from "../../seo/PageMeta";
import Avatar from "../../design/Avatar";
import { useGetPublicUserProfileQuery } from "../../store/slices/communitySlice";
import routeId from "../../utils/routeId";
import { languageFlag, stripVariant } from "../../utils/languages";
import { publicIntents } from "../profile/intents";
import { shareContent } from "../linking/shareContent";
import { openInApp } from "../linking/openInAppAction";
import brandLogo from "../../assets/logo.png";

/** Enough topics to say something about a person, few enough to stay a card. */
export const CARD_TOPICS = 5;

const text = (value: any): string => (typeof value === "string" ? value.trim() : "");

const PAGE = "min-h-screen bg-canvas px-4 pb-16 pt-6 dark:bg-canvas-dark sm:pt-10";
const BUTTON =
  "inline-flex min-h-[44px] w-full items-center justify-center gap-2 rounded-chip px-4 text-sm font-semibold transition-colors";
const PRIMARY = `${BUTTON} bg-brand-deep text-white hover:bg-brand-dark`;
const SECONDARY = `${BUTTON} border border-line bg-surface text-ink-800 hover:bg-ink-50 dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-100 dark:hover:bg-white/5`;

/**
 * A language-exchange card: who someone is and what they trade, on a page
 * anyone can open from a link.
 *
 * This is the web doing what the app cannot — a URL that works with no
 * install and no account. Every card shared to a chat or a bio is an
 * invitation from a real person, which converts better than any landing page.
 *
 * It shows nothing the public profile does not already show: it reads the
 * same PUBLIC endpoint (`/auth/users/:id/public`), so the owner's privacy
 * toggles (country, city, age, online status) are applied by the server
 * before anything reaches this page, and dating is never among the intents.
 * Kept `noindex` — a card is for the people it is sent to, not for search.
 */
const LanguageCard: React.FC = () => {
  const { userId: rawUserId } = useParams<{ userId: string }>();
  // Shared links arrive with text glued on; the id at the front is still good.
  const userId = routeId(rawUserId);
  const { t } = useTranslation();
  const viewerId = useSelector(
    (state: any) => state.auth.userInfo?.user?._id || state.auth.userInfo?._id
  );

  const { data, isLoading, error } = useGetPublicUserProfileQuery(userId, {
    skip: !userId,
  });
  const user: any = (data as any)?.data || (data as any)?.user;

  if (isLoading) {
    return (
      <div className={PAGE}>
        <div
          data-testid="card-loading"
          className="mx-auto h-[520px] w-full max-w-sm animate-pulse rounded-[28px] bg-ink-100 dark:bg-white/5"
        />
      </div>
    );
  }

  if (error || !user || !user._id) {
    return (
      <div className={PAGE}>
        <PageMeta noindex title="BananaTalk" />
        <div
          data-testid="card-missing"
          className="mx-auto w-full max-w-sm rounded-[28px] border border-line bg-surface p-8 text-center dark:border-line-dark dark:bg-cardbg-dark"
        >
          <h1 className="font-display text-xl text-ink-900 dark:text-ink-50">
            {t("card.not_found") || "This card doesn't exist"}
          </h1>
          <p className="pt-2 text-sm text-ink-500 dark:text-ink-400">
            {t("card.not_found_body") || "The account may have been removed."}
          </p>
          <Link to="/communities" data-testid="card-missing-link" className={`mt-6 ${PRIMARY}`}>
            {t("card.find_partners") || "Find language partners"}
            <ArrowRight className="h-4 w-4" aria-hidden />
          </Link>
        </div>
      </div>
    );
  }

  const name = text(user.name) || text(user.username);
  const native = stripVariant(text(user.native_language));
  const learning = stripVariant(text(user.language_to_learn));
  const level = text(user.languageLevel).toUpperCase();
  const country = text(user.location && user.location.country);
  const bio = text(user.bio);
  const photo = Array.isArray(user.imageUrls) ? user.imageUrls[0] : undefined;
  const intents = publicIntents(user.intents);
  const topics: string[] = Array.isArray(user.topics)
    ? user.topics.filter((topic: any) => text(topic)).slice(0, CARD_TOPICS)
    : [];

  const isOwn = Boolean(viewerId) && viewerId === user._id;
  const signedIn = Boolean(viewerId);

  const handleShare = (): void => {
    shareContent({
      type: "card",
      id: user._id,
      title: t("card.title") || "Language Card",
      text:
        t("card.share_text", { language: native }) ||
        `Practice ${native} with me on BananaTalk`,
      nav: navigator,
      copiedMessage: t("linking.share.copied") || "Link copied to clipboard!",
      copyFailedMessage: t("linking.share.copyFailed") || "Failed to copy link",
      toast: (message, variant) =>
        variant === "error" ? toast.error(message) : toast.success(message),
    }).catch(() => {
      // The share sheet was dismissed; nothing to report.
    });
  };

  const handleOpenInApp = (): void => {
    openInApp({
      type: "profile",
      id: user._id,
      ua: navigator.userAgent,
      navigate: (url) => {
        window.location.href = url;
      },
      schedule: (fn, ms) => {
        window.setTimeout(fn, ms);
      },
      isVisible: () => document.visibilityState === "visible",
    });
  };

  const INTENT_ICONS = { learn: GraduationCap, meet: Users } as const;

  return (
    <div className={PAGE}>
      <PageMeta
        noindex
        title={`${name} · ${t("card.title") || "Language Card"} · BananaTalk`}
      />

      <article
        data-testid="language-card"
        className="relative mx-auto w-full max-w-sm overflow-hidden rounded-[28px] border border-line bg-surface shadow-card dark:border-line-dark dark:bg-cardbg-dark"
      >
        {/* The banner. Brand colours, and the one place the card is loud. */}
        <div className="relative h-28 bg-gradient-to-br from-banana via-banana-light to-brand">
          <span className="absolute right-4 top-3 rounded-full bg-white/70 px-2.5 py-0.5 text-[11px] font-extrabold uppercase tracking-wide text-ink-800 backdrop-blur">
            {t("card.title") || "Language Card"}
          </span>
        </div>

        <div className="-mt-11 px-6 pb-6">
          <div className="inline-block rounded-full ring-4 ring-surface dark:ring-cardbg-dark">
            <Avatar src={photo} name={name} size={80} priority />
          </div>

          <h1
            data-testid="card-name"
            className="pt-3 font-display text-2xl leading-tight text-ink-900 dark:text-ink-50"
          >
            {name}
          </h1>
          {country && (
            <p
              data-testid="card-country"
              className="flex items-center gap-1 pt-1 text-sm text-ink-500 dark:text-ink-400"
            >
              <MapPin className="h-3.5 w-3.5" aria-hidden />
              {country}
            </p>
          )}

          {/* What they trade: the whole point of the card, so it is the biggest thing on it. */}
          <dl className="mt-5 grid grid-cols-2 gap-3">
            <div className="rounded-2xl bg-brand/[0.08] p-3 dark:bg-brand/[0.16]">
              <dt className="text-[11px] font-extrabold uppercase tracking-wide text-ink-500 dark:text-ink-400">
                {t("card.speaks") || "Speaks"}
              </dt>
              <dd data-testid="card-speaks" className="pt-1 text-base font-bold text-ink-900 dark:text-ink-50">
                <span aria-hidden className="mr-1">{languageFlag(native)}</span>
                {native}
              </dd>
            </div>
            <div className="rounded-2xl bg-banana/20 p-3 dark:bg-banana/15">
              <dt className="text-[11px] font-extrabold uppercase tracking-wide text-ink-500 dark:text-ink-400">
                {t("card.learning") || "Learning"}
              </dt>
              <dd data-testid="card-learning" className="pt-1 text-base font-bold text-ink-900 dark:text-ink-50">
                <span aria-hidden className="mr-1">{languageFlag(learning)}</span>
                {learning}
              </dd>
              {level && (
                <span
                  data-testid="card-level"
                  className="mt-1 inline-block rounded-full bg-white/70 px-2 py-0.5 text-[11px] font-bold text-ink-700 dark:bg-white/10 dark:text-ink-200"
                >
                  {level}
                </span>
              )}
            </div>
          </dl>

          {intents.length > 0 && (
            <div data-testid="card-intents" className="mt-4 flex flex-wrap gap-2">
              {intents.map((intent) => {
                const Icon = INTENT_ICONS[intent as "learn" | "meet"];
                return (
                  <span
                    key={intent}
                    data-testid={`card-intent-${intent}`}
                    className="inline-flex items-center gap-1 rounded-chip border border-line px-2.5 py-1 text-xs font-semibold text-ink-700 dark:border-line-dark dark:text-ink-200"
                  >
                    <Icon className="h-3 w-3" aria-hidden />
                    {t(`profile.edit.intent_${intent}`) ||
                      (intent === "learn" ? "Here to learn" : "Open to meeting people")}
                  </span>
                );
              })}
            </div>
          )}

          {bio && (
            <p
              data-testid="card-bio"
              className="mt-4 line-clamp-3 break-words text-sm leading-relaxed text-ink-700 dark:text-ink-200"
            >
              {bio}
            </p>
          )}

          {topics.length > 0 && (
            <div data-testid="card-topics" className="mt-4 flex flex-wrap gap-1.5">
              {topics.map((topic, index) => (
                <span
                  key={`${topic}-${index}`}
                  data-testid="card-topic"
                  className="rounded-chip bg-ink-50 px-2 py-0.5 text-xs font-medium text-ink-600 dark:bg-white/5 dark:text-ink-300"
                >
                  #{t(`profile.topics.${topic}`) || topic}
                </span>
              ))}
            </div>
          )}

          <p className="mt-6 border-t border-line pt-3 text-center text-[11px] font-semibold uppercase tracking-wide text-ink-400 dark:border-line-dark">
            <img src={brandLogo} alt="" aria-hidden style={{ width: 18, height: 18, borderRadius: 4, verticalAlign: "-3px", marginInlineEnd: 6 }} />{t("card.tagline") || "Language exchange on BananaTalk"}
          </p>
        </div>
      </article>

      <div className="mx-auto mt-5 w-full max-w-sm space-y-2.5">
        {isOwn ? (
          <>
            <button type="button" data-testid="card-share" onClick={handleShare} className={PRIMARY}>
              <Share2 className="h-4 w-4" aria-hidden />
              {t("card.share") || "Share my card"}
            </button>
            <Link to="/profile/edit" data-testid="card-edit" className={SECONDARY}>
              <Pencil className="h-4 w-4" aria-hidden />
              {t("card.edit") || "Edit what's on it"}
            </Link>
          </>
        ) : signedIn ? (
          <>
            <Link to={`/chat/${user._id}`} data-testid="card-cta-message" className={PRIMARY}>
              <MessageCircle className="h-4 w-4" aria-hidden />
              {t("card.practice_with", { language: native, name }) ||
                `Practice ${native} with ${name}`}
            </Link>
            <Link to={`/community/${user._id}`} data-testid="card-cta-profile" className={SECONDARY}>
              {t("card.view_profile") || "See full profile"}
            </Link>
          </>
        ) : (
          <>
            <button type="button" data-testid="card-cta-app" onClick={handleOpenInApp} className={PRIMARY}>
              <Smartphone className="h-4 w-4" aria-hidden />
              {t("card.practice_with", { language: native, name }) ||
                `Practice ${native} with ${name}`}
            </button>
            <Link to={`/community/${user._id}`} data-testid="card-cta-web" className={SECONDARY}>
              {t("card.continue_web") || "Continue in the browser"}
            </Link>
          </>
        )}
      </div>
    </div>
  );
};

export default LanguageCard;
