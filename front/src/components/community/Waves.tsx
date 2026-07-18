import React, { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ArrowLeft, Hand, Loader2 } from "lucide-react";
import {
  useGetWavesQuery,
  useMarkWavesReadMutation,
} from "../../store/slices/communitySlice";

/**
 * Real wave item shape returned by `GET /api/v1/community/waves`
 * (`controllers/community.js getWaves`):
 *   { waveId, from: { _id, name, images }, message, createdAt, isRead }
 * `from` is populated with `name images` (NOT `imageUrls`) — the backend
 * selects `.populate('from', 'name images')`, so raw Mongo `images` docs are
 * what's on the wire here, not the computed `imageUrls` used elsewhere in the
 * community slice's `transformResponse`. We defensively read both.
 */
interface WaveFromUser {
  _id: string;
  name: string;
  images?: Array<string | { url?: string; imageUrl?: string }>;
  imageUrls?: string[];
}

interface WaveItem {
  waveId: string;
  from: WaveFromUser;
  message?: string;
  createdAt: string;
  isRead: boolean;
}

const PAGE_LIMIT = 20;

const getAvatarUrl = (user?: WaveFromUser): string | undefined => {
  if (!user) return undefined;
  if (user.imageUrls?.[0]) return user.imageUrls[0];
  const first = user.images?.[0];
  if (!first) return undefined;
  if (typeof first === "string") return first;
  return first.url || first.imageUrl;
};

const formatTimeAgo = (dateString: string): string => {
  const date = new Date(dateString);
  const diffMs = Date.now() - date.getTime();
  const minutes = Math.floor(diffMs / (1000 * 60));
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d ago`;
  const months = Math.floor(days / 30);
  return `${months}mo ago`;
};

const Waves: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [page, setPage] = useState(1);
  // Accumulated waves across all loaded pages. RTK Query caches each
  // {page, limit} arg combo as its own entry and does NOT merge them, so
  // "Load more" would otherwise just swap `data` to the new page's slice
  // and drop everything rendered so far. We keep our own running list here,
  // deduped by `waveId` (the real backend's identifier for a wave — NOT the
  // deprecated shim's `_id`).
  const [accumulatedWaves, setAccumulatedWaves] = useState<WaveItem[]>([]);

  const { data, isLoading, isFetching } = useGetWavesQuery({
    page,
    limit: PAGE_LIMIT,
  });
  const [markWavesRead] = useMarkWavesReadMutation();

  const unreadCount: number = data?.data?.unreadCount || 0;

  // Merge each page response into the accumulator: page 1 (initial load, or
  // any future reset back to the top) replaces the accumulator outright;
  // subsequent pages ("Load more") are appended, skipping any waveId already
  // present so a refetch/invalidation of the current page can't duplicate
  // entries.
  useEffect(() => {
    const fetchedWaves: WaveItem[] = data?.data?.waves || [];
    if (page === 1) {
      setAccumulatedWaves(fetchedWaves);
      return;
    }
    setAccumulatedWaves((prev) => {
      const seen = new Set(prev.map((w) => w.waveId));
      const newOnes = fetchedWaves.filter((w) => !seen.has(w.waveId));
      return newOnes.length ? [...prev, ...newOnes] : prev;
    });
  }, [data, page]);

  // The most recently fetched page determines whether more pages remain:
  // prefer the backend's own pagination flag when present, otherwise fall
  // back to "this page came back full" as a heuristic.
  const lastPageWaves: WaveItem[] = data?.data?.waves || [];
  const hasMore =
    data?.pagination?.hasMore ??
    (lastPageWaves.length > 0 && lastPageWaves.length === PAGE_LIMIT);

  // Auto-mark ALL unread waves as read once the inbox is opened and the
  // first page has loaded. Calling with no args marks every unread wave
  // (not just the current page) per the real endpoint contract.
  useEffect(() => {
    if (!isLoading && unreadCount > 0) {
      markWavesRead().catch(() => {
        /* best-effort — inbox still renders even if this fails */
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoading, unreadCount > 0]);

  const handleLoadMore = useCallback(() => {
    if (!isFetching) setPage((p) => p + 1);
  }, [isFetching]);

  // Backend already sorts by createdAt desc (`getWaves` query: `.sort({ createdAt: -1 })`),
  // so no client-side re-sort is needed here.
  const sortedWaves = accumulatedWaves;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] text-white px-5 py-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-full transition-colors"
            aria-label="Back"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold flex items-center gap-2">
              <Hand className="w-6 h-6" />
              {t("community.waves.title") || "Waves"}
            </h1>
            <p className="text-teal-50 text-sm">
              {t("community.waves.subtitle") || "People who waved at you"}
            </p>
          </div>
          {unreadCount > 0 && (
            <div
              data-testid="waves-unread-badge"
              className="bg-white text-teal-600 font-bold rounded-full min-w-[2rem] h-8 px-2 flex items-center justify-center"
            >
              {unreadCount}
            </div>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
          </div>
        ) : sortedWaves.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-teal-50 w-fit mx-auto mb-4">
              <Hand className="w-8 h-8 text-teal-500" />
            </div>
            <p className="text-gray-500">
              {t("community.waves.noReceivedWaves") || "No waves received yet"}
            </p>
            <button
              type="button"
              onClick={() => navigate("/community")}
              className="mt-4 px-6 py-3 bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] text-white rounded-full font-semibold hover:shadow-lg transition-all"
            >
              {t("community.waves.findPeople") || "Find People"}
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {sortedWaves.map((wave) => {
              const avatar = getAvatarUrl(wave.from);
              return (
                <div
                  key={wave.waveId}
                  data-testid="wave-item"
                  onClick={() => wave.from?._id && navigate(`/community/${wave.from._id}`)}
                  className={`flex items-start gap-3 rounded-2xl p-4 shadow-sm border cursor-pointer transition-colors ${
                    wave.isRead
                      ? "bg-white border-gray-100"
                      : "bg-teal-50/70 border-teal-200"
                  }`}
                >
                  <div className="w-12 h-12 rounded-full overflow-hidden bg-gradient-to-br from-teal-100 to-cyan-50 shrink-0 flex items-center justify-center">
                    {avatar ? (
                      <img
                        src={avatar}
                        alt={wave.from?.name || "User"}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <span className="text-lg font-semibold text-teal-600">
                        {wave.from?.name?.[0]?.toUpperCase() || "?"}
                      </span>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <h3 className="font-semibold text-gray-800 truncate">
                        {wave.from?.name || "Someone"}
                      </h3>
                      <span className="text-xs text-gray-400 shrink-0">
                        {formatTimeAgo(wave.createdAt)}
                      </span>
                    </div>
                    <p className="text-gray-600 text-sm mt-0.5">
                      {wave.message?.trim() || "Waved at you 👋"}
                    </p>
                  </div>
                  {!wave.isRead && (
                    <span
                      data-testid="wave-item-unread-dot"
                      className="w-2.5 h-2.5 rounded-full bg-teal-500 shrink-0 mt-1.5"
                      aria-label="Unread"
                    />
                  )}
                </div>
              );
            })}

            {hasMore && (
              <div className="flex justify-center pt-2">
                <button
                  type="button"
                  onClick={handleLoadMore}
                  disabled={isFetching}
                  className="px-6 py-2.5 rounded-full bg-gray-100 text-gray-700 font-medium hover:bg-gray-200 transition-colors disabled:opacity-50"
                >
                  {isFetching
                    ? t("communityMain.loadMore.loading") || "Loading..."
                    : t("communityMain.loadMore.button") || "Load more"}
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default Waves;
