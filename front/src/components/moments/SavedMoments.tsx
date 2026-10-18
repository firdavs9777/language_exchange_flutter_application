import React, { useEffect, useMemo, useState } from "react";
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
import MomentThumb from "./media/MomentThumb";
import MomentVideoPlayer from "./media/MomentVideoPlayer";
import VoiceNotePlayer from "./media/VoiceNotePlayer";
import GradientMomentCard from "./media/GradientMomentCard";

interface SavedMoment {
  _id: string;
  description?: string;
  imageUrls?: string[];
  mediaType?: "image" | "video" | "audio" | "text";
  backgroundColor?: string;
  audio?: { url: string; duration: number; waveform: number[] };
  video?: { url: string; thumbnail?: string };
  likeCount: number;
  commentCount: number;
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

  // The server pages this list ({data, pagination}); "Load more" asks for the
  // next page and keeps the earlier ones (same pattern as MyMoments).
  const PAGE_SIZE = 12;
  const [page, setPage] = useState(1);
  const { currentData, isLoading, isFetching, refetch } = useGetSavedMomentsQuery({ page, limit: PAGE_SIZE });
  const [pages, setPages] = useState<{ [page: number]: SavedMoment[] }>({});
  const [hasMore, setHasMore] = useState(false);
  const [removed, setRemoved] = useState<{ [id: string]: boolean }>({});
  useEffect(() => {
    if (!currentData) return;
    const rows: SavedMoment[] = Array.isArray((currentData as any).data) ? (currentData as any).data : [];
    setPages((prev) => ({ ...prev, [page]: rows }));
    const pagination = (currentData as any).pagination;
    setHasMore(
      pagination && typeof pagination.hasNextPage === "boolean" ? pagination.hasNextPage : rows.length >= PAGE_SIZE
    );
  }, [currentData, page]);
  const [unsaveMoment, { isLoading: isUnsaving }] = useUnsaveMomentMutation();

  const savedMoments: SavedMoment[] = useMemo(() => {
    const all: { [page: number]: SavedMoment[] } = { ...pages };
    if (currentData && Array.isArray((currentData as any).data)) all[page] = (currentData as any).data;
    const seen: { [id: string]: boolean } = {};
    const out: SavedMoment[] = [];
    Object.keys(all).map(Number).sort((a, b) => a - b).forEach((key) => {
      all[key].forEach((m) => {
        // An unsave shifts later pages by one, so a refetched page can repeat
        // a moment an earlier page already shows.
        if (!m || removed[m._id] || seen[m._id]) return;
        seen[m._id] = true;
        out.push(m);
      });
    });
    return out;
  }, [pages, currentData, page, removed]);

