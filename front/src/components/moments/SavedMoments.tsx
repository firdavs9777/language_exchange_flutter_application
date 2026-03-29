import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetSavedMomentsQuery,
  useUnsaveMomentMutation,
} from "../../store/slices/momentsSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Bookmark,
  BookmarkMinus,
  Heart,
  MessageCircle,
  Loader2,
  Grid,
  List,
  MoreVertical,
} from "lucide-react";

interface SavedMoment {
  _id: string;
  content?: string;
  imageUrls?: string[];
  videoUrls?: string[];
  likesCount: number;
  commentsCount: number;
  createdAt: string;
  user: {
    _id: string;
    name: string;
    imageUrls?: string[];
  };
}

const SavedMoments: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");
  const [menuOpen, setMenuOpen] = useState<string | null>(null);

  const { data, isLoading, refetch } = useGetSavedMomentsQuery({});
  const [unsaveMoment, { isLoading: isUnsaving }] = useUnsaveMomentMutation();

  const savedMoments: SavedMoment[] = data?.data || [];

  const handleUnsave = async (momentId: string) => {
    try {
      await unsaveMoment(momentId).unwrap();
      toast.success(t("moments.saved.removeSuccess") || "Removed from saved", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setMenuOpen(null);
      refetch();
    } catch (error) {
      toast.error(t("moments.saved.removeError") || "Failed to remove moment", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  };

  const GridView = () => (
    <div className="grid grid-cols-3 gap-1">
      {savedMoments.map((moment) => (
        <button
          key={moment._id}
          onClick={() => navigate(`/moments/${moment._id}`)}
          className="relative aspect-square bg-gray-100 overflow-hidden group"
        >
          {moment.imageUrls?.[0] ? (
            <img
              src={moment.imageUrls[0]}
              alt=""
              className="w-full h-full object-cover"
            />
          ) : moment.videoUrls?.[0] ? (
            <video
              src={moment.videoUrls[0]}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-teal-100 to-blue-100 p-2">
              <p className="text-gray-600 text-xs line-clamp-4 text-center">
                {moment.content}
              </p>
            </div>
          )}

          {/* Overlay on hover */}
          <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-4">
            <span className="flex items-center gap-1 text-white text-sm">
              <Heart className="w-4 h-4" fill="white" />
              {moment.likesCount}
            </span>
            <span className="flex items-center gap-1 text-white text-sm">
              <MessageCircle className="w-4 h-4" fill="white" />
              {moment.commentsCount}
            </span>
          </div>

          {/* Bookmark badge */}
          <div className="absolute top-2 right-2">
            <Bookmark className="w-5 h-5 text-white drop-shadow-lg" fill="white" />
          </div>
        </button>
      ))}
    </div>
  );

  const ListView = () => (
    <div className="space-y-4 px-4">
      {savedMoments.map((moment) => (
        <div
          key={moment._id}
          className="bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between p-4">
            <button
              onClick={() => navigate(`/user/${moment.user._id}`)}
              className="flex items-center gap-3"
            >
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 overflow-hidden">
                {moment.user.imageUrls?.[0] ? (
                  <img
                    src={moment.user.imageUrls[0]}
                    alt={moment.user.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-white font-bold">
                    {moment.user.name?.[0]}
                  </div>
                )}
              </div>
              <div className="text-left">
                <h3 className="font-semibold text-gray-800">{moment.user.name}</h3>
                <p className="text-xs text-gray-500">{formatDate(moment.createdAt)}</p>
              </div>
            </button>

            <div className="relative">
              <button
                onClick={() => setMenuOpen(menuOpen === moment._id ? null : moment._id)}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <MoreVertical className="w-5 h-5 text-gray-500" />
              </button>

              {menuOpen === moment._id && (
                <div className="absolute right-0 top-full mt-1 bg-white rounded-lg shadow-lg border py-1 z-10">
                  <button
                    onClick={() => handleUnsave(moment._id)}
                    disabled={isUnsaving}
                    className="flex items-center gap-2 px-4 py-2 text-red-500 hover:bg-red-50 w-full text-left"
                  >
                    <BookmarkMinus className="w-4 h-4" />
                    {t("moments.saved.remove") || "Remove"}
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Content */}
          <button
            onClick={() => navigate(`/moments/${moment._id}`)}
            className="w-full text-left"
          >
            {moment.content && (
              <p className="px-4 pb-3 text-gray-700">{moment.content}</p>
            )}

            {moment.imageUrls?.[0] && (
              <img
                src={moment.imageUrls[0]}
                alt=""
                className="w-full max-h-96 object-cover"
              />
            )}

            {moment.videoUrls?.[0] && (
              <video
                src={moment.videoUrls[0]}
                className="w-full max-h-96 object-cover"
                controls
              />
            )}
          </button>

          {/* Stats */}
          <div className="flex items-center gap-6 p-4 border-t">
            <span className="flex items-center gap-1 text-gray-500 text-sm">
              <Heart className="w-4 h-4" />
              {moment.likesCount}
            </span>
            <span className="flex items-center gap-1 text-gray-500 text-sm">
              <MessageCircle className="w-4 h-4" />
              {moment.commentsCount}
            </span>
          </div>
        </div>
      ))}
    </div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-blue-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-500 to-blue-500 text-white p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-xl font-bold flex items-center gap-2">
                <Bookmark className="w-6 h-6" />
                {t("moments.saved.title") || "Saved Moments"}
              </h1>
              <p className="text-teal-100 text-sm">
                {savedMoments.length} {t("moments.saved.momentCount") || "moments saved"}
              </p>
            </div>
          </div>

          {/* View Toggle */}
          <div className="flex gap-1 bg-white/20 p-1 rounded-lg">
            <button
              onClick={() => setViewMode("grid")}
              className={`p-2 rounded-md transition-colors ${
                viewMode === "grid" ? "bg-white text-teal-600" : "text-white/70"
              }`}
            >
              <Grid className="w-5 h-5" />
            </button>
            <button
              onClick={() => setViewMode("list")}
              className={`p-2 rounded-md transition-colors ${
                viewMode === "list" ? "bg-white text-teal-600" : "text-white/70"
              }`}
            >
              <List className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className={`py-6 max-w-2xl mx-auto ${viewMode === "list" ? "" : "px-0"}`}>
        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
          </div>
        ) : savedMoments.length === 0 ? (
          <div className="text-center py-12 px-4">
            <div className="p-4 rounded-full bg-teal-100 w-fit mx-auto mb-4">
              <Bookmark className="w-8 h-8 text-teal-500" />
            </div>
            <p className="text-gray-500 mb-4">
              {t("moments.saved.noMoments") || "No saved moments yet"}
            </p>
            <button
              onClick={() => navigate("/moments")}
              className="px-6 py-3 bg-gradient-to-r from-teal-500 to-blue-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
            >
              {t("moments.saved.browseMoments") || "Browse Moments"}
            </button>
          </div>
        ) : viewMode === "grid" ? (
          <GridView />
        ) : (
          <ListView />
        )}
      </div>

      {/* Click outside to close menu */}
      {menuOpen && (
        <div
          className="fixed inset-0 z-0"
          onClick={() => setMenuOpen(null)}
        />
      )}
    </div>
  );
};

export default SavedMoments;
