import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RootState } from "../../store";
import {
  useGetTopicsQuery,
  useGetUsersByTopicQuery,
  useUpdateMyTopicsMutation,
} from "../../store/slices/communitySlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Hash,
  Users,
  Check,
  Loader2,
  Search,
  ChevronRight,
  Sparkles,
} from "lucide-react";

interface Topic {
  _id: string;
  name: string;
  icon?: string;
  category?: string;
  userCount: number;
}

interface TopicUser {
  _id: string;
  name: string;
  imageUrls?: string[];
  isOnline?: boolean;
}

const TOPIC_ICONS: { [key: string]: string } = {
  music: "🎵",
  movies: "🎬",
  travel: "✈️",
  food: "🍕",
  sports: "⚽",
  gaming: "🎮",
  reading: "📚",
  art: "🎨",
  photography: "📷",
  fitness: "💪",
  technology: "💻",
  fashion: "👗",
  nature: "🌿",
  pets: "🐾",
  cooking: "👨‍🍳",
  languages: "🌍",
  default: "💬",
};

const Topics: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const myTopics: string[] = userInfo?.user?.interests || [];

  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTopic, setSelectedTopic] = useState<Topic | null>(null);
  const [editMode, setEditMode] = useState(false);
  const [selectedTopics, setSelectedTopics] = useState<string[]>(myTopics);

  const { data: topicsData, isLoading: isLoadingTopics } = useGetTopicsQuery({});
  const { data: usersData, isLoading: isLoadingUsers } = useGetUsersByTopicQuery(
    selectedTopic?._id || "",
    { skip: !selectedTopic }
  );
  const [updateMyTopics, { isLoading: isUpdating }] = useUpdateMyTopicsMutation();

  const topics: Topic[] = topicsData?.data || [];
  const topicUsers: TopicUser[] = usersData?.data || [];

  const filteredTopics = topics.filter((topic) =>
    topic.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getTopicIcon = (topic: Topic) => {
    if (topic.icon) return topic.icon;
    const key = topic.name.toLowerCase();
    return TOPIC_ICONS[key] || TOPIC_ICONS.default;
  };

  const handleToggleTopic = (topicId: string) => {
    setSelectedTopics((prev) =>
      prev.includes(topicId)
        ? prev.filter((id) => id !== topicId)
        : [...prev, topicId]
    );
  };

  const handleSaveTopics = async () => {
    try {
      await updateMyTopics({ topics: selectedTopics }).unwrap();
      toast.success(t("community.topics.updateSuccess") || "Topics updated!", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setEditMode(false);
    } catch (error) {
      toast.error(t("community.topics.updateError") || "Failed to update topics", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  if (selectedTopic) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50">
        {/* Header */}
        <div className="bg-gradient-to-r from-indigo-500 to-purple-500 text-white p-6">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setSelectedTopic(null)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div className="flex items-center gap-3">
              <span className="text-3xl">{getTopicIcon(selectedTopic)}</span>
              <div>
                <h1 className="text-xl font-bold">{selectedTopic.name}</h1>
                <p className="text-indigo-100 text-sm">
                  {selectedTopic.userCount} {t("community.topics.members") || "members"}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Users */}
        <div className="px-4 py-6 max-w-2xl mx-auto">
          {isLoadingUsers ? (
            <div className="flex justify-center py-12">
              <Loader2 className="w-10 h-10 text-indigo-500 animate-spin" />
            </div>
          ) : topicUsers.length === 0 ? (
            <div className="text-center py-12">
              <div className="p-4 rounded-full bg-indigo-100 w-fit mx-auto mb-4">
                <Users className="w-8 h-8 text-indigo-500" />
              </div>
              <p className="text-gray-500">
                {t("community.topics.noUsersInTopic") || "No users found in this topic"}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
              {topicUsers.map((user) => (
                <button
                  key={user._id}
                  onClick={() => navigate(`/user/${user._id}`)}
                  className="flex flex-col items-center p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 hover:bg-white/80 hover:shadow-lg transition-all"
                >
                  <div className="relative mb-2">
                    <div className="w-16 h-16 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 overflow-hidden">
                      {user.imageUrls?.[0] ? (
                        <img
                          src={user.imageUrls[0]}
                          alt={user.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-white text-xl font-bold">
                          {user.name?.[0]}
                        </div>
                      )}
                    </div>
                    {user.isOnline && (
                      <div className="absolute bottom-0 right-0 w-4 h-4 bg-green-500 border-2 border-white rounded-full" />
                    )}
                  </div>
                  <h3 className="font-medium text-gray-800 text-center truncate w-full">
                    {user.name}
                  </h3>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-indigo-500 to-purple-500 text-white p-6 pb-8">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-xl font-bold flex items-center gap-2">
                <Hash className="w-6 h-6" />
                {t("community.topics.title") || "Topics"}
              </h1>
              <p className="text-indigo-100 text-sm">
                {t("community.topics.subtitle") || "Find people by interests"}
              </p>
            </div>
          </div>
          {!editMode ? (
            <button
              onClick={() => setEditMode(true)}
              className="px-4 py-2 bg-white/20 rounded-lg font-medium hover:bg-white/30 transition-colors"
            >
              {t("community.topics.edit") || "Edit"}
            </button>
          ) : (
            <button
              onClick={handleSaveTopics}
              disabled={isUpdating}
              className="px-4 py-2 bg-white text-indigo-600 rounded-lg font-medium hover:bg-white/90 transition-colors disabled:opacity-50"
            >
              {isUpdating ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                t("community.topics.save") || "Save"
              )}
            </button>
          )}
        </div>

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-white/60" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={t("community.topics.searchPlaceholder") || "Search topics..."}
            className="w-full pl-12 pr-4 py-3 bg-white/20 rounded-xl text-white placeholder-white/60 focus:outline-none focus:bg-white/30 transition-colors"
          />
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {/* My Topics */}
        {myTopics.length > 0 && !editMode && (
          <div className="mb-8">
            <h2 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-yellow-500" />
              {t("community.topics.myTopics") || "My Topics"}
            </h2>
            <div className="flex flex-wrap gap-2">
              {topics
                .filter((t) => myTopics.includes(t._id))
                .map((topic) => (
                  <button
                    key={topic._id}
                    onClick={() => setSelectedTopic(topic)}
                    className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-full font-medium hover:shadow-lg transition-all"
                  >
                    <span>{getTopicIcon(topic)}</span>
                    {topic.name}
                  </button>
                ))}
            </div>
          </div>
        )}

        {/* All Topics */}
        <div>
          <h2 className="text-lg font-bold text-gray-800 mb-4">
            {editMode
              ? t("community.topics.selectTopics") || "Select Your Topics"
              : t("community.topics.allTopics") || "All Topics"}
          </h2>

          {isLoadingTopics ? (
            <div className="flex justify-center py-12">
              <Loader2 className="w-10 h-10 text-indigo-500 animate-spin" />
            </div>
          ) : filteredTopics.length === 0 ? (
            <div className="text-center py-12">
              <div className="p-4 rounded-full bg-indigo-100 w-fit mx-auto mb-4">
                <Hash className="w-8 h-8 text-indigo-500" />
              </div>
              <p className="text-gray-500">
                {t("community.topics.noTopicsFound") || "No topics found"}
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {filteredTopics.map((topic) => {
                const isSelected = editMode
                  ? selectedTopics.includes(topic._id)
                  : myTopics.includes(topic._id);

                return (
                  <button
                    key={topic._id}
                    onClick={() =>
                      editMode ? handleToggleTopic(topic._id) : setSelectedTopic(topic)
                    }
                    className={`w-full flex items-center gap-4 p-4 rounded-xl border transition-all ${
                      isSelected
                        ? "bg-indigo-50 border-indigo-300"
                        : "bg-white/60 backdrop-blur-sm border-white/30 hover:bg-white/80"
                    }`}
                  >
                    <span className="text-2xl">{getTopicIcon(topic)}</span>
                    <div className="flex-1 text-left">
                      <h3 className="font-semibold text-gray-800">{topic.name}</h3>
                      <p className="text-sm text-gray-500">
                        {topic.userCount} {t("community.topics.members") || "members"}
                      </p>
                    </div>
                    {editMode ? (
                      <div
                        className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors ${
                          isSelected
                            ? "bg-indigo-500 border-indigo-500"
                            : "border-gray-300"
                        }`}
                      >
                        {isSelected && <Check className="w-4 h-4 text-white" />}
                      </div>
                    ) : (
                      <ChevronRight className="w-5 h-5 text-gray-400" />
                    )}
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Edit Mode Footer */}
      {editMode && (
        <div className="fixed bottom-0 left-0 right-0 p-4 bg-white border-t">
          <div className="max-w-2xl mx-auto flex gap-3">
            <button
              onClick={() => {
                setSelectedTopics(myTopics);
                setEditMode(false);
              }}
              className="flex-1 py-3 bg-gray-100 text-gray-600 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
            >
              {t("community.topics.cancel") || "Cancel"}
            </button>
            <button
              onClick={handleSaveTopics}
              disabled={isUpdating}
              className="flex-1 py-3 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all disabled:opacity-50"
            >
              {isUpdating
                ? t("community.topics.saving") || "Saving..."
                : `${t("community.topics.save") || "Save"} (${selectedTopics.length})`}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default Topics;
