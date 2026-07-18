import React from "react";
import { MapPin, ArrowRight } from "lucide-react";
import { LANGUAGE_FLAGS, LANGUAGE_CODES } from "./type";

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
  onWave: (user: CommunityMemberCard) => void;
  onOpen: (user: CommunityMemberCard) => void;
}

const NEW_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

const getLanguageCode = (language?: string): string => {
  if (!language) return "";
  return LANGUAGE_CODES[language] || language.substring(0, 2).toLowerCase();
};

const getFlag = (language?: string): string => {
  const code = getLanguageCode(language);
  return LANGUAGE_FLAGS[code] || "🌐";
};

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

const MemberCard: React.FC<MemberCardProps> = ({ user, onWave, onOpen }) => {
  const age = getAge(user.birth_year);
  const isNew = !!user.isNew || isRecentlyCreated(user.createdAt);
  const locationLabel = formatLocation(user.location);
  const avatar = user.imageUrls?.[0];
  const nativeFlag = getFlag(user.native_language);
  const learningFlag = getFlag(user.language_to_learn);

  const handleWaveClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    onWave(user);
  };

  return (
    <div
      data-testid="member-card-root"
      onClick={() => onOpen(user)}
      className="flex items-center gap-4 bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 hover:shadow-xl hover:-translate-y-0.5 transition-all cursor-pointer"
    >
      {/* Avatar */}
      <div className="relative shrink-0 w-[72px] h-[72px]">
        <div
          data-testid={user.hasActiveStory ? "member-card-story-ring" : undefined}
          className={
            user.hasActiveStory
              ? "absolute inset-0 rounded-[22px] bg-gradient-to-tr from-[#00BFA5] via-[#FFD700] to-[#00ACC1] p-[3px]"
              : ""
          }
        >
          <div
            className={
              user.hasActiveStory
                ? "w-full h-full rounded-[19px] bg-white p-[2px] overflow-hidden"
                : "w-full h-full rounded-[22px] overflow-hidden"
            }
          >
            {avatar ? (
              <img
                src={avatar}
                alt={user.name}
                className="w-full h-full object-cover rounded-[19px]"
              />
            ) : (
              <div className="w-full h-full rounded-[19px] bg-gradient-to-br from-teal-100 to-yellow-50 flex items-center justify-center text-2xl font-semibold text-teal-600">
                {user.name?.[0]?.toUpperCase() || "?"}
              </div>
            )}
          </div>
        </div>

        {/* Native-language flag overlay */}
        <span
          className="absolute -bottom-1 -left-1 text-base leading-none bg-white rounded-full w-6 h-6 flex items-center justify-center shadow border border-white"
          aria-hidden
          title={user.native_language}
        >
          {nativeFlag}
        </span>

        {/* Online dot */}
        {user.isOnline && (
          <span
            data-testid="member-card-online-dot"
            className="absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full bg-green-500 border-2 border-white"
            aria-label="Online"
          />
        )}
      </div>

      {/* Info column */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <span data-testid="member-card-name" className="font-semibold text-gray-900 truncate">
            {user.name}
            {age !== undefined ? `, ${age}` : ""}
          </span>

          {isNew && (
            <span
              data-testid="member-card-new-badge"
              className="text-[10px] font-bold uppercase tracking-wide text-white bg-gradient-to-r from-teal-500 to-cyan-500 rounded-full px-2 py-0.5"
            >
              New
            </span>
          )}

          {user.isVIP && (
            <span
              data-testid="member-card-vip-badge"
              className="text-[10px] font-bold uppercase tracking-wide text-white bg-gradient-to-r from-[#FFD700] to-[#FFA500] rounded-full px-2 py-0.5"
            >
              VIP
            </span>
          )}
        </div>

        {/* Language exchange row */}
        <div className="flex items-center gap-1.5 mt-1 text-sm text-gray-600">
          <span aria-hidden>{nativeFlag}</span>
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

        {/* Location row */}
        {locationLabel && (
          <div
            data-testid="member-card-location"
            className="flex items-center gap-1 mt-1 text-xs text-gray-500"
          >
            <MapPin className="w-3 h-3" />
            <span className="truncate">{locationLabel}</span>
          </div>
        )}

        {/* Bio */}
        {user.bio && (
          <p className="mt-1 text-xs text-gray-500 truncate">{user.bio}</p>
        )}
      </div>

      {/* Wave button */}
      <button
        type="button"
        data-testid="member-card-wave-button"
        onClick={handleWaveClick}
        aria-label={`Wave at ${user.name}`}
        className="shrink-0 flex items-center justify-center w-11 h-11 rounded-full text-white bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] shadow-md hover:shadow-lg hover:scale-105 active:scale-95 transition-all"
      >
        <span className="text-lg leading-none" aria-hidden>
          👋
        </span>
      </button>
    </div>
  );
};

export default MemberCard;