  const handleUnsave = async (momentId: string) => {
    try {
      await unsaveMoment(momentId).unwrap();
      setRemoved((prev) => ({ ...prev, [momentId]: true }));
      toast.success(t("moments_section.saved.removeSuccess") || "Removed from saved", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setMenuOpen(null);
      refetch();
    } catch (error) {
      toast.error(t("moments_section.saved.removeError") || "Failed to remove moment", {
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
          data-testid="saved-tile"
          onClick={() => navigate(`/moment/${moment._id}`)}
          className="relative aspect-square bg-gray-100 overflow-hidden group"
        >
          <MomentThumb moment={moment} />

          {/* Overlay on hover */}
          <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-4">
            <span className="flex items-center gap-1 text-white text-sm">
              <Heart className="w-4 h-4" fill="white" />
              {moment.likeCount}
            </span>
            <span className="flex items-center gap-1 text-white text-sm">
              <MessageCircle className="w-4 h-4" fill="white" />
              {moment.commentCount}
            </span>
          </div>

          {/* Bookmark badge */}
          <div className="absolute top-2 end-2">
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
              data-testid="saved-author"
              onClick={() => navigate(`/community/${moment.user._id}`)}
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
                <div className="absolute end-0 top-full mt-1 bg-white rounded-lg shadow-lg border py-1 z-10">
                  <button
                    onClick={() => handleUnsave(moment._id)}
                    disabled={isUnsaving}
                    className="flex items-center gap-2 px-4 py-2 text-red-500 hover:bg-red-50 w-full text-start"
                  >
                    <BookmarkMinus className="w-4 h-4" />
                    {t("moments_section.saved.remove") || "Remove"}
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Content */}
          <button
            onClick={() => navigate(`/moment/${moment._id}`)}
            className="w-full text-start"
          >
            {/* A gradient moment draws its caption on the card itself. */}
            {moment.description && moment.mediaType !== "text" && !moment.backgroundColor && (
              <p className="px-4 pb-3 text-gray-700">{moment.description}</p>
            )}

            {moment.video && moment.video.url ? (
              <div className="px-4 pb-3"><MomentVideoPlayer video={moment.video as any} /></div>
            ) : moment.audio && moment.audio.url ? (
              <div className="px-4 pb-3"><VoiceNotePlayer audio={moment.audio} /></div>
            ) : moment.mediaType === "text" || (moment.backgroundColor && !(moment.imageUrls && moment.imageUrls.length)) ? (
              <div className="px-4 pb-3">
                <GradientMomentCard text={moment.description || ""} backgroundColor={moment.backgroundColor} />
              </div>
            ) : moment.imageUrls && moment.imageUrls[0] ? (
              <img src={moment.imageUrls[0]} alt="" loading="lazy" className="w-full max-h-96 object-cover" />
            ) : null}
          </button>

          {/* Stats */}
          <div className="flex items-center gap-6 p-4 border-t">
            <span className="flex items-center gap-1 text-gray-500 text-sm">
              <Heart className="w-4 h-4" />
              {moment.likeCount}
            </span>
            <span className="flex items-center gap-1 text-gray-500 text-sm">
              <MessageCircle className="w-4 h-4" />
              {moment.commentCount}
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
                {t("moments_section.saved.title") || "Saved Moments"}
              </h1>
              <p className="text-teal-100 text-sm">
                {(currentData && (currentData as any).pagination && (currentData as any).pagination.totalMoments) || savedMoments.length}{" "}
                {t("moments_section.saved.momentCount") || "moments saved"}
              </p>
            </div>
          </div>

          {/* View Toggle */}
          <div className="flex gap-1 bg-white/20 p-1 rounded-lg">
            <button
              type="button"
              aria-label={t("moments_section.saved.gridView") || "Grid view"}
              aria-pressed={viewMode === "grid"}
              onClick={() => setViewMode("grid")}
              className={`p-2 rounded-md transition-colors ${
                viewMode === "grid" ? "bg-white text-teal-600" : "text-white/70"
              }`}
            >
              <Grid className="w-5 h-5" />
            </button>
            <button
              type="button"
              aria-label={t("moments_section.saved.listView") || "List view"}
              aria-pressed={viewMode === "list"}
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
              {t("moments_section.saved.noMoments") || "No saved moments yet"}
            </p>
            <button
              onClick={() => navigate("/moments")}
              className="px-6 py-3 bg-gradient-to-r from-teal-500 to-blue-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
            >
              {t("moments_section.saved.browseMoments") || "Browse Moments"}
            </button>
          </div>
        ) : viewMode === "grid" ? (
          <GridView />
        ) : (
          <ListView />
        )}
        {hasMore && savedMoments.length > 0 && (
          <div className="mt-4 flex justify-center">
            <button
              type="button"
              onClick={() => setPage((p) => p + 1)}
              disabled={isFetching}
              className="rounded-full bg-white px-5 py-2 text-sm font-semibold text-teal-700 shadow disabled:opacity-50"
            >
              {t("moments_section.saved.loadMore") || "Load more"}
            </button>
          </div>
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
