import React from "react";
import { MapPin, ArrowRight } from "lucide-react";
import { languageFlag } from "../../utils/languages";
import { ReasonChip } from "./lib/matchReasonChips";

/**
 * Normalized member shape as produced by `communityApiSlice.getCommunityMembers`
 * transformResponse (see src/store/slices/communitySlice.ts). Only fields that
 * actually exist on USER_LIST_FIELDS / the transform are modeled here —
 * responseRate/mbti are intentionally NOT included (not present on the list
 * payload; see Package "Community" design spec, "Open items").
 */
export interface CommunityMemberCard {
  _id: string;
  name: string;
  bio?: string;
  native_language: string;
  language_to_learn: string;
  imageUrls: string[];
  birth_year?: string | number;
  gender?: string;
  createdAt?: string;
  isNew?: boolean;
  isVIP?: boolean;
  languageLevel?: string;
  location?: { city?: string; country?: string } | string;
  lastActive?: string;
  hasActiveStory?: boolean;
  isOnline?: boolean;
  followersCount?: number;
}

export interface MemberCardProps {
  user: CommunityMemberCard;
  /** From the matching engine. 0-3 strings; see controllers/matching.js. */
  reasons?: Array<string | ReasonChip>;
  /**
   * The row shape this card had before it was rebuilt as a grid cell. The
   * profile page's suggestion strip is a horizontal carousel, not a grid, and
   * a ~400px photo-on-top card is the wrong thing to put in one.
   */
  compact?: boolean;
  onWave: (user: CommunityMemberCard) => void;
  onOpen: (user: CommunityMemberCard) => void;
}

const NEW_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

const getAge = (birthYear?: string | number): number | undefined => {
  if (birthYear === undefined || birthYear === null || birthYear === "") return undefined;
  const year = typeof birthYear === "string" ? parseInt(birthYear, 10) : birthYear;
  if (!year || Number.isNaN(year)) return undefined;
  const age = new Date().getFullYear() - year;
  return age > 0 && age < 130 ? age : undefined;
};

const isRecentlyCreated = (createdAt?: string): boolean => {
  if (!createdAt) return false;
  const created = new Date(createdAt).getTime();
  if (Number.isNaN(created)) return false;
  return Date.now() - created <= NEW_WINDOW_MS;
};

const formatLocation = (location?: CommunityMemberCard["location"]): string | undefined => {
  if (!location) return undefined;
  if (typeof location === "string") return location || undefined;
  const parts = [location.city, location.country].filter(Boolean);
  return parts.length > 0 ? parts.join(", ") : undefined;
};

/**
 * Only the language bucket describes compatibility -- the others are presence
 * and location facts. Leading with the language reason stops a card reading
 * "Active today - Same country" and making the matching look shallow.
 */
const isLanguageReason = (reason: string): boolean =>
  /^Speaks |^Native /.test(reason);

/**
 * Every reason as an entry, language match first. A plain string is English
 * from the server and is classified by its wording; an entry already knows
 * (localised text cannot be read by an English pattern).
 */
const orderReasons = (reasons: Array<string | ReasonChip>): ReasonChip[] => {
  const chips = reasons
    .map((reason) =>
      typeof reason === "string" ? { text: reason, primary: isLanguageReason(reason) } : reason
    )
    .filter((chip) => chip && chip.text);
  return [...chips.filter((chip) => chip.primary), ...chips.filter((chip) => !chip.primary)];
};

