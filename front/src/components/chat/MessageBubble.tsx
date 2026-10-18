import React from "react";
import {
  MoreVertical,
  Paperclip,
  Play,
  Pause,
  Edit3,
  Globe,
  RefreshCw,
  Check,
  CheckCheck,
  Clock,
  CornerUpRight,
} from "lucide-react";
import { useTranslation } from "react-i18next";
import ReactionRow from "./actions/ReactionRow";
import CorrectionCard, { MessageCorrection } from "./components/CorrectionCard";
import TranslationCard from "./components/TranslationCard";
import { firstLink } from "./utils/linkDetector";
import CallMessageCard from "./components/CallMessageCard";
import LocationMessageCard, { MessageLocation } from "./components/LocationMessageCard";
import StoryReferenceCard from "./components/StoryReferenceCard";
import { CallData } from "./lib/callLabel";
import { isEmojiOnly, isWaveText } from "./lib/messageKinds";

/**
 * One message, lifted out of `ChatContent`'s `.map` unchanged — same classes,
 * same structure, same handlers — and wrapped in `React.memo`. Inlined, every
 * keystroke in the composer re-rendered the whole thread; memoized, only the
 * messages whose own props changed re-render.
 *
 * The shared message shapes live here because this is the component that
 * renders them; `ChatContent` imports them back.
 */

export interface MessageSender {
  _id: string;
  name: string;
  username?: string;
  images?: string[];
  userMode?: string;
}

export interface MessageReceiver {
  _id: string;
  name: string;
  username?: string;
  images?: string[];
}

export interface MessageMedia {
  url: string;
  type: string;
  thumbnail?: string;
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  duration?: number;
  waveform?: number[];
  dimensions?: { width: number; height: number };
  /** media.type 'call' (services/callMessageService.js). */
  callData?: CallData;
  location?: MessageLocation;
}

export type MessageStatus = "sending" | "sent" | "delivered" | "read" | "error";

export interface Message {
  _id: string;
  message: string;
  sender: MessageSender;
  receiver: MessageReceiver | string;
  messageType?: string;
  read?: boolean;
  /**
   * Set by the server once the receiver's socket actually has the message
   * (socket/socketHandler.js). A real field, not the `status` virtual, so it
   * survives a reload -- which is what keeps two ticks two ticks.
   */
  delivered?: boolean;
  readAt?: string;
  createdAt: string;
  updatedAt?: string;
  isOptimistic?: boolean;
  status?: MessageStatus;
  media?: MessageMedia;
  replyTo?: { _id: string; message: string; sender: { _id: string; name: string } };
  corrections?: MessageCorrection[];
  reactions?: Array<{ user: string; emoji: string; createdAt?: string }>;
  isEdited?: boolean;
  editedAt?: string;
  isForwarded?: boolean;
  forwardedFrom?: { sender?: string; messageId?: string; originalMessage?: string };
  pinned?: boolean;
  /** Set on story replies, reactions and shares (backend controllers/stories.js). */
  storyReference?: { storyId?: string | null; thumbnail?: string | null } | null;
  /** Deleted for everyone (the server rewrites `message` to "This message was deleted"). */
  isDeleted?: boolean;
  deletedForEveryone?: boolean;
}

export type BubblePosition = "single" | "first" | "middle" | "last";

export const formatDuration = (seconds: number): string => {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
};

/**
 * The corner the bubble loses where it meets its neighbour, as a class rather
 * than the inline `borderRadius` this used to compute. ChatContent.css owns
 * the eight rules (four positions x sent/received); a position the list does
 * not know keeps the default corners of `.message-bubble`.
 */
const BUBBLE_POSITIONS = ["single", "first", "middle", "last"];

const bubblePositionClass = (position: string): string =>
  BUBBLE_POSITIONS.indexOf(position) === -1 ? "" : ` message-bubble--${position}`;

/**
 * The vertical gap above a message, as a class rather than the inline
 * `marginTop` this used to compute. Two bubbles from the same sender sit
 * 2px apart; the first message of a new sender (or the first in its date
 * group) sits 8px below the previous group, and the very first message of
 * a group has none at all -- ChatContent.css owns the three values.
 */
