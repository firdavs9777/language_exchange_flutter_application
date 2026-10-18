import React from "react";
import { useTranslation } from "react-i18next";
import { BadgeCheck, Crown } from "lucide-react";
import Avatar from "../../../design/Avatar";
import Badge from "../../../design/Badge";

export interface ProfileHeaderProps {
  name: string;
  username?: string;
  avatarUrl?: string;
  /** Opens the photo viewer on the avatar, which is also the first photo. */
  onAvatarClick?: () => void;
  /** The person has a story the viewer may see: ring the avatar, and the tap opens it. */
  hasStory?: boolean;
  isOnline?: boolean;
  /** Birth fields as the API returns them — strings on the wire. */
  birthYear?: string | number;
  birthMonth?: string | number;
  birthDay?: string | number;
  /** The `location` sub-document, or a plain string on older records. */
  location?: any;
  /** `userMode` from the user document; the VIP badge shows for `"vip"`. */
  userMode?: string;
  /** `isEmailVerified` — own profiles only, it is not in USER_PUBLIC_FIELDS. */
  isEmailVerified?: boolean;
  createdAt?: string;
  lastActive?: string;
}

function toNumber(value?: string | number): number {
  const n = typeof value === "number" ? value : parseInt(String(value || ""), 10);
  return isFinite(n) ? n : NaN;
}

/**
 * Age in whole years, or null when the birth fields are absent — the public
 * endpoint drops them when `privacySettings.showAge` is off, and a profile
 * with no age shows no age rather than a guess.
 */
export function ageFromBirth(
  year?: string | number,
  month?: string | number,
  day?: string | number,
  now: Date = new Date()
): number | null {
  const y = toNumber(year);
  if (!isFinite(y) || y < 1900) return null;
  const m = isFinite(toNumber(month)) ? toNumber(month) : 1;
  const d = isFinite(toNumber(day)) ? toNumber(day) : 1;
  let age = now.getFullYear() - y;
  const beforeBirthday =
    now.getMonth() + 1 < m || (now.getMonth() + 1 === m && now.getDate() < d);
  if (beforeBirthday) age -= 1;
  return age > 0 && age < 120 ? age : null;
}

/** "Seoul, South Korea" from the GeoJSON sub-document, or the legacy string. */
export function formatLocation(location: any): string {
  if (!location) return "";
  if (typeof location === "string") return location.trim();
  return [location.city, location.state, location.country]
    .filter((part: any) => typeof part === "string" && part.trim())
    .slice(0, 2)
    .join(", ");
}

function parseDate(value?: string): Date | null {
  if (!value) return null;
  const date = new Date(value);
  return isFinite(date.getTime()) ? date : null;
}

/** "Sep 2026". Intl, because the repo has no shared date helper to reuse. */
function formatMonthYear(date: Date, language: string): string {
  try {
    return new Intl.DateTimeFormat(language, { month: "short", year: "numeric" }).format(date);
  } catch {
    return `${date.getUTCFullYear()}`;
  }
}

// `Intl.RelativeTimeFormat` has no typing in the repo's typescript@3.7.2 lib,
// so the constructor is reached through an `any` view of Intl rather than
// declared -- a `declare global` block here would fight the next TS upgrade.
const UNITS: Array<[string, number]> = [
  ["year", 365 * 24 * 3600],
  ["month", 30 * 24 * 3600],
  ["week", 7 * 24 * 3600],
  ["day", 24 * 3600],
  ["hour", 3600],
  ["minute", 60],
];

/** "2 hours ago". Falls back to the empty string where Intl is unavailable. */
function formatRelative(date: Date, language: string, now: Date = new Date()): string {
  const seconds = Math.round((now.getTime() - date.getTime()) / 1000);
  const RelativeTimeFormat = (Intl as any).RelativeTimeFormat;
  if (!RelativeTimeFormat) return "";
  try {
    const rtf = new RelativeTimeFormat(language, { numeric: "auto" });
    for (let i = 0; i < UNITS.length; i += 1) {
      const unit = UNITS[i][0];
      const size = UNITS[i][1];
      if (Math.abs(seconds) >= size) return rtf.format(-Math.round(seconds / size), unit);
    }
    return rtf.format(-seconds, "second");
  } catch {
    return "";
  }
}

