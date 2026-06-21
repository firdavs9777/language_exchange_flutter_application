import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useSearchUsersQuery,
  useSearchUsersByUsernameQuery,
  useGetUserByIdQuery,
} from "../../store/slices/usersSlice";
import { useCreateChatRoomMutation } from "../../store/slices/chatSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Search,
  MessageCircle,
  Clock,
  Loader2,
  UserPlus,
  AtSign,
  Hash,
} from "lucide-react";

interface User {
  _id: string;
  name: string;
  username?: string;
  imageUrls?: string[];
  isOnline?: boolean;
  lastSeen?: string;
}

// Detect if input looks like a MongoDB ObjectId (24 hex chars)
const isObjectId = (str: string) => /^[a-f\d]{24}$/i.test(str.trim());

// Detect if input starts with @ (username search)
const isUsernameQuery = (str: string) => str.trim().startsWith("@");

const NewChat: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [searchQuery, setSearchQuery] = useState("");

  const trimmedQuery = searchQuery.trim();
  const searchByUsername = isUsernameQuery(trimmedQuery);
  const searchById = isObjectId(trimmedQuery);
  const searchByName = !searchByUsername && !searchById && trimmedQuery.length >= 2;

  // Name search
  const { data: nameSearchData, isLoading: isNameSearching } = useSearchUsersQuery(
    { query: trimmedQuery },
    { skip: !searchByName }
  );

  // Username search (when query starts with @)
  const { data: usernameSearchData, isLoading: isUsernameSearching } = useSearchUsersByUsernameQuery(
    { query: trimmedQuery },
    { skip: !searchByUsername || trimmedQuery.replace("@", "").length < 1 }
  );

  // ID search (when query is a valid ObjectId)
  const { data: idSearchData, isLoading: isIdSearching } = useGetUserByIdQuery(
    trimmedQuery,
    { skip: !searchById }
  );

  const [createChatRoom, { isLoading: isCreating }] = useCreateChatRoomMutation();

  // Merge results from all search types
  const getSearchResults = (): User[] => {
    if (searchByName) return nameSearchData?.data || [];
    if (searchByUsername) return usernameSearchData?.data || [];
    if (searchById && idSearchData?.data) {
      const user = idSearchData.data;
      return [user];
    }
    return [];
  };

  const searchResults = getSearchResults();
  const isSearching = isNameSearching || isUsernameSearching || isIdSearching;
  const hasQuery = searchByName || searchByUsername || searchById;

  const handleSelectUser = (user: User) => {
    handleCreateChat(user);
  };

  const handleCreateChat = async (user: User) => {
    try {
      // Backend expects { userId: string } for 1-on-1 chat. Group chat isn't
      // implemented server-side (isGroupMessage:false everywhere) so we never
      // try to bundle multiple users into one createChatRoom call.
      const result = await createChatRoom(user._id).unwrap();

      const chatId = result?.data?._id;
      if (chatId) {
        navigate(`/chat/${chatId}`);
      } else {
        // Fall back to navigating with the user id; ChatContent fetches by id.
        navigate(`/chat/${user._id}`);
      }
    } catch (error: any) {
      const message =
        error?.data?.error ||
        error?.data?.message ||
        t("newChat.createError") ||
        "Failed to create chat";
      toast.error(message, {
        position: "top-right",
        autoClose: 3000,
        theme: "colored",
        transition: Bounce,
      });
    }
  };

  const formatLastSeen = (lastSeen?: string) => {
    if (!lastSeen) return "";
    const date = new Date(lastSeen);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return t("chatPage.daysAgo", { count: days }) || `${days}d ago`;
    }
    if (hours > 0) {
      return t("chatPage.hoursAgo", { count: hours }) || `${hours}h ago`;
    }
    if (minutes > 0) {
      return t("chatPage.minutesAgo", { count: minutes }) || `${minutes}m ago`;
    }
    return t("chatPage.justNow") || t("newChat.recently") || "Just now";
  };

  // Search mode indicator
  const getSearchMode = () => {
    if (searchByUsername) return { icon: <AtSign className="w-4 h-4" />, label: t("newChat.searchByUsername") || "Searching by username" };
    if (searchById) return { icon: <Hash className="w-4 h-4" />, label: t("newChat.searchById") || "Searching by user ID" };
    return null;
  };

  const searchMode = hasQuery ? getSearchMode() : null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-500 to-blue-500 text-white p-6 pb-8">
        <div className="flex items-center gap-4 mb-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold">
              {t("newChat.title") || "New Chat"}
            </h1>
            <p className="text-teal-100 text-sm">
              {t("newChat.subtitle") || "Start a conversation"}
            </p>
          </div>
        </div>

        {/* Group chat toggle removed — backend createConversationRoom only
            supports 1-on-1 conversations (isGroupMessage:false). */}

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-white/60" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={t("newChat.searchPlaceholder") || "Search by name, @username, or user ID..."}
            className="w-full pl-12 pr-4 py-3 bg-white/20 rounded-xl text-white placeholder-white/60 focus:outline-none focus:bg-white/30 transition-colors"
          />
        </div>

        {/* Search mode indicator */}
        {searchMode && (
          <div className="flex items-center gap-2 mt-2 text-teal-100 text-xs">
            {searchMode.icon}
            <span>{searchMode.label}</span>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {!hasQuery ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-teal-100 w-fit mx-auto mb-4">
              <UserPlus className="w-8 h-8 text-teal-500" />
            </div>
            <p className="text-gray-600 font-medium mb-2">
              {t("newChat.searchHint") || "Search for users to start a chat"}
            </p>
            <div className="flex flex-col items-center gap-1.5 text-sm text-gray-400 mt-4">
              <div className="flex items-center gap-2">
                <Search className="w-3.5 h-3.5" />
                <span>{t("newChat.hintName") || "Search by name"}</span>
              </div>
              <div className="flex items-center gap-2">
                <AtSign className="w-3.5 h-3.5" />
                <span>{t("newChat.hintUsername") || "Type @username to find by username"}</span>
              </div>
              <div className="flex items-center gap-2">
                <Hash className="w-3.5 h-3.5" />
                <span>{t("newChat.hintId") || "Paste a user ID to find directly"}</span>
              </div>
            </div>
          </div>
        ) : isSearching ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
          </div>
        ) : searchResults.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-gray-100 w-fit mx-auto mb-4">
              <Search className="w-8 h-8 text-gray-400" />
            </div>
            <p className="text-gray-500">
              {t("newChat.noResults") || "No users found"}
            </p>
            <p className="text-gray-400 text-sm mt-1">
              {t("newChat.tryDifferent") || "Try a different name, @username, or user ID"}
            </p>
          </div>
        ) : (
          <div className="space-y-2">
            {searchResults.map((user) => (
              <button
                key={user._id}
                onClick={() => handleSelectUser(user)}
                disabled={isCreating}
                className="w-full flex items-center gap-4 p-4 rounded-xl border bg-white/60 backdrop-blur-sm border-white/30 hover:bg-white/80 transition-all disabled:opacity-50"
              >
                <div className="relative">
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 overflow-hidden">
                    {user.imageUrls?.[0] ? (
                      <img
                        src={user.imageUrls[0]}
                        alt={user.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-white text-lg font-bold">
                        {user.name?.[0]}
                      </div>
                    )}
                  </div>
                  {user.isOnline && (
                    <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-white rounded-full" />
                  )}
                </div>

                <div className="flex-1 text-left">
                  <h3 className="font-semibold text-gray-800">{user.name}</h3>
                  {user.username && (
                    <p className="text-xs text-teal-500 font-medium">@{user.username}</p>
                  )}
                  <p className="text-sm text-gray-500 flex items-center gap-1">
                    {user.isOnline ? (
                      <span className="text-green-500">{t("chatPage.online") || "Online"}</span>
                    ) : user.lastSeen ? (
                      <>
                        <Clock className="w-3 h-3" />
                        {formatLastSeen(user.lastSeen)}
                      </>
                    ) : null}
                  </p>
                </div>

                {isCreating ? (
                  <Loader2 className="w-5 h-5 text-teal-500 animate-spin" />
                ) : (
                  <MessageCircle className="w-5 h-5 text-teal-500" />
                )}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default NewChat;
