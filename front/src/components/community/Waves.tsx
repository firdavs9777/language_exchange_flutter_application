import React, { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ArrowLeft, Hand, History, Loader2 } from "lucide-react";
import {
  useGetWavesQuery,
  useMarkWavesReadMutation,
} from "../../store/slices/communitySlice";
import { useGetAppConfigQuery } from "../../store/slices/appConfigSlice";
import { photoUrl } from "../../utils/photoUrl";
import { timeAgo } from "../../utils/timeAgo";

/**
 * GET /api/v1/community/waves (controllers/community.js getWaves):
 *   { waveId, from: { _id, name, images }, message, createdAt, isRead, revealed? }
 * `from` is populated with `name images` only — raw storage paths, never
 * `imageUrls` — and is null when the sender's account is gone.
 */
interface WaveFromUser {
  _id: string;
  name: string;
  images?: Array<string | { url?: string; imageUrl?: string }>;
  imageUrls?: string[];
}

interface WaveItem {
  waveId: string;
  from: WaveFromUser | null;
  message?: string;
  createdAt: string;
  isRead: boolean;
}

const PAGE_LIMIT = 20;

/**
 * The sender's photo as a URL a browser can load. The old code put the raw
 * storage path ("users/x.jpg") straight into <img src>, a broken image for
 * every app user. Legacy rows carrying `{url}` objects still work.
 */
export function waveAvatarUrl(user?: WaveFromUser | null): string | undefined {
  if (!user) return undefined;
  const built = (user.imageUrls || []).find((u) => typeof u === "string" && u.trim());
  if (built) return built;
  const paths = (user.images || [])
    .map((image) =>
      typeof image === "string" ? image : (image && (image.url || image.imageUrl)) || ""
    )
    .filter((image) => Boolean(image));
  return photoUrl(paths);
}

