import React from "react";
import { useTranslation } from "react-i18next";
import { BookOpen, Globe } from "lucide-react";
import SurfaceCard from "../../../design/SurfaceCard";
import LanguageExchangePill from "../../../design/LanguageExchangePill";

export interface ProfileLanguagesProps {
  /** The user document, own (`/auth/me`) or public (`USER_PUBLIC_FIELDS`). */
  user?: any;
  /** Render the contents alone, for a caller that draws the card itself. */
  bare?: boolean;
}

interface ExtraLanguage {
  name: string;
  level: string;
}

/**
 * Extra learning languages, if the record carries any.
 *
 * `models/User.js` has no `learningLanguages` path today and it is not in
 * `USER_PUBLIC_FIELDS`, so this is empty for every profile the API currently
 * returns. It is read anyway — defensively, from both the string and the
 * `{ language, level }` object shape — because the mobile app's language list
 * is the obvious next field to land here, and the alternative is a card that
 * silently drops data the moment the backend grows it.
 */
export function extraLanguages(user: any, primaryLearning: string): ExtraLanguage[] {
  const raw = user && (user.learningLanguages || user.languages);
  if (!Array.isArray(raw)) return [];
  const primary = primaryLearning.trim().toLowerCase();
  const seen: Record<string, boolean> = {};
  const out: ExtraLanguage[] = [];

  raw.forEach((entry: any) => {
    const name =
      typeof entry === "string"
        ? entry
        : String((entry && (entry.language || entry.name)) || "");
    const trimmed = name.trim();
    if (!trimmed) return;
    const key = trimmed.toLowerCase();
    if (key === primary || seen[key]) return;
    seen[key] = true;
    const level =
      typeof entry === "string"
        ? ""
        : String((entry && (entry.level || entry.languageLevel)) || "").trim();
    out.push({ name: trimmed, level });
  });

  return out;
}

/**
 * The language exchange itself: native → learning with the CEFR dots, the two
 * languages named in full underneath, and any further languages as chips.
 *
 * The pill is the shared primitive, so the pair reads identically here, in the
 * community row and on a moment card.
 */
/** Whether this section has anything to show. Same rule as the guard below. */
export const hasLanguages = (user: any): boolean =>
  !!(String((user && user.native_language) || "").trim() ||
     String((user && user.language_to_learn) || "").trim());

const ProfileLanguages: React.FC<ProfileLanguagesProps> = ({ user, bare }) => {
  const { t } = useTranslation();

  const native = String((user && user.native_language) || "").trim();
  const learning = String((user && user.language_to_learn) || "").trim();
  const level = String((user && user.languageLevel) || "").trim();
  const extras = extraLanguages(user, learning);

  if (!hasLanguages(user)) return null;

  const body = (
    <>
      <div data-testid="profile-languages">
        <h2 className="mb-3 text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
          {t("profile.sections.languages") || "Languages"}
        </h2>

        <div className="flex flex-wrap items-center gap-2">
          {/* The pill is a *pair*. With one side missing it would have to
              repeat the same language on both sides, which reads as a claim
              the record has not made, so it is simply not drawn. */}
          {native && learning && (
            <LanguageExchangePill
              nativeLanguage={native}
              learningLanguage={learning}
              languageLevel={level || null}
            />
          )}
          {level && (
            <span
              data-testid="language-level"
              className="inline-flex items-center rounded-full bg-brand/[0.12] px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wide text-brand-dark dark:text-brand-light"
            >
              {level}
            </span>
          )}
        </div>

        <dl className="mt-4 flex flex-wrap gap-x-8 gap-y-3">
          {native && (
            <div data-testid="language-native" className="flex items-center gap-2">
              <Globe className="h-4 w-4 shrink-0 text-brand" aria-hidden />
              <div className="leading-tight">
                <dt className="text-[11px] uppercase tracking-wide text-ink-500 dark:text-ink-400">
                  {t("profile.labels.native_language") || "Native"}
                </dt>
                <dd className="text-sm font-semibold text-ink-900 dark:text-ink-50">
                  {native}
                </dd>
              </div>
            </div>
          )}

          {learning && (
            <div data-testid="language-learning" className="flex items-center gap-2">
              <BookOpen className="h-4 w-4 shrink-0 text-brand" aria-hidden />
              <div className="leading-tight">
                <dt className="text-[11px] uppercase tracking-wide text-ink-500 dark:text-ink-400">
                  {t("profile.labels.learning") || "Learning"}
                </dt>
                <dd className="text-sm font-semibold text-ink-900 dark:text-ink-50">
                  {learning}
                </dd>
              </div>
            </div>
          )}
        </dl>

        {extras.length > 0 && (
          <div className="mt-4">
            <p className="mb-2 text-[11px] uppercase tracking-wide text-ink-500 dark:text-ink-400">
              {t("profile.languages.also_learning") || "Also learning"}
            </p>
            <div className="flex flex-wrap gap-2">
              {extras.map((entry) => (
                <span
                  key={entry.name}
                  data-testid="language-extra"
                  className="inline-flex items-center gap-1.5 rounded-chip bg-ink-100 px-2.5 py-1 text-xs font-semibold text-ink-700 dark:bg-ink-800 dark:text-ink-100"
                >
                  {entry.name}
                  {entry.level && (
                    <span className="text-[10px] font-extrabold uppercase text-brand-dark dark:text-brand-light">
                      {entry.level}
                    </span>
                  )}
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

export default ProfileLanguages;