const messageGapClass = (position: string, isFirstInGroup: boolean): string => {
  if (isFirstInGroup) return " modern-message--gap-none";
  return position === "middle" || position === "last"
    ? " modern-message--gap-tight"
    : " modern-message--gap-normal";
};

/**
 * A voice waveform bar's height is data-driven (one value per recorded
 * amplitude sample) and can't be named by a handful of classes the way the
 * bubble corners can. Rather than an inline `style`, it is quantised to the
 * nearest even pixel and looked up as `waveform-bar--h{N}` -- a bounded set
 * of classes (4..24 step 2) that ChatContent.css declares once.
 */
const WAVEFORM_BAR_MIN = 4;
const WAVEFORM_BAR_MAX = 24;
const waveformBarHeightClass = (amplitude: number): string => {
  const raw = (amplitude || 0.3) * WAVEFORM_BAR_MAX;
  const clamped = Math.min(WAVEFORM_BAR_MAX, Math.max(WAVEFORM_BAR_MIN, raw));
  const bucket = Math.round(clamped / 2) * 2;
  return ` waveform-bar--h${bucket}`;
};

/** The day heading above the first message of each day. */
export const DateSeparator: React.FC<{ label: string }> = ({ label }) => (
  <div className="date-separator">
    <span className="date-text">{label}</span>
  </div>
);

export interface MessageBubbleProps {
  message: Message;
  isSent: boolean;
  position: BubblePosition;
  /** First message of its date group — no top gap. */
  isFirstInGroup: boolean;
  showAvatar: boolean;
  hideAvatarSpace: boolean;
  avatarUrl: string;
  currentUserId: string;
  otherUserName: string;
  timeLabel: string;
  isTranslationOpen: boolean;
  targetLanguage: string;
  /** True only for the bubble whose voice note is playing. */
  isPlaying: boolean;
  audioProgress: number;
  audioElapsed: number;
  onTogglePlayback: (messageId: string, url: string) => void;
  onOpenActions: (message: Message) => void;
  onToggleReaction: (message: Message, emoji: string) => void;
  onToggleTranslation: (messageId: string) => void;
  onCorrect: (message: Message) => void;
  onCorrectionAccepted: (messageId: string, correctionId: string) => void;
  onRetry: (message: Message) => void;
  /** Opens the story a share/reply/reaction points at. */
  onOpenStory?: (storyId: string) => void;
}

