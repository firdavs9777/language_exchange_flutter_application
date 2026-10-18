import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { FaCommentDots, FaEllipsisH, FaFlag, FaHeart, FaRegHeart, FaShare, FaTimes, FaUserSlash } from "react-icons/fa";
import { useDislikeMomentMutation, useLikeMomentMutation, useShareMomentMutation } from "../../store/slices/momentsSlice";
import CommentList from "../moments/comments/CommentList";
import ShareButton from "../linking/ShareButton";
import ReportMomentDialog from "../moments/actions/ReportMomentDialog";
import BlockAuthorDialog from "../moments/actions/BlockAuthorDialog";
import { Reel } from "./lib/reelModel";

export interface ReelActionsProps {
  reel: Reel;
  myUserId: string;
  onPatch(patch: Partial<Reel>): void;
  onAuthorBlocked(authorId: string): void;
}

const isAlreadyLiked = (err: any) => {
  const d = err && err.data;
  const msg = (d && (d.message || d.error)) || "";
  return err && err.status === 400 && /already liked/i.test(String(msg));
};

/** The right-hand action rail of a reel (the app's reel_overlays.dart). */
const ReelActions: React.FC<ReelActionsProps> = ({ reel, myUserId, onPatch, onAuthorBlocked }) => {
  const { t } = useTranslation();
  const [likeMoment] = useLikeMomentMutation();
  const [dislikeMoment] = useDislikeMomentMutation();
  const [shareMoment] = useShareMomentMutation();
  const [commentsOpen, setCommentsOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [dialog, setDialog] = useState<"report" | "block" | null>(null);

  const toggleLike = () => {
    const before = { isLiked: reel.isLiked, likeCount: reel.likeCount };
    const liking = !reel.isLiked;
    onPatch({ isLiked: liking, likeCount: Math.max(0, reel.likeCount + (liking ? 1 : -1)) });
    const call = liking ? likeMoment : dislikeMoment;
    Promise.resolve()
      .then(() => call({ momentId: reel.id, userId: myUserId }).unwrap())
      .catch((err: any) => {
        if (liking && isAlreadyLiked(err)) return;
        onPatch(before);
      });
  };

  const trackShare = () => {
    onPatch({ shareCount: reel.shareCount + 1 });
    // Fired in the click itself (the ShareButton inside opens the sheet);
    // the count is best effort.
    try {
      const req: any = shareMoment(reel.id);
      if (req && req.unwrap) req.unwrap().catch(() => {});
    } catch (e) {
      // ignore
    }
  };

  return (
    <>
      <Link to={`/profile/${reel.author.id}`} className="reel-avatar" data-testid="reel-author-link"
        aria-label={reel.author.name || t("reels.actions.profile") || "Profile"}>
        {reel.author.avatar ? <img src={reel.author.avatar} alt="" /> : <span>{(reel.author.name || "?").charAt(0)}</span>}
      </Link>

      <button type="button" className="reel-action" data-testid="reel-like" onClick={toggleLike}
        aria-pressed={reel.isLiked} aria-label={reel.isLiked ? t("reels.actions.unlike") || "Unlike" : t("reels.actions.like") || "Like"}>
        {reel.isLiked ? <FaHeart aria-hidden="true" className="reel-liked" /> : <FaRegHeart aria-hidden="true" />}
        <span data-testid="reel-like-count">{reel.likeCount}</span>
      </button>

      <button type="button" className="reel-action" data-testid="reel-comments" onClick={() => setCommentsOpen(true)}
        aria-label={t("reels.actions.comments") || "Comments"}>
        <FaCommentDots aria-hidden="true" />
        <span data-testid="reel-comment-count">{reel.commentCount}</span>
      </button>

      <span className="reel-action" data-testid="reel-share" onClick={trackShare}>
        <ShareButton type="moment" id={reel.id} title={reel.author.name || "BananaTalk"} text={reel.description}
          className="reel-share-inner" />
        <FaShare aria-hidden="true" />
        <span>{reel.shareCount}</span>
      </span>

      <div className="reel-more-wrap">
        <button type="button" className="reel-action" data-testid="reel-more" aria-haspopup="menu"
          aria-expanded={menuOpen} onClick={() => setMenuOpen((o) => !o)} aria-label={t("reels.actions.more") || "More"}>
          <FaEllipsisH aria-hidden="true" />
        </button>
        {menuOpen && (
          <div className="reel-menu" role="menu">
            <button type="button" role="menuitem" data-testid="reel-report"
              onClick={() => { setMenuOpen(false); setDialog("report"); }}>
              <FaFlag aria-hidden="true" /> {t("reels.actions.report") || "Report"}
            </button>
            <button type="button" role="menuitem" data-testid="reel-block" className="reel-menu-danger"
              onClick={() => { setMenuOpen(false); setDialog("block"); }}>
              <FaUserSlash aria-hidden="true" /> {t("reels.actions.block") || "Block user"}
            </button>
          </div>
        )}
      </div>

      {commentsOpen && (
        <div className="reel-comments-drawer" data-testid="reel-comments-drawer" role="dialog"
          aria-label={t("reels.actions.comments") || "Comments"}
          onWheel={(e) => e.stopPropagation()} onTouchStart={(e) => e.stopPropagation()} onTouchEnd={(e) => e.stopPropagation()}
          onKeyDown={(e) => e.stopPropagation()}>
          <div className="reel-comments-head">
            <strong>{t("reels.actions.comments") || "Comments"}</strong>
            <button type="button" className="reel-icon-btn" data-testid="reel-comments-close"
              onClick={() => setCommentsOpen(false)} aria-label={t("reels.viewer.close") || "Close"}>
              <FaTimes aria-hidden="true" />
            </button>
          </div>
          <CommentList
            momentId={reel.id}
            momentText={reel.description}
            myUserId={myUserId}
            isLoggedIn
            onRequireLogin={() => {}}
            onTotalChange={(total) => onPatch({ commentCount: total })}
          />
        </div>
      )}

      {dialog === "report" && (
        <ReportMomentDialog type="moment" targetId={reel.id} authorId={reel.author.id} onClose={() => setDialog(null)} />
      )}
      {dialog === "block" && (
        <BlockAuthorDialog authorId={reel.author.id} authorName={reel.author.name} onClose={() => setDialog(null)}
          onBlocked={() => { setDialog(null); onAuthorBlocked(reel.author.id); }} />
      )}
    </>
  );
};

export default ReelActions;
