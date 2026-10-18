import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Brain, Briefcase, Droplet, GraduationCap, Hash, Users } from "lucide-react";
import { publicIntents } from "../intents";
import SurfaceCard from "../../../design/SurfaceCard";

export interface ProfileAboutProps {
  /** The user document, own (`/auth/me`) or public (`USER_PUBLIC_FIELDS`). */
  user?: any;
  /** Render the contents alone, for a caller that draws the card itself. */
  bare?: boolean;
}

/** Long bios get a fold rather than a scroll: the card must stay a card. */
export const BIO_COLLAPSE_AT = 240;

function text(value: any): string {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Bio, occupation, school, interests, MBTI and blood type — everything the
 * backend already knows about a person that is not a language or a number.
 *
 * `occupation` and `school` are in `USER_PUBLIC_FIELDS` but have never been
 * rendered anywhere in the web app (inventory §5); this is their first
 * appearance. The whole card is skipped when every field is empty — an
 * "About" heading over nothing is worse than no heading.
 */
/** Whether this section has anything to show. Same rule as the guard below. */
export const hasAbout = (user: any): boolean => {
  const topics: string[] = Array.isArray(user && user.topics)
    ? user.topics.filter((topic: any) => text(topic))
    : [];
  return !!(
    text(user && user.bio) ||
    text(user && user.occupation) ||
    text(user && user.school) ||
    text(user && user.mbti) ||
    text(user && user.bloodType) ||
    topics.length ||
    publicIntents(user && user.intents).length
  );
};

const ProfileAbout: React.FC<ProfileAboutProps> = ({ user, bare }) => {
  const { t } = useTranslation();
  const [expanded, setExpanded] = useState(false);

  const bio = text(user && user.bio);
  const occupation = text(user && user.occupation);
  const school = text(user && user.school);
  const mbti = text(user && user.mbti);
  const bloodType = text(user && user.bloodType);
  const topics: string[] = Array.isArray(user && user.topics)
    ? user.topics.filter((topic: any) => text(topic))
    : [];

  // Learn / meet only — dating is never printed on a profile, own included.
  const intents = publicIntents(user && user.intents);
  const INTENT_ICONS = { learn: GraduationCap, meet: Users } as const;

  if (!hasAbout(user)) return null;

  const isLong = bio.length > BIO_COLLAPSE_AT;
  const shownBio = isLong && !expanded ? `${bio.slice(0, BIO_COLLAPSE_AT).trim()}…` : bio;

  const facts = [
    {
      key: "occupation",
      icon: Briefcase,
      label: t("profile.about.occupation") || "Work",
      value: occupation,
    },
    {
      key: "school",
      icon: GraduationCap,
      label: t("profile.about.school") || "School",
      value: school,
    },
    {
      key: "mbti",
      icon: Brain,
      label: t("profile.labels.mbti") || "MBTI",
      value: mbti,
    },
    {
      key: "blood",
      icon: Droplet,
      label: t("profile.labels.blood_type") || "Blood type",
      value: bloodType,
    },
  ].filter((fact) => Boolean(fact.value));

  const body = (
    <>
      <div data-testid="profile-about">
        <h2 className="mb-3 text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
          {t("profile.about.title") || "About"}
        </h2>

        {bio && (
          <div className="mb-4">
            <p
              id="about-bio"
              data-testid="about-bio"
              className="whitespace-pre-wrap break-words text-sm leading-relaxed text-ink-800 dark:text-ink-100"
            >
              {shownBio}
            </p>
            {isLong && (
              <button
                type="button"
                data-testid="about-bio-toggle"
                aria-expanded={expanded}
                aria-controls="about-bio"
                onClick={() => setExpanded(!expanded)}
                className="mt-1 text-xs font-extrabold text-brand-deep hover:underline dark:text-brand-light"
              >
                {expanded
                  ? t("profile.about.read_less") || "Show less"
                  : t("profile.about.read_more") || "Read more"}
              </button>
            )}
          </div>
        )}

        {facts.length > 0 && (
          <dl className="flex flex-wrap gap-x-8 gap-y-3">
            {facts.map((fact) => {
              const Icon = fact.icon;
              return (
                <div
                  key={fact.key}
                  data-testid={`about-${fact.key}`}
                  className="flex items-center gap-2"
                >
                  <Icon className="h-4 w-4 shrink-0 text-brand" aria-hidden />
                  <div className="leading-tight">
                    <dt className="text-[11px] uppercase tracking-wide text-ink-500 dark:text-ink-400">
                      {fact.label}
                    </dt>
                    <dd className="break-words text-sm font-semibold text-ink-900 dark:text-ink-50">
                      {fact.value}
                    </dd>
                  </div>
                </div>
              );
            })}
          </dl>
        )}

        {intents.length > 0 && (
          <div data-testid="about-intents" className="mt-4">
            <p className="mb-2 text-[11px] uppercase tracking-wide text-ink-500 dark:text-ink-400">
              {t("profile.edit.intent_title") || "What you're here for"}
            </p>
            <div className="flex flex-wrap gap-2">
              {intents.map((intent) => {
                const Icon = INTENT_ICONS[intent as "learn" | "meet"];
                return (
                  <span
                    key={intent}
                    data-testid={`about-intent-${intent}`}
                    className="inline-flex items-center gap-1 rounded-chip bg-banana/20 px-2.5 py-1 text-xs font-semibold text-ink-800 dark:bg-banana/15 dark:text-ink-100"
                  >
                    <Icon className="h-3 w-3" aria-hidden />
                    {t(`profile.edit.intent_${intent}`) ||
                      (intent === "learn" ? "Here to learn" : "Open to meeting people")}
                  </span>
                );
              })}
            </div>
          </div>
        )}

        {topics.length > 0 && (
          <div className="mt-4">
            <p className="mb-2 text-[11px] uppercase tracking-wide text-ink-500 dark:text-ink-400">
              {t("profile.sections.topics") || "Topics & Interests"}
            </p>
            <div className="flex flex-wrap gap-2">
              {topics.map((topic, index) => (
                <span
                  key={`${topic}-${index}`}
                  data-testid="about-topic"
                  className="inline-flex items-center gap-1 rounded-chip bg-brand/[0.09] px-2.5 py-1 text-xs font-semibold text-brand-dark dark:bg-brand/[0.18] dark:text-brand-light"
                >
                  <Hash className="h-3 w-3" aria-hidden />
                  {/* Same lookup the editor uses, so an interest reads the
                      same on the form and on the profile in all 18 locales.
                      The fallback keeps free-text topics from older records. */}
                  {t(`profile.topics.${topic}`) || topic}
                </span>
              ))}
            </div>
          </div>
        )}
      </div>
    </>
  );

  return bare ? body : <SurfaceCard padding="md">{body}</SurfaceCard>;
};

export default ProfileAbout;