const MessageBubbleView: React.FC<MessageBubbleProps> = ({
  message: msg,
  isSent,
  position,
  isFirstInGroup,
  showAvatar,
  hideAvatarSpace,
  avatarUrl,
  currentUserId,
  otherUserName,
  timeLabel,
  isTranslationOpen,
  targetLanguage,
  isPlaying,
  audioProgress,
  audioElapsed,
  onTogglePlayback,
  onOpenActions,
  onToggleReaction,
  onToggleTranslation,
  onCorrect,
  onCorrectionAccepted,
  onRetry,
  onOpenStory,
}) => {
  const { t } = useTranslation();

  // System placeholder created by createConversationRoom — show as a
  // centered notice instead of a chat bubble.
  if (msg.message === "Conversation started") {
    return (
      <div className="system-notice">
        <span>{t("chatPage.conversationStarted") || "Conversation started"}</span>
      </div>
    );
  }

  // Deleted for everyone: the app draws "This message was deleted" in place
  // (text_message_view.dart). No actions, no reactions, no media -- the
  // server already removed the file.
  if (msg.isDeleted || msg.deletedForEveryone) {
    return (
      <div
        data-msg-id={msg._id}
        className={`modern-message ${isSent ? "sent" : "received"}${messageGapClass(position, isFirstInGroup)}`}
      >
        {!isSent && <div className="message-avatar message-avatar--hidden" />}
        <div className="message-wrapper">
          <div
            className={`message-bubble message-bubble--deleted${bubblePositionClass(position)}`}
            data-testid="message-deleted-placeholder"
          >
            {t("chatPage.deleteMessage.placeholder") || "This message was deleted"}
          </div>
        </div>
      </div>
    );
  }

  const isVoice = msg.messageType === "voice" || msg.media?.type === "voice";
  // By content, like the app: a lone wave is a greeting card, 1-3 emoji are
  // sticker-sized, and a sentence stored as 'sticker' (the wave mirror does
  // that) is ordinary text.
  const isWave = !msg.media?.type && isWaveText(msg.message);
  const isSticker = !isWave && !msg.media?.type && isEmojiOnly(msg.message);
  const isGif =
    msg.messageType === "gif" ||
    (typeof msg.message === "string" &&
      /\.gif(\?|$)|giphy\.com\/media/i.test(msg.message));
  // A call record is media.type 'call' with an English fallback text; it is a
  // card of its own, never an attachment and never a text bubble.
  const isCall = msg.messageType === "call" || msg.media?.type === "call";
  const isLocation = msg.media?.type === "location";
  const hasMedia = !!msg.media?.type && !isVoice && !isCall && !isLocation;
  const isStoryShare = msg.messageType === "story_share";
  const isPlainText = !isWave && !isSticker && !isGif && !isVoice && !hasMedia && !isCall && !isLocation && !isStoryShare;
  const storyId = (msg.storyReference && msg.storyReference.storyId) || "";
  const showStoryRef = isStoryShare || !!storyId;
  const storyLabel = isStoryShare
    ? isSent
      ? t("chatPage.story.youShared") || "You shared a story"
      : t("chatPage.story.shared") || "Shared a story"
    : isSent
    ? t("chatPage.story.youReplied") || "You replied to their story"
    : t("chatPage.story.replied") || "Replied to your story";
  const link = isPlainText && msg.message ? firstLink(msg.message) : null;

  const renderVoiceMessage = () => {
    const duration = msg.media?.duration || 0;
    const bars = (msg.media?.waveform || Array(20).fill(0.3)).slice(0, 30);
    const playedCount = isPlaying ? Math.floor(audioProgress * bars.length) : 0;

    return (
      <div className="voice-message">
        <button
          className="voice-play-btn"
          onClick={(e) => {
            e.stopPropagation();
            if (msg.media?.url) onTogglePlayback(msg._id, msg.media.url);
          }}
        >
          {isPlaying ? <Pause size={16} /> : <Play size={16} />}
        </button>
        <div className="voice-waveform">
          <div className="voice-waveform-bars">
            {bars.map((v: number, i: number) => (
              <div
                key={i}
                className={`waveform-bar${i < playedCount ? " waveform-bar--played" : ""}${waveformBarHeightClass(v)}`}
              />
            ))}
          </div>
        </div>
        <span className="voice-duration">
          {isPlaying ? formatDuration(audioElapsed) : formatDuration(duration)}
        </span>
      </div>
    );
  };

  const renderMediaContent = () => {
    if (!msg.media || !msg.media.type) return null;

    const mediaType = msg.media.type || msg.messageType;

    if (mediaType === "voice") {
      return renderVoiceMessage();
    }
    if (mediaType === "location") {
      return <LocationMessageCard location={msg.media.location} />;
    }

    if (mediaType === "image" || msg.media.mimeType?.startsWith("image/")) {
      return (
        <div className="message-media">
          <img
            src={msg.media.url}
            alt="media"
            className="message-image"
            loading="lazy"
            decoding="async"
          />
        </div>
      );
    }

    if (mediaType === "video" || msg.media.mimeType?.startsWith("video/")) {
      return (
        <div className="message-media">
          {msg.media.thumbnail ? (
            <div className="video-thumbnail-wrapper">
              <img
                src={msg.media.thumbnail}
                alt="video"
                className="message-image"
                loading="lazy"
                decoding="async"
              />
              <div className="video-play-overlay">
                <Play size={32} />
              </div>
            </div>
          ) : (
            <video src={msg.media.url} controls className="message-video" preload="metadata" />
          )}
        </div>
      );
    }

    // Document/file
    return (
      <div className="message-file">
        <Paperclip size={16} />
        <span className="file-name">{msg.media.fileName || "File"}</span>
        {msg.media.fileSize && (
          <span className="file-size">
            {(msg.media.fileSize / 1024).toFixed(0)}KB
          </span>
        )}
      </div>
    );
  };

  /**
   * Ticks, not words: one check once the server has the message
   * (`messageSent`), two once the other person's client has it
   * (`messageDelivered`), two marked read on `messagesRead`.
   */
  const renderStatusIcon = () => {
    if (msg.sender._id !== currentUserId) return null;

    const status = msg.status || "sent";

    if (status === "error") {
      return (
        <span className="status-text error" data-testid="msg-status-error">
          {t("chatPage.status.failed") || "Failed"}
        </span>
      );
    }

    if (status === "sending") {
      const label = t("chatPage.status.sending") || "Sending";
      return (
        <span
          className="message-status-icon sending"
          data-testid="msg-status-sending"
          role="img"
          aria-label={label}
          title={label}
        >
          <Clock size={13} />
        </span>
      );
    }

    const label =
      status === "read"
        ? t("chatPage.status.read") || "Read"
        : status === "delivered"
        ? t("chatPage.status.delivered") || "Delivered"
        : t("chatPage.status.sent") || "Sent";

    return (
      <span
        className={`message-status-icon ${status}`}
        data-testid={`msg-status-${status}`}
        role="img"
        aria-label={label}
        title={label}
      >
        {status === "sent" ? <Check size={13} /> : <CheckCheck size={13} />}
      </span>
    );
  };

  return (
    <div
      data-msg-id={msg._id}
      className={`modern-message ${isSent ? "sent" : "received"} ${
        msg.status === "error" ? "error" : ""
      }${messageGapClass(position, isFirstInGroup)}`}
      onContextMenu={
        msg.isOptimistic
          ? undefined
          : (e) => {
              e.preventDefault();
              onOpenActions(msg);
            }
      }
    >
      {!isSent && (
        <div className={`message-avatar${showAvatar ? "" : " message-avatar--hidden"}`}>
          {(showAvatar || hideAvatarSpace) && (
            <img src={avatarUrl} alt={msg.sender.name} loading="lazy" decoding="async" />
          )}
        </div>
      )}

      <div className="message-wrapper">
        <div
          className={`message-bubble${isVoice ? " voice-bubble" : ""}${hasMedia ? " media-bubble" : ""}${isSticker ? " sticker-bubble" : ""}${isWave ? " sticker-bubble wave-bubble" : ""}${isCall ? " call-bubble" : ""}${bubblePositionClass(position)}`}
        >
          {showStoryRef && (
            <StoryReferenceCard
              storyId={String(storyId)}
              thumbnail={msg.storyReference && msg.storyReference.thumbnail}
              label={storyLabel}
              onOpen={onOpenStory}
            />
          )}
          {isCall ? (
            <CallMessageCard
              callData={msg.media && msg.media.callData}
              viewerId={currentUserId}
              isSent={isSent}
              otherName={otherUserName}
            />
          ) : isWave ? (
            <div className="wave-card" data-testid="wave-card">
              <span className="wave-card-hand" aria-hidden="true">{msg.message.trim()}</span>
              <span className="wave-card-text">{t("chatPage.wave.hi") || "Hi!"}</span>
            </div>
          ) : isSticker ? (
            <div className="sticker-message">{msg.message}</div>
          ) : isGif ? (
            <img
              className="gif-message"
              src={msg.message}
              alt={t("chatPage.gif.altText") || "GIF"}
              loading="lazy"
              decoding="async"
            />
          ) : (
            <>
              {msg.isForwarded && (
                <span className="message-forwarded" data-testid="message-forwarded">
                  <CornerUpRight size={12} aria-hidden="true" />
                  {t("chatPage.forwarded") || "Forwarded"}
                </span>
              )}

              {renderMediaContent()}

              {msg.replyTo && (
                <div className="reply-preview">
                  <span className="reply-sender">{msg.replyTo.sender.name}</span>
                  <span className="reply-text">{msg.replyTo.message}</span>
                </div>
              )}

              {msg.message && !isVoice && !isStoryShare && (
                <p className="message-text">{msg.message}</p>
              )}

              {/* A card for the first link in the message. Nothing is
                  fetched — the host and the URL are all the text itself
                  knows, and asking a third party for a title would leak
                  the conversation. */}
              {link && (
                <a
                  className="message-link-card"
                  data-testid="message-link-card"
                  href={link.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={(e) => e.stopPropagation()}
                >
                  <span className="message-link-host">{link.host}</span>
                  <span className="message-link-url">{link.text}</span>
                </a>
              )}

              {isTranslationOpen && msg.message && (
                <TranslationCard
                  messageId={msg._id}
                  originalText={msg.message}
                  targetLanguage={targetLanguage}
                  onClose={() => onToggleTranslation(msg._id)}
                />
              )}
            </>
          )}

          <div className="message-meta">
            {msg.isEdited && (
              <span className="message-edited" data-testid="message-edited">
                {t("chatPage.editedLabel") || "edited"}
              </span>
            )}
            <span className="message-time">{timeLabel}</span>
            {isSent && <div className="message-status">{renderStatusIcon()}</div>}
          </div>
        </div>

        {/* Message-actions trigger (opens MessageActionMenu) */}
        {!msg.isOptimistic && (
          <button
            type="button"
            className="msg-action-trigger"
            aria-label={t("chatPage.moreOptions") || "More options"}
            onClick={() => onOpenActions(msg)}
          >
            <MoreVertical size={14} />
          </button>
        )}

        {/* Reactions row (renders null when there are none) */}
        <ReactionRow
          reactions={msg.reactions}
          myUserId={currentUserId || ""}
          onToggle={(emoji) => onToggleReaction(msg, emoji)}
        />

        {/* Correction card lives OUTSIDE the bubble so it always
            renders on a white background — readable for both
            sent (teal) and received (grey) bubbles. */}
        {msg.corrections &&
          msg.corrections.map((correction) => (
            <CorrectionCard
              key={correction._id}
              messageId={msg._id}
              correction={correction}
              isMe={isSent}
              currentUserId={currentUserId || ""}
              otherUserName={otherUserName}
              onAccepted={(correctionId) => onCorrectionAccepted(msg._id, correctionId)}
            />
          ))}

        {!isSent && !isWave && !isSticker && !isVoice && !hasMedia && !isCall && !isLocation && msg.message && (
          <div className="message-chip-row">
            {/* Hide Correct chip once a correction already exists */}
            {!(msg.corrections && msg.corrections.length > 0) && (
              <button
                type="button"
                className="correct-chip"
                onClick={() => onCorrect(msg)}
                title={t("chatPage.suggestCorrection") || "Suggest a correction"}
              >
                <Edit3 size={12} />
                <span>{t("chatPage.correct") || "Correct"}</span>
              </button>
            )}
            <button
              type="button"
              className={`translate-chip ${isTranslationOpen ? "active" : ""}`}
              onClick={() => onToggleTranslation(msg._id)}
              title={t("chatPage.translateThis") || "Translate this message"}
            >
              <Globe size={12} />
              <span>
                {isTranslationOpen
                  ? t("chatPage.hide_translation") || "Hide"
                  : t("chatPage.translate") || "Translate"}
              </span>
            </button>
          </div>
        )}

        {msg.status === "error" && (
          <button
            className="retry-btn"
            onClick={() => onRetry(msg)}
            title={t("chatPage.retrySending") || "Retry sending"}
          >
            <RefreshCw size={14} />
            <span>{t("chatPage.retry") || "Retry"}</span>
          </button>
        )}
      </div>
    </div>
  );
};

const MessageBubble = React.memo(MessageBubbleView);

export default MessageBubble;
