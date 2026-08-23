import React from "react";
import { Users, UserPlus, Image as ImageIcon, Eye, Lock, LucideIcon } from "lucide-react";

interface StatsRowProps {
  followers: number;
  following: number;
  moments: number;
  visitors: number | string;
  isVip: boolean;
  onFollowers?: () => void;
  onFollowing?: () => void;
  onVisitors?: () => void;
}

interface Tile {
  key: string;
  icon: LucideIcon;
  value: React.ReactNode;
  label: string;
  onClick?: () => void;
  locked?: boolean;
}

const StatsRow: React.FC<StatsRowProps> = ({
  followers,
  following,
  moments,
  visitors,
  isVip,
  onFollowers,
  onFollowing,
  onVisitors,
}) => {
  const visitorLocked = !isVip;

  const tiles: Tile[] = [
    { key: "followers", icon: Users, value: followers, label: "Followers", onClick: onFollowers },
    { key: "following", icon: UserPlus, value: following, label: "Following", onClick: onFollowing },
    { key: "moments", icon: ImageIcon, value: moments, label: "Moments" },
    {
      key: "visitors",
      icon: visitorLocked ? Lock : Eye,
      value: isVip ? visitors : "VIP",
      label: "Visitors",
      onClick: onVisitors,
      locked: visitorLocked,
    },
  ];

  return (
    <div className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl rounded-2xl p-3 shadow-lg border border-white/30 dark:border-gray-700/30">
      <div className="grid grid-cols-4 gap-2">
        {tiles.map(({ key, icon: Icon, value, label, onClick, locked }) => (
          <button
            key={key}
            type="button"
            data-testid={`stat-${key}`}
            onClick={onClick}
            disabled={!onClick}
            className="flex flex-col items-center gap-1 py-2 rounded-xl transition-colors enabled:hover:bg-teal-50 dark:enabled:hover:bg-teal-900/30 disabled:cursor-default"
          >
            <Icon
              className={`w-5 h-5 ${
                locked ? "text-amber-500 dark:text-amber-400" : "text-teal-500 dark:text-teal-400"
              }`}
            />
            <span
              className={`text-base font-bold ${
                locked
                  ? "text-amber-600 dark:text-amber-400"
                  : "text-gray-900 dark:text-gray-50"
              }`}
            >
              {value}
            </span>
            <span className="text-[11px] text-gray-500 dark:text-gray-400">{label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default StatsRow;