const MemberCardRow: React.FC<MemberCardProps> = ({ user, reasons, compact, onWave, onOpen }) => {
  const age = getAge(user.birth_year);
  const isNew = !!user.isNew || isRecentlyCreated(user.createdAt);
  const locationLabel = formatLocation(user.location);
  const avatar = user.imageUrls?.[0];
  const nativeFlag = languageFlag(user.native_language);
  const learningFlag = languageFlag(user.language_to_learn);
  const orderedReasons = orderReasons(reasons || []);

  const handleWaveClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    onWave(user);
  };

  // The card is the primary control of the row, so it has to answer the
  // keyboard as well as the mouse: without this the whole member list (and
  // the suggestion strip on a profile) is reachable only by pointer. Space is
  // preventDefault'd because its default action scrolls the page.
  const handleCardKeyDown = (e: React.KeyboardEvent) => {
    if (e.key !== "Enter" && e.key !== " ") return;
    if (e.target !== e.currentTarget) return;
    e.preventDefault();
    onOpen(user);
  };

  return (
    <div
      data-testid="member-card-root"
      role="button"
      tabIndex={0}
      aria-label={user.name}
      onClick={() => onOpen(user)}
      onKeyDown={handleCardKeyDown}
      className={
        compact
          ? "flex flex-row items-center gap-3 p-3 bg-white/80 backdrop-blur-xl rounded-2xl shadow-lg border border-white/30 hover:shadow-xl transition-all cursor-pointer"
          : "flex flex-col h-full bg-white/80 backdrop-blur-xl rounded-2xl shadow-lg border border-white/30 overflow-hidden hover:shadow-xl hover:-translate-y-0.5 transition-all cursor-pointer"
      }
    >
      {/* Photo. A grid cell gets a 16:10 banner; a carousel row gets a 56px
          avatar. The width/height are the reserved box, not the painted size. */}
      <div
        data-testid={compact ? "member-card-avatar" : "member-card-photo"}
        className={
          compact
            ? "relative shrink-0 w-14 h-14 rounded-xl overflow-hidden"
            : "relative w-full aspect-[16/10]"
        }
      >
        {avatar ? (
          <img
            src={avatar}
            alt={user.name}
            width={compact ? 56 : 320}
            height={compact ? 56 : 200}
            loading="lazy"
            decoding="async"
            className="block w-full h-full object-cover"
          />
        ) : (
          <div
            data-testid={
              compact ? "member-card-avatar-placeholder" : "member-card-photo-placeholder"
            }
            className={`w-full h-full bg-gradient-to-br from-teal-100 to-yellow-50 flex items-center justify-center font-semibold text-teal-600 ${compact ? "text-lg" : "text-4xl"}`}
          >
            {user.name?.charAt(0)?.toUpperCase() || "?"}
          </div>
        )}
        {user.hasActiveStory && (
          <span
            data-testid="member-card-story-ring"
            className={
              compact
                ? "absolute left-0 top-0 rounded-full ring-2 ring-teal-400 w-2.5 h-2.5 bg-white"
                : "absolute left-2 top-2 rounded-full ring-2 ring-teal-400 w-3 h-3 bg-white"
            }
          />
        )}
        {user.isOnline && (
          <span
            data-testid="member-card-online-dot"
            className={
              compact
                ? "absolute right-0 top-0 w-2.5 h-2.5 rounded-full bg-green-500 border-2 border-white"
                : "absolute right-2 top-2 w-3 h-3 rounded-full bg-green-500 border-2 border-white"
            }
          />
        )}
      </div>

      {/* Info column */}
      <div className={compact ? "flex-1 min-w-0" : "flex-1 min-w-0 p-4"}>
        <div className="flex items-center gap-2">
          <span data-testid="member-card-name" className="font-semibold text-gray-900 truncate min-w-0">
            {user.name}
            {age !== undefined ? `, ${age}` : ""}
          </span>

          {isNew && (
            <span
              data-testid="member-card-new-badge"
              className="shrink-0 text-[10px] font-bold uppercase tracking-wide text-white bg-gradient-to-r from-teal-500 to-cyan-500 rounded-full px-2 py-0.5"
            >
              New
            </span>
          )}

          {user.isVIP && (
            <span
              data-testid="member-card-vip-badge"
              className="shrink-0 text-[10px] font-bold uppercase tracking-wide text-white bg-gradient-to-r from-[#FFD700] to-[#FFA500] rounded-full px-2 py-0.5"
            >
              VIP
            </span>
          )}
        </div>

        {/* Language exchange row */}
        <div className="flex items-center gap-1.5 mt-1 text-sm text-gray-600">
          <span aria-hidden title={user.native_language}>{nativeFlag}</span>
          <ArrowRight className="w-3 h-3 text-gray-400" />
          <span aria-hidden>{learningFlag}</span>
          {user.languageLevel && (
            <span
              data-testid="member-card-level-badge"
              className="ml-1 text-[11px] font-semibold text-teal-700 bg-teal-50 border border-teal-200 rounded-full px-2 py-0.5"
            >
              {user.languageLevel}
            </span>
          )}
        </div>

        {/* Location and bio. In the grid each is a FIXED line, drawn
            whether or not the member filled it in: a card that grew a row
            for every optional field made every card a different height and
            the grid's rows ragged. The compact row keeps them optional. */}
        {(() => {
          const location = locationLabel ? (
            <div
              data-testid="member-card-location"
              className="flex items-center gap-1 text-xs text-gray-500 min-w-0"
            >
              <MapPin className="w-3 h-3 shrink-0" />
              <span className="truncate">{locationLabel}</span>
            </div>
          ) : null;
          const bio = user.bio ? (
            <p className="text-xs text-gray-500 truncate">{user.bio}</p>
          ) : null;
          if (compact) {
            return (
              <>
                {location && <div className="mt-1">{location}</div>}
                {bio && <div className="mt-1">{bio}</div>}
              </>
            );
          }
          return (
            <>
              <div data-testid="member-card-line-location" className="mt-1 h-4 overflow-hidden">
                {location}
              </div>
              <div data-testid="member-card-line-bio" className="mt-1 h-4 overflow-hidden">
                {bio}
              </div>
            </>
          );
        })()}
      </div>

      {/* One line of chips, clipped, and reserved even when empty -- wrapping
          chips were the biggest source of uneven card heights. The order puts
          the language match first, so what is clipped is the least of it. */}
      {!compact && (
        <div data-testid="member-card-line-reasons" className="h-[22px] mb-3 px-4 overflow-hidden">
        {orderedReasons.length > 0 && (
        <div data-testid="member-card-reasons" className="flex flex-nowrap gap-1.5">
          {orderedReasons.map((reason) => {
            const primary = reason.primary;
            return (
              <span
                key={reason.text}
                data-testid={primary ? "member-card-reason-primary" : "member-card-reason-secondary"}
                className={
                  primary
                    ? "shrink-0 whitespace-nowrap text-[11px] font-semibold text-teal-700 bg-teal-50 border border-teal-200 rounded-full px-2 py-0.5"
                    : "shrink-0 whitespace-nowrap text-[11px] text-gray-600 bg-gray-100 border border-gray-200 rounded-full px-2 py-0.5"
                }
              >
                {reason.text}
              </span>
            );
          })}
        </div>
        )}
        </div>
      )}

      {/* Wave button */}
      <button
        type="button"
        data-testid="member-card-wave"
        onClick={handleWaveClick}
        aria-label={`Wave at ${user.name}`}
        className={
          compact
            ? "shrink-0 w-11 h-11 rounded-full flex items-center justify-center text-white bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] hover:brightness-105 active:scale-95 transition-all"
            : "mt-auto w-full min-h-[44px] flex items-center justify-center gap-2 text-white bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] hover:brightness-105 active:scale-[.99] transition-all"
        }
      >
        <span className="text-lg leading-none" aria-hidden>
          👋
        </span>
      </button>
    </div>
  );
};

