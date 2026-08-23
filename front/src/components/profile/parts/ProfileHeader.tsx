import React from "react";
import { Pencil } from "lucide-react";

interface ProfileHeaderProps {
  name: string;
  username?: string;
  avatarUrl?: string;
  isOnline?: boolean;
  onEdit?: () => void;
}

const ProfileHeader: React.FC<ProfileHeaderProps> = ({
  name,
  username,
  avatarUrl,
  isOnline,
  onEdit,
}) => {
  const hasAvatar = Boolean(avatarUrl && avatarUrl.trim());
  const initial = (name?.trim()?.[0] || "?").toUpperCase();

  return (
    <div className="relative rounded-2xl overflow-hidden shadow-lg">
      {/* Teal gradient banner */}
      <div className="h-28 bg-gradient-to-r from-teal-400 via-teal-500 to-teal-600" />

      {onEdit && (
        <button
          type="button"
          onClick={onEdit}
          aria-label="Edit profile"
          className="absolute top-3 right-3 p-2 rounded-full bg-white/20 hover:bg-white/30 text-white backdrop-blur-sm transition-colors"
        >
          <Pencil className="w-4 h-4" />
        </button>
      )}

      <div className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl px-4 pb-4 pt-0 border-t border-white/30 dark:border-gray-700/30">
        <div className="-mt-10 flex items-end gap-3">
          <div className="relative">
            {hasAvatar ? (
              <img
                src={avatarUrl}
                alt={name}
                className="w-20 h-20 rounded-full object-cover ring-4 ring-white dark:ring-gray-800"
              />
            ) : (
              <div
                data-testid="avatar-initials"
                className="w-20 h-20 rounded-full flex items-center justify-center text-2xl font-bold text-white ring-4 ring-white dark:ring-gray-800 bg-gradient-to-br from-teal-400 via-sky-400 to-purple-500"
              >
                {initial}
              </div>
            )}
            {isOnline && (
              <span
                data-testid="online-dot"
                aria-label="online"
                className="absolute bottom-1 right-1 w-4 h-4 rounded-full bg-green-500 ring-2 ring-white dark:ring-gray-800"
              />
            )}
          </div>

          <div className="pb-1 leading-tight">
            <h2 className="text-lg font-bold text-gray-900 dark:text-gray-50">{name}</h2>
            {username && (
              <p className="text-sm text-gray-500 dark:text-gray-400">@{username}</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProfileHeader;
