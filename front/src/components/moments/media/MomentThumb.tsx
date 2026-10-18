import React from "react";
import { Mic, Play } from "lucide-react";
import { gradientFor } from "./momentGradients";

const firstImage = (m: any): string => {
  const urls = m && (m.imageUrls || m.images);
  if (!Array.isArray(urls)) return "";
  for (let i = 0; i < urls.length; i += 1) {
    if (typeof urls[i] === "string" && urls[i].trim()) return urls[i].trim();
  }
  return "";
};

const formatSeconds = (s: number) => {
  const total = Math.max(0, Math.round(s || 0));
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`;
};

/**
 * A square preview of any moment, in the feed's media precedence
 * (SingleMoment: video -> audio -> text/gradient -> images). Missing or
 * broken media degrade to the caption on a plain tile, never to an empty box.
 */
const MomentThumb: React.FC<{ moment: any }> = ({ moment }) => {
  const video = moment && moment.video;
  const audio = moment && moment.audio;
  const image = firstImage(moment);
  const caption = (moment && typeof moment.description === "string" && moment.description) || "";

  if (video && video.url) {
    return (
      <div data-testid="thumb-video" className="relative h-full w-full bg-black">
        {video.thumbnail ? (
          <img src={video.thumbnail} alt="" loading="lazy" className="h-full w-full object-cover" />
        ) : (
          <video src={video.url} preload="metadata" muted className="h-full w-full object-cover" />
        )}
        <Play className="absolute start-2 top-2 h-4 w-4 text-white drop-shadow" fill="white" aria-hidden />
      </div>
    );
  }
  if (audio && audio.url) {
    return (
      <div data-testid="thumb-audio" className="flex h-full w-full flex-col items-center justify-center gap-1 bg-amber-50 p-2 text-amber-700">
        <Mic className="h-6 w-6" aria-hidden />
        <span className="text-xs font-semibold tabular-nums">{formatSeconds(audio.duration)}</span>
        {caption && <p className="line-clamp-2 text-center text-[11px] text-amber-800">{caption}</p>}
      </div>
    );
  }
  if (image) {
    return <img data-testid="thumb-image" src={image} alt="" loading="lazy" className="h-full w-full object-cover" />;
  }
  if (moment && (moment.mediaType === "text" || moment.backgroundColor)) {
    return (
      <div
        data-testid="thumb-gradient"
        className="flex h-full w-full items-center justify-center p-2"
        // Through a custom property: jsdom's CSS parser drops a gradient set
        // on background directly, which would leave the tile untestable.
        style={{ ["--moment-gradient" as any]: gradientFor(moment.backgroundColor), backgroundImage: "var(--moment-gradient)" } as React.CSSProperties}
      >
        <p className="line-clamp-4 text-center text-xs font-bold text-white drop-shadow-sm">{caption}</p>
      </div>
    );
  }
  return (
    <div data-testid="thumb-text" className="flex h-full w-full items-center justify-center bg-gradient-to-br from-teal-100 to-blue-100 p-2">
      <p className="line-clamp-4 text-center text-xs text-gray-600">{caption}</p>
    </div>
  );
};

export default MomentThumb;