/**
 * Does this card draw the same row?
 *
 * The list re-renders on every keystroke, every filter edit and every page
 * append; without this every visible card's body re-runs each time. Compared
 * field by field rather than by identity because RTK Query hands out a fresh
 * object for every page, and only the fields this component actually paints
 * are compared -- `gender`, `lastActive` and `followersCount` are on the
 * payload but nowhere on screen, so a change in them is not a reason to draw
 * the row again.
 *
 * Returns true when the props are equivalent, i.e. when React may skip the
 * re-render (React.memo's convention, the inverse of shouldComponentUpdate).
 */
export const areMemberRowsEqual = (
  prev: MemberCardProps,
  next: MemberCardProps
): boolean => {
  // The handlers end up on onClick/onKeyDown, so a new identity is a real
  // difference. Both callers pass useCallback'd ones.
  if (prev.onOpen !== next.onOpen || prev.onWave !== next.onWave) return false;

  // Before the `a === b` fast path below: the list reuses the user object
  // between renders, so a comparison placed after it would never run and the
  // chips would freeze at whatever first rendered.
  if (prev.compact !== next.compact) return false;

  // Entries are compared by what they draw, not by identity: a fresh array of
  // equal chips must not re-render, a changed text or flag must.
  const ra = orderReasons(prev.reasons || []);
  const rb = orderReasons(next.reasons || []);
  if (ra.length !== rb.length) return false;
  if (ra.some((chip, index) => chip.text !== rb[index].text || chip.primary !== rb[index].primary)) {
    return false;
  }

  const a = prev.user;
  const b = next.user;
  if (a === b) return true;

  return (
    a._id === b._id &&
    a.name === b.name &&
    a.bio === b.bio &&
    a.native_language === b.native_language &&
    a.language_to_learn === b.language_to_learn &&
    a.birth_year === b.birth_year &&
    a.createdAt === b.createdAt &&
    a.isNew === b.isNew &&
    a.isVIP === b.isVIP &&
    a.languageLevel === b.languageLevel &&
    a.hasActiveStory === b.hasActiveStory &&
    a.isOnline === b.isOnline &&
    // Only the first image is painted; the rest of the array is not the
    // card's business.
    (a.imageUrls ? a.imageUrls[0] : undefined) ===
      (b.imageUrls ? b.imageUrls[0] : undefined) &&
    formatLocation(a.location) === formatLocation(b.location)
  );
};

const MemberCard = React.memo(MemberCardRow, areMemberRowsEqual);

export default MemberCard;
