import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RootState } from "../../store";
import {
  useGetCloseFriendsQuery,
  useRemoveCloseFriendMutation,
} from "../../store/slices/storiesSlice";
import { useGetFollowingsQuery } from "../../store/slices/usersSlice";
import { useAddCloseFriendMutation } from "../../store/slices/storiesSlice";
import { Bounce, toast } from "react-toastify";
import { ArrowLeft, Users, UserMinus, UserPlus, Search, Loader2, Star } from "lucide-react";

interface User {
  _id: string;
  name: string;
  imageUrls?: string[];
}

const CloseFriends: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const userId = userInfo?.user?._id;

  const [searchQuery, setSearchQuery] = useState("");
  const [showAddModal, setShowAddModal] = useState(false);

  const { data: closeFriendsData, isLoading, refetch } = useGetCloseFriendsQuery({});
  const { data: followingsData } = useGetFollowingsQuery({ userId: userId || "" }, { skip: !userId });
  const [removeCloseFriend, { isLoading: isRemoving }] = useRemoveCloseFriendMutation();
  const [addCloseFriend, { isLoading: isAdding }] = useAddCloseFriendMutation();

  const closeFriends: User[] = closeFriendsData?.data || [];
  const followings: User[] = followingsData?.data || [];

  // Filter followings that are not already close friends
  const availableToAdd = followings.filter(
    (f) => !closeFriends.some((cf) => cf._id === f._id)
  );

  const filteredAvailableToAdd = availableToAdd.filter((user) =>
    user.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleRemove = async (friendId: string, friendName: string) => {
    try {
      await removeCloseFriend(friendId).unwrap();
      toast.success(
        t("settings.closeFriends.removeSuccess", { name: friendName }) ||
          `${friendName} removed from close friends`,
        {
          position: "top-right",
          autoClose: 2000,
          theme: "dark",
          transition: Bounce,
        }
      );
      refetch();
    } catch (error) {
      toast.error(t("settings.closeFriends.removeError") || "Failed to remove", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleAdd = async (friendId: string, friendName: string) => {
    try {
      await addCloseFriend(friendId).unwrap();
      toast.success(
        t("settings.closeFriends.addSuccess", { name: friendName }) ||
          `${friendName} added to close friends`,
        {
          position: "top-right",
          autoClose: 2000,
          theme: "dark",
          transition: Bounce,
        }
      );
      refetch();
      setShowAddModal(false);
    } catch (error) {
      toast.error(t("settings.closeFriends.addError") || "Failed to add", {
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
      <div className="bg-gradient-to-r from-green-500 to-teal-500 text-white p-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold">
              {t("settings.closeFriends.title") || "Close Friends"}
            </h1>
            <p className="text-green-100 text-sm">
              {t("settings.closeFriends.subtitle") || "Share stories with select people"}
            </p>
          </div>
          <button
            onClick={() => setShowAddModal(true)}
            className="p-2 bg-white/20 rounded-lg hover:bg-white/30 transition-colors"
          >
            <UserPlus className="w-6 h-6" />
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {/* Info Card */}
        <div className="bg-green-50 border border-green-200 rounded-xl p-4 mb-6">
          <div className="flex items-start gap-3">
            <Star className="w-5 h-5 text-green-600 mt-0.5" />
            <div>
              <p className="text-sm text-green-800">
                {t("settings.closeFriends.info") ||
                  "Close friends can see stories you share only with them. They won't know they're on your list."}
              </p>
            </div>
          </div>
        </div>

        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="w-10 h-10 text-green-500 animate-spin mb-4" />
            <p className="text-gray-500">{t("common.loading") || "Loading..."}</p>
          </div>
        ) : closeFriends.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20">
            <div className="p-6 rounded-full bg-green-100 mb-6">
              <Users className="w-12 h-12 text-green-500" />
            </div>
            <h3 className="text-xl font-semibold text-gray-800 mb-2">
              {t("settings.closeFriends.noFriends") || "No Close Friends Yet"}
            </h3>
            <p className="text-gray-500 text-center max-w-sm mb-6">
              {t("settings.closeFriends.noFriendsDesc") ||
                "Add people to your close friends list to share private stories with them."}
            </p>
            <button
              onClick={() => setShowAddModal(true)}
              className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-green-500 to-teal-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
            >
              <UserPlus className="w-5 h-5" />
              {t("settings.closeFriends.addFriends") || "Add Close Friends"}
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            <p className="text-sm text-gray-500 mb-4">
              {t("settings.closeFriends.count", { count: closeFriends.length }) ||
                `${closeFriends.length} close friend(s)`}
            </p>

            {closeFriends.map((friend) => (
              <div
                key={friend._id}
                className="flex items-center justify-between p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30"
              >
                <div className="flex items-center gap-4">
                  <div className="relative">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-green-400 to-teal-500 overflow-hidden ring-2 ring-green-400">
                      {friend.imageUrls?.[0] ? (
                        <img
                          src={friend.imageUrls[0]}
                          alt={friend.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center">
                          <Users className="w-6 h-6 text-white" />
                        </div>
                      )}
                    </div>
                    <Star className="absolute -bottom-1 -right-1 w-5 h-5 text-green-500 fill-green-500" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-800">{friend.name}</p>
                    <p className="text-sm text-green-600">
                      {t("settings.closeFriends.closeFriendLabel") || "Close Friend"}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => handleRemove(friend._id, friend.name)}
                  disabled={isRemoving}
                  className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-600 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50"
                >
                  <UserMinus className="w-4 h-4" />
                  {t("settings.closeFriends.remove") || "Remove"}
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center">
          <div className="bg-white w-full sm:w-96 sm:rounded-2xl rounded-t-2xl max-h-[80vh] overflow-hidden">
            <div className="p-4 border-b">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold">
                  {t("settings.closeFriends.addTitle") || "Add Close Friends"}
                </h3>
                <button
                  onClick={() => setShowAddModal(false)}
                  className="text-gray-500 hover:text-gray-700"
                >
                  &times;
                </button>
              </div>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  placeholder={t("settings.closeFriends.searchPlaceholder") || "Search following..."}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500"
                />
              </div>
            </div>
            <div className="overflow-y-auto max-h-96 p-4">
              {filteredAvailableToAdd.length === 0 ? (
                <p className="text-center text-gray-500 py-8">
                  {t("settings.closeFriends.noResults") || "No users found"}
                </p>
              ) : (
                <div className="space-y-2">
                  {filteredAvailableToAdd.map((user) => (
                    <button
                      key={user._id}
                      onClick={() => handleAdd(user._id, user.name)}
                      disabled={isAdding}
                      className="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
                    >
                      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-gray-300 to-gray-400 overflow-hidden">
                        {user.imageUrls?.[0] ? (
                          <img
                            src={user.imageUrls[0]}
                            alt={user.name}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center">
                            <Users className="w-5 h-5 text-white" />
                          </div>
                        )}
                      </div>
                      <span className="flex-1 text-left font-medium">{user.name}</span>
                      <UserPlus className="w-5 h-5 text-green-500" />
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CloseFriends;