const Waves: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  /** false = the last 7 days; true = 7-30 days (the app's "View archive"). */
  const [archive, setArchive] = useState(false);
  const [page, setPage] = useState(1);
  // RTK Query caches each {page, archive} as its own entry and does not merge
  // them, so "Load more" keeps its own running list, deduped by waveId.
  const [accumulatedWaves, setAccumulatedWaves] = useState<WaveItem[]>([]);

  // The app sends ?reveal=1 only while boostsEnabled is on (waves_tab.dart).
  // Waiting for the config keeps it to one request, not one without and one
  // with; a failed config read counts as "off".
  const { data: appConfig, isLoading: configLoading } = useGetAppConfigQuery();
  const reveal = Boolean(appConfig && (appConfig as any).boostsEnabled);

  // currentData, not data: after the archive switch `data` still holds the
  // other list until the new one lands, and would be merged into it.
  const { currentData, isLoading, isFetching } = useGetWavesQuery(
    {
      page,
      limit: PAGE_LIMIT,
      archive: archive || undefined,
      reveal: reveal || undefined,
    },
    { skip: configLoading }
  );
  const data: any = currentData;
  const [markWavesRead] = useMarkWavesReadMutation();

  const unreadCount: number = (data && data.data && data.data.unreadCount) || 0;

  useEffect(() => {
    if (!data) return;
    const fetchedWaves: WaveItem[] = (data.data && data.data.waves) || [];
    if (page === 1) {
      setAccumulatedWaves(fetchedWaves);
      return;
    }
    setAccumulatedWaves((prev) => {
      const seen = new Set(prev.map((w) => w.waveId));
      const newOnes = fetchedWaves.filter((w) => !seen.has(w.waveId));
      return newOnes.length ? prev.concat(newOnes) : prev;
    });
  }, [data, page]);

  const lastPageWaves: WaveItem[] = (data && data.data && data.data.waves) || [];
  const hasMore =
    (data && data.pagination && data.pagination.hasMore) ??
    (lastPageWaves.length > 0 && lastPageWaves.length === PAGE_LIMIT);

  // Opening the recent list marks every unread wave read (no ids = all), as
  // the app does after a successful load. The archive never does.
  useEffect(() => {
    if (!archive && data && unreadCount > 0) {
      markWavesRead(undefined).catch(() => {
        /* best-effort — the badge clears on the next load */
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [archive, Boolean(data), unreadCount > 0]);

  const handleLoadMore = useCallback(() => {
    if (!isFetching) setPage((p) => p + 1);
  }, [isFetching]);

  const switchList = () => {
    setArchive((was) => !was);
    setPage(1);
    setAccumulatedWaves([]);
  };

  const loading = configLoading || isLoading || (!data && isFetching);

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] text-white px-5 py-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-full transition-colors"
            aria-label={t("waves.back") || "Back"}
          >
            <ArrowLeft className="w-6 h-6 rtl:rotate-180" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold flex items-center gap-2">
              <Hand className="w-6 h-6" />
              {t("waves.title") || "Waves"}
            </h1>
            <p className="text-teal-50 text-sm">
              {archive
                ? t("waves.archiveHint") || "Waves from 7 to 30 days ago"
                : t("waves.subtitle") || "People who waved at you"}
            </p>
          </div>
          {!archive && unreadCount > 0 && (
            <div
              data-testid="waves-unread-badge"
              className="bg-white text-teal-600 font-bold rounded-full min-w-[2rem] h-8 px-2 flex items-center justify-center"
            >
              {unreadCount}
            </div>
          )}
        </div>
      </div>

      <div className="px-4 py-6 max-w-2xl mx-auto">
        <div className="flex justify-end pb-3">
          <button
            type="button"
            data-testid="waves-archive-toggle"
            aria-pressed={archive}
            onClick={switchList}
            className="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm font-medium text-teal-700 hover:bg-teal-50 transition-colors"
          >
            <History className="w-4 h-4" aria-hidden />
            {archive ? t("waves.recent") || "Last 7 days" : t("waves.archive") || "Older waves"}
          </button>
        </div>

        {loading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
          </div>
        ) : accumulatedWaves.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-teal-50 w-fit mx-auto mb-4">
              <Hand className="w-8 h-8 text-teal-500" />
            </div>
            <p className="text-gray-500">
              {archive
                ? t("waves.archiveEmpty") || "No older waves"
                : t("waves.noReceived") || "No waves received yet"}
            </p>
            <button
              type="button"
              onClick={() => navigate("/communities")}
              className="mt-4 px-6 py-3 bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] text-white rounded-full font-semibold hover:shadow-lg transition-all"
            >
              {t("waves.findPeople") || "Find People"}
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {accumulatedWaves.map((wave) => {
              const avatar = waveAvatarUrl(wave.from);
              const name = (wave.from && wave.from.name) || t("waves.someone") || "Someone";
              return (
                <div
                  key={wave.waveId}
                  data-testid="wave-item"
                  onClick={() => wave.from && wave.from._id && navigate(`/community/${wave.from._id}`)}
                  className={`flex items-start gap-3 rounded-2xl p-4 shadow-sm border cursor-pointer transition-colors ${
                    wave.isRead ? "bg-white border-gray-100" : "bg-teal-50/70 border-teal-200"
                  }`}
                >
                  <div className="w-12 h-12 rounded-full overflow-hidden bg-gradient-to-br from-teal-100 to-cyan-50 shrink-0 flex items-center justify-center">
                    {avatar ? (
                      <img src={avatar} alt={name} className="w-full h-full object-cover" />
                    ) : (
                      <span className="text-lg font-semibold text-teal-600">
                        {name ? name[0].toUpperCase() : "?"}
                      </span>
                    )}
                  </div>
                  <div className="flex-1 min-w-0 text-start">
                    <div className="flex items-center justify-between gap-2">
                      <h3 className="font-semibold text-gray-800 truncate">{name}</h3>
                      <span className="text-xs text-gray-400 shrink-0">
                        {timeAgo(wave.createdAt, t, { withAgo: true })}
                      </span>
                    </div>
                    <p className="text-gray-600 text-sm mt-0.5">
                      {(wave.message && wave.message.trim()) || t("waves.wavedAtYou") || "Waved at you 👋"}
                    </p>
                  </div>
                  {!wave.isRead && (
                    <span
                      data-testid="wave-item-unread-dot"
                      className="w-2.5 h-2.5 rounded-full bg-teal-500 shrink-0 mt-1.5"
                      aria-label={t("waves.unread") || "Unread"}
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
