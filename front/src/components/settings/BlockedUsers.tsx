import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useGetBlockedUsersQuery, useUnblockUserMutation } from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import { ArrowLeft, UserX, Unlock, Loader2 } from "lucide-react";

interface BlockedUser {
  _id: string;
  name: string;
  imageUrls?: string[];
}

const BlockedUsers: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { data, isLoading, refetch } = useGetBlockedUsersQuery({});
  const [unblockUser, { isLoading: isUnblocking }] = useUnblockUserMutation();

  const blockedUsers: BlockedUser[] = data?.data || [];

  const handleUnblock = async (userId: string, userName: string) => {
    try {
      await unblockUser(userId).unwrap();
      toast.success(
        t("settings.blocked.unblockSuccess", { name: userName }) || `${userName} has been unblocked`,
        {
          position: "top-right",
          autoClose: 2000,
          theme: "dark",
          transition: Bounce,
        }
      );
      refetch();
    } catch (error) {
      toast.error(t("settings.blocked.unblockError") || "Failed to unblock user", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-yellow-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-500 to-teal-600 text-white p-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold">
              {t("settings.blocked.title") || "Blocked Users"}
            </h1>
            <p className="text-teal-100 text-sm">
              {t("settings.blocked.subtitle") || "Manage your blocked accounts"}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin mb-4" />
            <p className="text-gray-500">{t("common.loading") || "Loading..."}</p>
          </div>
        ) : blockedUsers.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20">
            <div className="p-6 rounded-full bg-gray-100 mb-6">
              <UserX className="w-12 h-12 text-gray-400" />
            </div>
            <h3 className="text-xl font-semibold text-gray-800 mb-2">
              {t("settings.blocked.noBlocked") || "No Blocked Users"}
            </h3>
            <p className="text-gray-500 text-center max-w-sm">
              {t("settings.blocked.noBlockedDesc") ||
                "Users you block will appear here. They won't be able to see your profile or message you."}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            <p className="text-sm text-gray-500 mb-4">
              {t("settings.blocked.count", { count: blockedUsers.length }) ||
                `${blockedUsers.length} blocked user(s)`}
            </p>

            {blockedUsers.map((user) => (
              <div
                key={user._id}
                className="flex items-center justify-between p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30"
              >
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-gray-300 to-gray-400 overflow-hidden">
                    {user.imageUrls?.[0] ? (
                      <img
                        src={user.imageUrls[0]}
                        alt={user.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <UserX className="w-6 h-6 text-white" />
                      </div>
                    )}
                  </div>
                  <div>
                    <p className="font-medium text-gray-800">{user.name}</p>
                    <p className="text-sm text-gray-500">
                      {t("settings.blocked.blockedLabel") || "Blocked"}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => handleUnblock(user._id, user.name)}
                  disabled={isUnblocking}
                  className="flex items-center gap-2 px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors disabled:opacity-50"
                >
                  <Unlock className="w-4 h-4" />
                  {t("settings.blocked.unblock") || "Unblock"}
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default BlockedUsers;
