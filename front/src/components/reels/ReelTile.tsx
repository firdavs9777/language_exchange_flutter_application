import React from "react";
import { useTranslation } from "react-i18next";
import { FaHeart, FaPlay } from "react-icons/fa";
import { formatReelDuration, Reel } from "./lib/reelModel";

const ReelTile: React.FC<{ reel: Reel; onOpen: () => void }> = ({ reel, onOpen }) => {
  const { t } = useTranslation();
  const duration = formatReelDuration(reel.duration);
  const label =
    (t("reels.grid.open_reel", { name: reel.author.name }) || `Play reel by ${reel.author.name}`).trim();
  return (
    <button type="button" className="reel-tile" data-testid={`reel-tile-${reel.id}`} onClick={onOpen} aria-label={label}>
      {reel.thumbnail ? (
        <img src={reel.thumbnail} alt="" loading="lazy" className="reel-tile-media" />
      ) : (
        // 2.6.1 reels have no thumbnail: the first frame, fetched as metadata only.
        <video
          src={`${reel.videoUrl}#t=0.1`}
          preload="metadata"
          muted
          playsInline
          className="reel-tile-media"
          aria-hidden="true"
        />
      )}
      <span className="reel-tile-play" aria-hidden="true">
        <FaPlay />
      </span>
      <span className="reel-tile-meta">
        <span className="reel-tile-likes">
          <FaHeart aria-hidden="true" /> {reel.likeCount}
        </span>
        {duration && <span className="reel-tile-duration">{duration}</span>}
      </span>
    </button>
  );
};

export default ReelTile;