/**
 * The top of the profile, identical for the signed-in user and anyone else:
 * a brand cover band (a gradient, never an uploaded image — there is no cover
 * photo field on the model), the avatar breaking its lower edge, the name, and
 * a badge row that only shows facts the data actually carries.
 */
const ProfileHeader: React.FC<ProfileHeaderProps> = ({
  name,
  username,
  avatarUrl,
  onAvatarClick,
  hasStory = false,
  isOnline,
  birthYear,
  birthMonth,
  birthDay,
  location,
  userMode,
  isEmailVerified,
  createdAt,
  lastActive,
}) => {
  const { t, i18n } = useTranslation();
  const language = (i18n && i18n.language) || "en";

  const age = ageFromBirth(birthYear, birthMonth, birthDay);
  const place = formatLocation(location);
  const joined = parseDate(createdAt);
  const active = parseDate(lastActive);
  const activeText = active ? formatRelative(active, language) : "";

  const meta = [
    age === null ? "" : String(age),
    place,
  ].filter(Boolean);

  return (
    <section className="overflow-hidden rounded-card bg-surface shadow-card dark:bg-cardbg-dark dark:shadow-none">
      <div
        data-testid="profile-cover"
        className="h-28 bg-gradient-to-r from-brand-light via-brand to-brand-deep sm:h-32"
      />

      <div className="px-4 pb-5 sm:px-6">
        <div className="-mt-10 flex items-end gap-3">
          <div className="rounded-full bg-surface p-1 dark:bg-cardbg-dark">
            <Avatar
              src={avatarUrl}
              name={name}
              size={80}
              isOnline={isOnline}
              /* This one IS the page -- deferring it would delay the main
                 subject behind whatever else is loading. */
              priority
              hasStory={hasStory}
              onClick={avatarUrl || hasStory ? onAvatarClick : undefined}
              label={
                hasStory
                  ? t("profile.photos.openStory", { name }) || `View ${name}'s story`
                  : t("profile.photos.openAvatar", { name }) || `Open ${name}'s photo`
              }
            />
          </div>
        </div>

        <div className="pt-3">
          <h1 className="font-display text-xl text-ink-900 dark:text-ink-50">{name}</h1>
          {username && (
            <p className="text-sm text-ink-500 dark:text-ink-400">@{username}</p>
          )}
          {meta.length > 0 && (
            <p data-testid="profile-meta" className="pt-1 text-sm text-ink-600 dark:text-ink-300">
              {meta.join(" · ")}
            </p>
          )}
        </div>

        <div className="flex flex-wrap items-center gap-1.5 pt-3">
          {userMode === "vip" && (
            <span data-testid="badge-vip">
              <Badge tone="banana">
                <Crown className="mr-1 h-3 w-3" aria-hidden />
                {t("profile.badges.vip") || "VIP"}
              </Badge>
            </span>
          )}
          {isEmailVerified === true && (
            <span data-testid="badge-verified">
              <Badge>
                <BadgeCheck className="mr-1 h-3 w-3" aria-hidden />
                {t("profile.badges.verified") || "Verified"}
              </Badge>
            </span>
          )}
          {joined && (
            <span data-testid="badge-joined">
              <Badge>
                {t("profile.badges.joined", { date: formatMonthYear(joined, language) }) ||
                  `Joined ${formatMonthYear(joined, language)}`}
              </Badge>
            </span>
          )}
          {(isOnline || activeText) && (
            <span data-testid="badge-active">
              <Badge>
                {isOnline
                  ? t("profile.badges.online") || "Online now"
                  : t("profile.badges.active", { time: activeText }) || `Active ${activeText}`}
              </Badge>
            </span>
          )}
        </div>
      </div>
    </section>
  );
};

export default ProfileHeader;
