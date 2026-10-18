import React from "react";
import { Link } from "react-router-dom";
import {
  overlayPlateClass,
  OVERLAY_FONT_CLASS,
  mentionPositionStyle,
  overlayPositionStyle,
  overlayScaleClass,
  parseLinkUrl,
  storyBodyFontClass,
} from "./storyOverlays";
import { storyBackgroundStyle, storyTextColor } from "./storyBackground";

/** First usable media URL, from `mediaUrls` or the legacy `mediaUrl`. */
export function storyMediaUrl(story: any): string {
  if (!story) return "";
  const urls = story.mediaUrls;
  if (Array.isArray(urls)) {
    for (let i = 0; i < urls.length; i += 1) {
      const url = typeof urls[i] === "string" ? urls[i].trim() : "";
      if (url) return url;
    }
  }
  return typeof story.mediaUrl === "string" ? story.mediaUrl.trim() : "";
}

export function isVideoStory(story: any): boolean {
  if (!story) return false;
  return story.mediaType === "video" || /\.(mp4|webm|mov|m4v|ogg)$/i.test(storyMediaUrl(story));
}

/**
 * The place an author tagged, or "" when there is none. The backend stores a
 * location only with a non-empty name (`parseLocation`), but older rows and
 * the app's model allow a blank one; both mean "no place", as in the app's
 * `story.location!.name.trim().isNotEmpty` check.
 */
export function storyLocationName(story: any): string {
  const location = story && story.location;
  if (!location || typeof location !== "object") return "";
  return typeof location.name === "string" ? location.name.trim() : "";
}

/**
 * The story's hashtags as the app shows them: `#` added when missing, blanks
 * and repeats dropped. Labels only -- no hashtag search exists, and a chip
 * that goes nowhere is the worse bug (the app's own reasoning).
 */
