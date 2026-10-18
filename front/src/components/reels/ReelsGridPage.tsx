import React from "react";
import { useTranslation } from "react-i18next";
import { useSelector } from "react-redux";
import { Link, useLocation, useNavigate, useSearchParams } from "react-router-dom";
import ReelPolicyGate from "./ReelPolicyGate";
import ReelActions from "./ReelActions";
import ReelTile from "./ReelTile";
import ReelViewer from "./ReelViewer";
import { useReelsFeed } from "./useReelsFeed";
import "./Reels.scss";

/**
 * /reels -- the grid (the app's Reels tab, reels_grid_screen.dart). Only
 * routed while webReelsEnabled and reelsEnabled are on (P4-REEL-7).
 */
const ReelsGridPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const feed = useReelsFeed();
  const myUserId = useSelector(
    (state: any) => (state.auth.userInfo && state.auth.userInfo.user && state.auth.userInfo.user._id) || ""
  );
  // The open reel lives in the URL (?reel=<id>) so Back closes the viewer
  // instead of leaving /reels. A link shared by id that is not in this
  // session's feed simply opens the grid.
  const [searchParams, setSearchParams] = useSearchParams();
  const location = useLocation();
  const openId = searchParams.get("reel");
  const openIndex = openId ? feed.reels.findIndex((r) => r.id === openId) : -1;
  const openReel = (i: number) =>
    setSearchParams({ reel: feed.reels[i].id }, { state: { reelOpened: true } } as any);
  const moveTo = (i: number) => setSearchParams({ reel: feed.reels[i].id }, { replace: true, state: location.state } as any);
  const closeViewer = () => {
    if (location.state && (location.state as any).reelOpened) navigate(-1);
    else setSearchParams({}, { replace: true } as any);
  };

  const createLink = (
    <Link to="/reels/new" className="reel-btn reel-btn-primary" data-testid="reels-create">
      {t("reels.grid.create") || "Create reel"}
    </Link>
  );

  let body: React.ReactNode;
  if (feed.status === "loading") {
    body = <div className="reels-state" aria-busy="true">{t("reels.grid.loading") || "Loading reels…"}</div>;
  } else if (feed.status === "unavailable") {
    body = (
      <div className="reels-state" data-testid="reels-unavailable">
        {t("reels.grid.unavailable") || "Reels are currently unavailable."}
      </div>
    );
  } else if (feed.status === "error") {
    body = (
      <div className="reels-state" data-testid="reels-error">
        <p>{t("reels.grid.error") || "Couldn't load reels."}</p>
        <button type="button" className="reel-btn reel-btn-ghost" data-testid="reels-retry" onClick={feed.reload}>
          {t("reels.grid.retry") || "Try again"}
        </button>
      </div>
    );
  } else if (feed.reels.length === 0) {
    body = (
      <div className="reels-state" data-testid="reels-empty">
        <p>{t("reels.grid.empty") || "No reels yet. Be the first to post one."}</p>
      </div>
    );
  } else {
    body = (
      <>
        <div className="reels-grid">
          {feed.reels.map((reel, i) => (
            <ReelTile key={reel.id} reel={reel} onOpen={() => openReel(i)} />
          ))}
        </div>
        {feed.hasMore && (
          <div className="reels-more">
            <button
              type="button"
              className="reel-btn reel-btn-ghost"
              data-testid="reels-load-more"
              disabled={feed.loadingMore}
              onClick={feed.loadMore}
            >
              {feed.loadingMore ? t("reels.grid.loading") || "Loading reels…" : t("reels.grid.load_more") || "Load more"}
            </button>
          </div>
        )}
      </>
    );
  }

  return (
    <ReelPolicyGate onDeclined={() => navigate("/moments")}>
      <section className="reels-page" data-testid="reels-page">
        <header className="reels-header">
          <h1 className="reels-title">{t("reels.grid.title") || "Reels"}</h1>
          {feed.status !== "unavailable" && createLink}
        </header>
        {body}
        {openIndex >= 0 && (
          <ReelViewer
            reels={feed.reels}
            index={openIndex}
            hasMore={feed.hasMore}
            onIndexChange={moveTo}
            onNeedMore={feed.loadMore}
            onClose={closeViewer}
            renderActions={(reel) => (
              <ReelActions
                reel={reel}
                myUserId={myUserId}
                onPatch={(patch) => feed.patchReel(reel.id, patch)}
                onAuthorBlocked={(authorId) => {
                  closeViewer();
                  feed.removeWhere((r) => r.author.id === authorId);
                }}
              />
            )}
          />
        )}
      </section>
    </ReelPolicyGate>
  );
};

export default ReelsGridPage;
