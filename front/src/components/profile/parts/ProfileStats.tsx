import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Image as ImageIcon, UserPlus, Users } from "lucide-react";

export interface ProfileStatsProps {
  /** The profile owner. Absent only while the own profile is still loading. */
  userId?: string;
  isOwn: boolean;
  followers: number;
  following: number;
  moments: number;
}

/**
 * Followers / Following / Moments as three tappable tiles.
 *
 * Each tile is a `Link`, not a button with an onClick: the whole tile is then
 * a real target that can be opened in a new tab, and the destination is
 * visible in the status bar before the tap.
 */
const ProfileStats: React.FC<ProfileStatsProps> = ({
  userId,
  isOwn,
  followers,
  following,
  moments,
}) => {
  const { t } = useTranslation();

  // The per-user list routes arrive with the list page; until an id is known
  // (an own profile mid-load) the existing own-list routes still work.
  const followersTo = userId ? `/profile/${userId}/followers` : "/followersList";
  const followingTo = userId ? `/profile/${userId}/following` : "/followingsList";
  const momentsTo = isOwn || !userId ? "/my-moments" : `/profile/${userId}#moments`;

  const tiles = [
    {
      key: "followers",
      icon: Users,
      value: followers,
      label: t("profile.stats.followers") || "Followers",
      to: followersTo,
    },
    {
      key: "following",
      icon: UserPlus,
      value: following,
      label: t("profile.stats.following") || "Following",
      to: followingTo,
    },
    {
      key: "moments",
      icon: ImageIcon,
      value: moments,
      label: t("profile.stats.moments") || "Moments",
      to: momentsTo,
    },
  ];

  return (
    <div className="grid grid-cols-3 gap-2">
      {tiles.map((tile) => {
        const Icon = tile.icon;
        return (
          <Link
            key={tile.key}
            to={tile.to}
            data-testid={`stat-${tile.key}`}
            className="flex flex-col items-center gap-1 rounded-card bg-surface py-3 shadow-card transition-shadow hover:shadow-raised dark:bg-cardbg-dark dark:shadow-none"
          >
            <Icon className="h-4 w-4 text-brand" aria-hidden />
            <span className="font-display text-lg text-ink-900 dark:text-ink-50">
              {tile.value}
            </span>
            <span className="text-[11px] text-ink-500 dark:text-ink-400">{tile.label}</span>
          </Link>
        );
      })}
    </div>
  );
};

export default ProfileStats;