export function storyHashtags(story: any): string[] {
  const raw: any[] = story && Array.isArray(story.hashtags) ? story.hashtags : [];
  const out: string[] = [];
  raw.forEach((tag) => {
    const clean = typeof tag === "string" ? tag.trim().replace(/^#+/, "") : "";
    if (!clean) return;
    const label = "#" + clean;
    if (out.indexOf(label) === -1) out.push(label);
  });
  return out;
}

/**
 * Where a link sticker really goes: the host the server parsed (stored from
 * Phase 1 on), else the same parse done here for stories saved before the
 * backend kept it. Shown under the label because the label is the poster's
 * words and the host is not -- the app does the same.
 */
export function storyLinkHost(link: any): string {
  if (!link) return "";
  if (typeof link.host === "string" && link.host.trim()) return link.host.trim().toLowerCase();
  const parsed = parseLinkUrl(link.url);
  return parsed ? parsed.host : "";
}

/**
 * The cross-client rule for `text`.
 *
 * Text story: when it carries overlays, they ARE its words. The app sends a
 * text story's `text` as the overlays' text joined together (so old clients
 * still show something) and its own viewer hides `text` whenever overlays
 * exist; painting both would print every line twice.
 *
 * Media story: `text` is the app's caption, which the app shows even when the
 * picture has overlays, so it is hidden only when it merely repeats them.
 */
export function storyBodyText(story: any): string {
  if (!story) return "";
  const text = typeof story.text === "string" ? story.text.trim() : "";
  const overlays: any[] = Array.isArray(story.overlays) ? story.overlays.filter(Boolean) : [];
  if (!text || overlays.length === 0) return text;
  if (story.mediaType === "text" || !storyMediaUrl(story)) return "";
  const contents = overlays.map((o) => String(o.content || "").trim()).filter(Boolean);
  const joined = overlays
    .filter((o) => o.type !== "emoji")
    .map((o) => String(o.content || ""))
    .join("\n")
    .trim();
  return text === joined || contents.indexOf(text) > -1 ? "" : text;
}

export interface StoryCanvasProps {
  story: any;
  /** Prefix of every data-testid, so each surface keeps its own. */
  testIdPrefix?: string;
  /** Video stories: called when playback ends (the viewer's auto-advance). */
  onVideoEnded?: () => void;
  /** Called before a mention navigates away, so a dialog can close itself. */
  onNavigate?: () => void;
  /** Text-story body size; the full-screen viewer reads larger than a panel. */
  bodyClassName?: string;
}

/**
 * Everything a story DRAWS, shared by the full-screen viewer and the highlight
 * viewer so the two never disagree about a story: the background (media, or a
 * text story's colour / app gradient), the body or caption, the text and emoji
 * overlays, the tagged people and the link sticker. Interactive stickers
 * (poll, question) belong to the viewer that can act on them.
 *
 * The parent must be `relative` and sized; this fills it.
 */
const StoryCanvas: React.FC<StoryCanvasProps> = ({
  story,
  testIdPrefix = "story",
  onVideoEnded,
  onNavigate,
  bodyClassName = "text-2xl sm:text-3xl",
}) => {
  if (!story) return null;
  const media = storyMediaUrl(story);
  const isText = story.mediaType === "text" || !media;
  const body = storyBodyText(story);
  const overlays: any[] = Array.isArray(story.overlays) ? story.overlays : [];
  const mentions: any[] = Array.isArray(story.mentions) ? story.mentions : [];
  // An interactive sticker sits at the bottom of the picture; a caption moves
  // to the top rather than disappear under it.
  const hasBottomSticker = Boolean(story.poll || story.questionBox);
  const tags = storyHashtags(story);

  return (
    <>
      {isText ? (
        <div
          data-testid={testIdPrefix + "-text"}
          // The author's own palette: story DATA, the way an overlay's
          // colour is. The classes carry the fallback for a story that
          // arrives without one (or with a value CSS cannot paint).
          style={{
            ...storyBackgroundStyle(story.backgroundColor),
            color: storyTextColor(story.textColor),
          }}
          className={[
            "flex h-full w-full items-center justify-center break-words bg-black p-10 text-center text-white",
            storyBodyFontClass(story.fontStyle),
            bodyClassName,
          ].join(" ")}
        >
          {body ? <p className="m-0 max-w-[90%] whitespace-pre-wrap">{body}</p> : null}
        </div>
      ) : isVideoStory(story) ? (
        <video
          data-testid={testIdPrefix + "-video"}
          src={media}
          className="h-full w-full object-contain"
          onEnded={onVideoEnded}
          controls
          playsInline
        />
      ) : (
        <img
          data-testid={testIdPrefix + "-image"}
          src={media}
          alt="Story"
          className="h-full w-full object-contain"
        />
      )}

      {/* Caption (a media story's `text`, the app's caption field) and the
          hashtags under it, as one block so they never overlap. */}
      {((!isText && body) || tags.length > 0) && (
        <div
          className={[
            "pointer-events-none absolute inset-x-4 z-[6] flex flex-col items-center gap-1.5 text-center",
            hasBottomSticker ? "top-24" : "bottom-40",
          ].join(" ")}
        >
          {!isText && body && (
            <p
              data-testid={testIdPrefix + "-caption"}
              className="m-0 whitespace-pre-wrap break-words text-base text-white drop-shadow-[0_1px_3px_rgba(0,0,0,0.9)]"
            >
              {body}
            </p>
          )}
          {tags.length > 0 && (
            <p
              data-testid={testIdPrefix + "-hashtags"}
              className="m-0 flex flex-wrap justify-center gap-x-2 gap-y-1 text-sm font-semibold text-sky-200 drop-shadow-[0_1px_3px_rgba(0,0,0,0.9)]"
            >
              {tags.map((tag) => (
                <span key={tag} dir="auto">
                  {tag}
                </span>
              ))}
            </p>
          )}
        </div>
      )}

      {/* Text and emoji overlays.
          These are STRUCTURE, not pixels: the composer (web) and the studio
          (app) both upload `overlays[]` as JSON and never bake the glyphs into
          the image, so this is the only place they become visible.
          `left`/`top` are the one thing that has to be an inline style -- two
          numbers out of the JSON that no utility class can express, on a
          canvas whose size is whatever the viewport gives it. Everything else
          (font, weight, plate, size) is a class from `storyOverlays.ts`;
          `color` is the author's own choice and is data. */}
      {overlays.map((overlay, index) =>
        overlay ? (
          <span
            key={index}
            data-testid={testIdPrefix + "-overlay-" + index}
            style={{
              ...overlayPositionStyle(overlay.x, overlay.y, overlay.rotation),
              color: overlay.color,
            }}
            className={[
              "pointer-events-none absolute z-10 -translate-x-1/2 -translate-y-1/2",
              "max-w-[80%] whitespace-pre-wrap text-center leading-tight",
              overlayScaleClass(overlay.scale),
              (OVERLAY_FONT_CLASS as any)[overlay.fontStyle] || OVERLAY_FONT_CLASS["sans-serif"],
              overlayPlateClass(overlay.bgMode, overlay.color),
            ].join(" ")}
          >
            {overlay.content}
          </span>
        ) : null
      )}

      {/* Tagged people. Tappable, exactly as in the app viewer: a mention
          nobody can follow is decoration. */}
      {mentions.map((mention, index) => {
        const mentionUser: any = mention && mention.user;
        const mentionId =
          typeof mentionUser === "string" ? mentionUser : mentionUser && mentionUser._id;
        if (!mentionId) return null;
        // The app's pill (story_viewer_screen.dart _buildMentionPills):
        // black at 0.55, white bold 13px, fully rounded.
        return (
          <Link
            key={index}
            data-testid={testIdPrefix + "-mention-" + index}
            to={"/community/" + mentionId}
            onClick={(e) => {
              e.stopPropagation();
              if (onNavigate) onNavigate();
            }}
            style={mentionPositionStyle(mention.position)}
            className="absolute z-10 -translate-x-1/2 -translate-y-1/2 rounded-full bg-black/55 px-2.5 py-1 text-[13px] font-bold text-white no-underline"
          >
            @{mention.username || (mentionUser && mentionUser.name) || ""}
          </Link>
        );
      })}

      {/* Link sticker. A real anchor, not window.open: the destination is
          visible on hover and in the context menu, and `noopener` keeps the
          opened tab away from this one. The host is shown when the author
          gave no label, so a tap is never a blind one. */}
      {story.link && story.link.url && (
        <a
          data-testid={testIdPrefix + "-link-sticker"}
          href={story.link.url}
          target="_blank"
          rel="noopener noreferrer nofollow"
          onClick={(e) => e.stopPropagation()}
          className="absolute bottom-24 left-1/2 z-10 -translate-x-1/2 rounded-chip bg-white/90 px-3 py-1.5 text-sm font-semibold text-ink-900 no-underline"
        >
          {(() => {
            const host = storyLinkHost(story.link);
            const label = story.link.displayText || story.link.title || host || story.link.url;
            return (
              <span className="flex flex-col items-center leading-tight">
                <span className="max-w-[16rem] truncate">{label}</span>
                {host && host !== String(label).toLowerCase() && (
                  <span
                    data-testid={testIdPrefix + "-link-host"}
                    dir="ltr"
                    className="max-w-[16rem] truncate text-[11px] font-normal text-ink-500"
                  >
                    {host}
                  </span>
                )}
              </span>
            );
          })()}
        </a>
      )}
    </>
  );
};

export default StoryCanvas;
