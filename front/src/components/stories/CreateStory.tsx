import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  AtSign,
  BarChart3,
  Check,
  Hash,
  Image as ImageIcon,
  Link2,
  MessageCircleQuestion,
  Move,
  Plus,
  Trash2,
  Type,
  Video as VideoIcon,
  X,
} from "lucide-react";
import {
  useCreateStoryMutation,
  useCreateVideoStoryMutation,
  useGetVideoConfigQuery,
  useGetCloseFriendsQuery,
} from "../../store/slices/storiesSlice";
import { useGetFollowingsQuery } from "../../store/slices/usersSlice";
import { useSelector } from "react-redux";
import SurfaceCard from "../../design/SurfaceCard";
import notify from "../../design/notify";
import { showDailyLimitToast } from "../vip/dailyLimit";
import {
  LinkDraft,
  MentionDraft,
  MENTION_MAX_COUNT,
  newOverlayDraft,
  nextOverlayId,
  OverlayBgMode,
  OverlayDraft,
  OverlayFontStyle,
  overlayPlateClass,
  OVERLAY_BG_MODES,
  OVERLAY_COLORS,
  OVERLAY_FONT_CLASS,
  OVERLAY_FONT_STYLES,
  OVERLAY_MAX_COUNT,
  OVERLAY_SCALE_STEPS,
  clamp01,
  formatMegabytes,
  overlayPositionStyle,
  overlayScaleClass,
  parseLinkUrl,
  serializeLink,
  serializeMentions,
  serializeOverlays,
  storyBodyFontClass,
  videoConstraintsOf,
  videoDurationError,
  videoFileError,
} from "./storyOverlays";

/**
 * The story composer.
 *
 * What changed in Phase 2 is not the buttons but what leaves the page: text and
 * emoji stickers, tagged people and the link sticker now travel as STRUCTURED
 * JSON (`overlays`, `mentions`, `link`) in the shape `controllers/stories.js`
 * parses, instead of being dropped on the floor as they were before. Nothing is
 * baked into the image — the app's studio uploads the same JSON, so a story
 * composed here is legible there and the wire format is the contract, not the
 * pixels. Drawing and filters, which the app DOES bake client-side, are out of
 * scope: a canvas editor is its own project.
 *
 * Positions are normalized here and only here (see `storyOverlays.ts`): the
 * canvas is whatever size the viewport gives it, so fractions are the only
 * placement that survives the trip to a 1080x1920 phone.
 */

type Step = "media" | "edit";
type StickerPanel = "poll" | "question" | "hashtag" | "mention" | "link" | null;

const PAGE = "min-h-screen bg-canvas px-4 py-6 dark:bg-canvas-dark";
const COLUMN = "mx-auto w-full max-w-3xl space-y-4";
const FIELD = [
  "w-full rounded-card border border-line bg-surface px-3 py-2 text-sm",
  "text-ink-900 placeholder:text-ink-400",
  "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
].join(" ");
const PRIMARY = [
  "inline-flex items-center gap-1.5 rounded-chip bg-brand-deep px-3.5 py-1.5 text-sm font-semibold text-white",
  "transition hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-50",
].join(" ");
const GHOST = [
  "inline-flex items-center gap-1.5 rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700",
  "transition hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-50",
  "dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800",
].join(" ");
const TOOL = [
  "flex flex-1 flex-col items-center gap-1.5 rounded-card border border-line px-3 py-4 text-sm font-medium",
  "text-ink-700 transition hover:bg-ink-100",
  "dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800",
].join(" ");
const LABEL = "text-xs font-semibold uppercase tracking-wide text-ink-500 dark:text-ink-400";
const SELECT = [
  "rounded-chip border border-line bg-surface px-2 py-1 text-xs text-ink-800",
  "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-100",
].join(" ");

/** The quick emoji row. These are story CONTENT — the character the author
 * places on the picture — not icons standing in for an action. */
const QUICK_EMOJI = ["😂", "❤️", "🔥", "🎉", "👏", "😮"];

const BG_COLORS = OVERLAY_COLORS.map((c) => c.hex);

/** A text story's font as the overlay vocabulary spells it. */
const BODY_OVERLAY_FONT: { [k: string]: OverlayFontStyle } = {
  normal: "sans-serif",
  bold: "bold",
  // The overlay vocabulary has no italic. Serif is a different typeface, not
  // a slant; the plain face is the honest nearest, and the story's own
  // `fontStyle: "italic"` still travels for clients that read it.
  italic: "sans-serif",
  handwriting: "handwritten",
};

/** `parseStickerFields()` rejects a poll with more than four options. */
const POLL_MAX_OPTIONS = 4;
const POLL_MIN_OPTIONS = 2;

interface RootState {
  auth: {
    userInfo?: {
      user?: { _id: string };
      data?: { _id: string };
    };
  };
}

const CreateStory: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  // Locally typed rather than imported from ../../store: TS 3.7 has no
  // `import type`, so importing RootState would pull the whole store --
  // apiSlice, every reducer -- into this chunk and into this file's tests.
  const currentUserId = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?._id || state.auth.userInfo?.data?._id || null
  );

  const [step, setStep] = useState<Step>("media");
  const [mediaFiles, setMediaFiles] = useState<File[]>([]);
  const [mediaPreviews, setMediaPreviews] = useState<string[]>([]);
  const [mediaType, setMediaType] = useState<"image" | "video" | "text">("image");
  const [currentMediaIndex, setCurrentMediaIndex] = useState(0);
  const [mediaError, setMediaError] = useState<string | null>(null);

  // Text story body (distinct from the overlay vocabulary: this is the
  // centered caption the backend stores on `text`/`fontStyle`).
  const [text, setText] = useState("");
  // A photo or video story's caption. It travels on the same `text` field
  // (the app's caption field does too) and is shown under the picture.
  const [caption, setCaption] = useState("");
  const [backgroundColor, setBackgroundColor] = useState("#000000");
  const [textColor, setTextColor] = useState("#FFFFFF");
  const [fontStyle, setFontStyle] = useState<"normal" | "bold" | "italic" | "handwriting">("normal");

  const [privacy, setPrivacy] = useState<"public" | "friends" | "close_friends">("public");

  const [overlays, setOverlays] = useState<OverlayDraft[]>([]);
  const [mentions, setMentions] = useState<MentionDraft[]>([]);
  const [link, setLink] = useState<LinkDraft>({ url: "", title: "", displayText: "" });
  const [linkOn, setLinkOn] = useState(false);

  const [panel, setPanel] = useState<StickerPanel>(null);
  const [mentionQuery, setMentionQuery] = useState("");

  const [poll, setPoll] = useState<{ question: string; options: string[]; isAnonymous: boolean } | null>(null);
  const [questionBox, setQuestionBox] = useState<{ prompt: string } | null>(null);
  // Why the poll or question sticker cannot be sent as it stands. Shown
  // inline under the sticker; cleared as soon as the author edits it.
  const [stickerError, setStickerError] = useState<string | null>(null);
  const [hashtags, setHashtags] = useState<string[]>([]);
  const [hashtagInput, setHashtagInput] = useState("");

  const fileInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);
  const canvasRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<{ kind: "overlay" | "mention"; index: number } | null>(null);

  const [createStory, { isLoading: isCreating }] = useCreateStoryMutation();
  const [createVideoStory, { isLoading: isCreatingVideo }] = useCreateVideoStoryMutation();

  // Public endpoint, and the numbers are server constants — the slice keeps
  // them for ten minutes, so opening the composer twice costs one request.
  const { data: videoConfigData } = useGetVideoConfigQuery(undefined);
  const videoLimits = useMemo(() => videoConstraintsOf(videoConfigData), [videoConfigData]);

  // Only asked for once the author actually chooses close friends: an empty
  // list is the one thing worth interrupting them about, and a story posted to
  // nobody is the failure this prevents.
  const { data: closeFriendsData } = useGetCloseFriendsQuery(undefined, {
    skip: privacy !== "close_friends",
  });
  const closeFriendsCount = useMemo(() => {
    const payload = closeFriendsData as any;
    if (!payload) return null;
    const list = Array.isArray(payload) ? payload : payload.data;
    return Array.isArray(list) ? list.length : null;
  }, [closeFriendsData]);

  // Mentions come from the people the author FOLLOWS, not from a search of
  // every member -- app parity (`mention_sheet.dart` lists followings) and a
  // privacy fix. `POST /stories` drops a mention of a user that does not
  // exist but does not check that the author may tag them, so a member
  // search here meant anyone could push a notification at a stranger.
  // One request, filtered in the browser: the followings list is small, the
  // endpoint takes no query, and typing then costs nothing.
  const { data: followingsData, isFetching: isLoadingFollowings } = useGetFollowingsQuery(
    { userId: currentUserId || "" },
    { skip: !currentUserId || panel !== "mention" }
  );
  const followings = useMemo(() => {
    const payload = followingsData as any;
    if (!payload) return [];
    const list = Array.isArray(payload) ? payload : payload.data;
    return Array.isArray(list) ? list : [];
  }, [followingsData]);

  const mentionSearch = mentionQuery.trim().toLowerCase();
  const searchResults = useMemo(() => {
    if (!mentionSearch) return followings;
    return followings.filter((user: any) => {
      const name = String((user && user.name) || "").toLowerCase();
      const username = String((user && user.username) || "").toLowerCase();
      return name.indexOf(mentionSearch) > -1 || username.indexOf(mentionSearch) > -1;
    });
  }, [followings, mentionSearch]);

  useEffect(
    () => () => {
      mediaPreviews.forEach((url) => URL.revokeObjectURL(url));
    },
    // Runs on unmount only: revoking on every preview change would kill the
    // <img> currently on screen.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  const resetMedia = useCallback(() => {
    setMediaFiles([]);
    setMediaPreviews((prev) => {
      prev.forEach((url) => URL.revokeObjectURL(url));
      return [];
    });
    setCurrentMediaIndex(0);
    setStep("media");
  }, []);

  const handleFileSelect = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = Array.from(e.target.files || []);
      if (fileInputRef.current) fileInputRef.current.value = "";
      if (videoInputRef.current) videoInputRef.current.value = "";
      if (files.length === 0) return;
      setMediaError(null);

      const images = files.filter((f) => f.type.indexOf("image/") === 0);
      const videos = files.filter((f) => f.type.indexOf("video/") === 0);

      if (videos.length > 0) {
        // Checked BEFORE the editor opens: composing a story on top of a file
        // the server will refuse wastes the only part of this that is work.
        const reason = videoFileError(videos[0], videoLimits);
        if (reason === "type") {
          setMediaError(t("stories.video_type_error") || "That video format isn't supported");
          return;
        }
        if (reason === "size") {
          setMediaError(
            (t("stories.video_size_error") || "That video is larger than") +
              " " +
              formatMegabytes(videoLimits)
          );
          return;
        }
        setMediaType("video");
        setMediaFiles(videos.slice(0, 1));
        setMediaPreviews(videos.slice(0, 1).map((file) => URL.createObjectURL(file)));
        setStep("edit");
        return;
      }

      if (images.length > 0) {
        // One picture per story, as in the app: every viewer (this one and
        // the app's) draws mediaUrls[0] only, so pictures 2-5 used to be
        // uploaded and never seen by anyone.
        if (images.length > 1) {
          notify.info(
            t("stories.one_image_only") || "A story shows one picture. We kept the first one."
          );
        }
        setMediaType("image");
        setMediaFiles(images.slice(0, 1));
        setMediaPreviews(images.slice(0, 1).map((file) => URL.createObjectURL(file)));
        setStep("edit");
      }
    },
    [t, videoLimits]
  );

  /** Duration is the one constraint the browser only learns after it has read
   * the file's header, so it is enforced here rather than at selection. */
  const handleVideoMetadata = useCallback(
    (e: React.SyntheticEvent<HTMLVideoElement>) => {
      const seconds = e.currentTarget.duration;
      if (videoDurationError(seconds, videoLimits)) {
        setMediaError(
          (t("stories.video_duration_error") || "That video is longer than") +
            " " +
            (videoLimits && videoLimits.maxDurationFormatted ? videoLimits.maxDurationFormatted : "")
        );
        resetMedia();
      }
    },
    [resetMedia, t, videoLimits]
  );

  // ---------------------------------------------------------------- overlays

  const addOverlay = useCallback(
    (partial: Partial<OverlayDraft>) => {
      setOverlays((prev) =>
        prev.length >= OVERLAY_MAX_COUNT ? prev : prev.concat([newOverlayDraft(partial)])
      );
    },
    []
  );

  const patchOverlay = useCallback((index: number, patch: Partial<OverlayDraft>) => {
    setOverlays((prev) => prev.map((o, i) => (i === index ? { ...o, ...patch } : o)));
  }, []);

  const removeOverlay = useCallback((index: number) => {
    setOverlays((prev) => prev.filter((_, i) => i !== index));
  }, []);

  // ---------------------------------------------------------------- mentions

  const addMention = useCallback((user: { _id: string; name?: string }) => {
    setMentions((prev) => {
      if (prev.length >= MENTION_MAX_COUNT) return prev;
      if (prev.some((m) => m.userId === user._id)) return prev;
      // Same default spot as the app's mention sheet (x 50 / y 80 on its
      // 0-100 scale), then draggable from there.
      return prev.concat([
        { id: nextOverlayId("mn"), userId: user._id, name: user.name || "", x: 0.5, y: 0.8 },
      ]);
    });
  }, []);

  const removeMention = useCallback((index: number) => {
    setMentions((prev) => prev.filter((_, i) => i !== index));
  }, []);

  // ------------------------------------------------------------------ drag

  const pointFrom = (e: React.PointerEvent): { x: number; y: number } | null => {
    const el = canvasRef.current;
    if (!el) return null;
    const rect = el.getBoundingClientRect();
    if (!rect.width || !rect.height) return null;
    return {
      x: clamp01((e.clientX - rect.left) / rect.width),
      y: clamp01((e.clientY - rect.top) / rect.height),
    };
  };

  const startDrag = (kind: "overlay" | "mention", index: number) => (
    e: React.PointerEvent<HTMLElement>
  ) => {
    dragRef.current = { kind, index };
    const target = e.currentTarget as any;
    // Pointer capture is what makes one handler serve mouse, pen and touch:
    // the moves keep arriving at this node even when the finger outruns it.
    // jsdom has no implementation, hence the guard.
    if (target && typeof target.setPointerCapture === "function") {
      try {
        target.setPointerCapture(e.pointerId);
      } catch (err) {
        /* capture is an optimisation, never a requirement */
      }
    }
  };

  const onDragMove = (e: React.PointerEvent<HTMLElement>) => {
    const drag = dragRef.current;
    if (!drag) return;
    const point = pointFrom(e);
    if (!point) return;
    if (drag.kind === "overlay") {
      setOverlays((prev) => prev.map((o, i) => (i === drag.index ? { ...o, x: point.x, y: point.y } : o)));
    } else {
      setMentions((prev) => prev.map((m, i) => (i === drag.index ? { ...m, x: point.x, y: point.y } : m)));
    }
  };

  const endDrag = (e: React.PointerEvent<HTMLElement>) => {
    dragRef.current = null;
    const target = e.currentTarget as any;
    if (target && typeof target.releasePointerCapture === "function") {
      try {
        target.releasePointerCapture(e.pointerId);
      } catch (err) {
        /* nothing to release */
      }
    }
  };

  // --------------------------------------------------------------- stickers

  const openPoll = useCallback(() => {
    // Poll XOR question, enforced here rather than at submit: the backend
    // returns 400 for both at once, and a composer that lets you build the
    // second one only to reject it has wasted the author's time.
    setQuestionBox(null);
    setStickerError(null);
    setPoll({ question: "", options: ["", ""], isAnonymous: false });
    setPanel("poll");
  }, []);

  const openQuestion = useCallback(() => {
    setPoll(null);
    setStickerError(null);
    setQuestionBox({ prompt: t("stories.question_box.ask_me_anything") || "Ask me anything!" });
    setPanel("question");
  }, [t]);

  const addHashtag = useCallback(() => {
    const tag = hashtagInput.trim().replace(/^#/, "").toLowerCase();
    if (tag && hashtags.indexOf(tag) === -1 && hashtags.length < 10) {
      setHashtags(hashtags.concat([tag]));
    }
    setHashtagInput("");
  }, [hashtagInput, hashtags]);

  const linkInvalid = linkOn && link.url.trim().length > 0 && !parseLinkUrl(link.url);

  // ----------------------------------------------------------------- submit

  const handleSubmit = useCallback(async () => {
    // A text story must carry text. Overlays are NOT a substitute: the
    // backend rejects a story with neither media nor `text` (400 "Story must
    // have media or text"), so an overlay-only submit could only ever fail
    // after the upload -- better to say so before it.
    if (mediaType === "text" && !text.trim()) {
      notify.error(t("stories.add_text") || "Please add text to your story");
      return;
    }
    if (mediaType !== "text" && mediaFiles.length === 0) {
      notify.error(t("stories.upload_media") || "Please upload media");
      return;
    }
    if (linkInvalid) {
      notify.error(t("stories.link_invalid") || "That link doesn't look right");
      return;
    }

    // The server trims and then rejects (400) a blank question, fewer than
    // two options or more than four; a whitespace-only field is blank. Say so
    // here, next to the sticker, instead of after the upload -- and never
    // drop the sticker silently and post the story without it.
    let pollPayload: { question: string; options: string[]; isAnonymous: boolean } | null = null;
    let questionPayload: { prompt: string } | null = null;
    if (poll) {
      const question = poll.question.trim();
      const options = poll.options.map((o) => o.trim());
      let reason: string | null = null;
      if (!question) {
        reason = t("stories.poll_error_question") || "Add a question to your poll";
      } else if (options.some((o) => !o)) {
        reason = t("stories.poll_error_blank_option") || "Fill in or remove the empty poll options";
      } else if (options.length < POLL_MIN_OPTIONS) {
        reason = t("stories.poll_error_min_options") || "A poll needs at least two options";
      } else if (options.length > POLL_MAX_OPTIONS) {
        reason = t("stories.poll_error_max_options") || "A poll can have at most four options";
      }
      if (reason) {
        setStickerError(reason);
        setPanel("poll");
        notify.error(reason);
        return;
      }
      pollPayload = { question, options, isAnonymous: poll.isAnonymous };
    } else if (questionBox) {
      const prompt = questionBox.prompt.trim();
      if (!prompt) {
        const reason = t("stories.question_error_prompt") || "Add a question to your question sticker";
        setStickerError(reason);
        setPanel("question");
        notify.error(reason);
        return;
      }
      questionPayload = { prompt };
    }

    const formData = new FormData();
    if (mediaType === "video") {
      if (mediaFiles[0]) formData.append("video", mediaFiles[0]);
    } else if (mediaType !== "text") {
      mediaFiles.forEach((file) => formData.append("media", file));
    }

    if (mediaType === "text") {
      formData.append("text", text);
      formData.append("backgroundColor", backgroundColor);
      formData.append("textColor", textColor);
      formData.append("fontStyle", fontStyle);
    } else if (caption.trim()) {
      formData.append("text", caption.trim());
    }

    formData.append("privacy", privacy);

    // Cross-client rule: the app hides a text story's `text` whenever it has
    // overlays (it sends `text` as the overlays joined). So a web text story
    // with stickers also carries its body as the FIRST overlay -- centred,
    // x/y being the overlay's centre as a 0-1 fraction, as in the app's
    // OverlayDraft -- and keeps sending `text` for clients without overlays.
    const userOverlays = serializeOverlays(overlays);
    const body = text.trim();
    const serializedOverlays =
      mediaType === "text" && body && userOverlays.length > 0
        ? serializeOverlays([
            newOverlayDraft({
              type: "text",
              content: body,
              x: 0.5,
              y: 0.5,
              scale: 1.5,
              color: /^#[0-9a-fA-F]{6}$/.test(textColor) ? textColor : "#FFFFFF",
              fontStyle: BODY_OVERLAY_FONT[fontStyle] || "sans-serif",
              bgMode: "none",
            }),
            ...overlays,
          ])
        : userOverlays;
    if (serializedOverlays.length > 0) {
      formData.append("overlays", JSON.stringify(serializedOverlays));
    }

    const serializedMentions = serializeMentions(mentions);
    if (serializedMentions.length > 0) {
      formData.append("mentions", JSON.stringify(serializedMentions));
    }

    const serializedLink = linkOn ? serializeLink(link) : null;
    if (serializedLink) formData.append("link", JSON.stringify(serializedLink));

    if (pollPayload) {
      formData.append("poll", JSON.stringify(pollPayload));
    } else if (questionPayload) {
      formData.append("questionBox", JSON.stringify(questionPayload));
    }

    if (hashtags.length > 0) formData.append("hashtags", JSON.stringify(hashtags));

    try {
      if (mediaType === "video") {
        await createVideoStory(formData).unwrap();
      } else {
        await createStory(formData).unwrap();
      }
      notify.success(t("stories.story_created") || "Story shared");
      navigate("/moments");
    } catch (error: any) {
      // The daily story limit (429): the VIP upgrade toast instead.
      if (showDailyLimitToast(error)) return;
      notify.error(
        (error && error.data && error.data.error) ||
          t("stories.create_story_failed") ||
          "Couldn't share your story"
      );
    }
  }, [
    backgroundColor,
    caption,
    createStory,
    createVideoStory,
    fontStyle,
    hashtags,
    link,
    linkInvalid,
    linkOn,
    mediaFiles,
    mediaType,
    mentions,
    navigate,
    overlays,
    poll,
    privacy,
    questionBox,
    t,
    text,
    textColor,
  ]);

  const handleClose = useCallback(() => {
    mediaPreviews.forEach((url) => URL.revokeObjectURL(url));
    navigate("/moments");
  }, [mediaPreviews, navigate]);

  // ------------------------------------------------------------------ views

  const videoHint = videoLimits ? (
    <p data-testid="video-constraints" className="text-xs text-ink-500 dark:text-ink-400">
      {t("stories.video_limits") || "Video"}:{" "}
      {videoLimits.maxDurationFormatted || ""} · {formatMegabytes(videoLimits)} ·{" "}
      {(videoLimits.allowedTypes || []).join(", ")}
    </p>
  ) : null;

  const renderCanvasBackground = () => {
    if (mediaType === "text") {
      return (
        <div
          // Author data, not theme: the colours they picked for this story.
          style={{ backgroundColor, color: textColor }}
          className={
            "flex h-full w-full items-center justify-center p-6 text-center text-lg " +
            storyBodyFontClass(fontStyle)
          }
        >
          {text}
        </div>
      );
    }
    const preview = mediaPreviews[currentMediaIndex];
    if (!preview) return <div className="h-full w-full bg-ink-800" />;
    if (mediaType === "video") {
      return (
        <video
          data-testid="story-video-preview"
          src={preview}
          className="h-full w-full object-cover"
          onLoadedMetadata={handleVideoMetadata}
          muted
          playsInline
          controls
        />
      );
    }
    return <img src={preview} alt="" className="h-full w-full object-cover" />;
  };

  return (
    <div className={PAGE}>
      <div className={COLUMN}>
        <header className="flex items-center justify-between gap-3">
          <button type="button" className={GHOST} onClick={handleClose} data-testid="close-composer">
            <X size={16} aria-hidden />
            {t("stories.cancel") || "Cancel"}
          </button>
          <h1 className="text-base font-semibold text-ink-900 dark:text-ink-50">
            {t("stories.create_first_story") || "Create story"}
          </h1>
          {step === "edit" ? (
            <button
              type="button"
              data-testid="share-story"
              className={PRIMARY}
              onClick={handleSubmit}
              disabled={isCreating || isCreatingVideo}
            >
              <Check size={16} aria-hidden />
              {t("stories.share_story") || "Share"}
            </button>
          ) : (
            <span className="w-20" />
          )}
        </header>

        {mediaError && (
          <p
            data-testid="media-error"
            role="alert"
            className="rounded-card border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-900 dark:bg-red-950 dark:text-red-200"
          >
            {mediaError}
          </p>
        )}

        {step === "media" ? (
          <SurfaceCard padding="lg">
            <div className="flex flex-col gap-3 sm:flex-row">
              <button type="button" className={TOOL} data-testid="pick-photo" onClick={() => fileInputRef.current && fileInputRef.current.click()}>
                <ImageIcon size={20} aria-hidden />
                {t("stories.choose_photo") || "Photo"}
              </button>
              <button type="button" className={TOOL} data-testid="pick-video" onClick={() => videoInputRef.current && videoInputRef.current.click()}>
                <VideoIcon size={20} aria-hidden />
                {t("stories.choose_video") || "Video"}
              </button>
              <button
                type="button"
                className={TOOL}
                data-testid="pick-text"
                onClick={() => {
                  setMediaType("text");
                  setStep("edit");
                }}
              >
                <Type size={20} aria-hidden />
                {t("stories.text_story") || "Text"}
              </button>
            </div>
            <div className="mt-3">{videoHint}</div>
            <input
              ref={fileInputRef}
              data-testid="photo-input"
              type="file"
              accept="image/*"
              onChange={handleFileSelect}
              className="hidden"
            />
            <input
              ref={videoInputRef}
              data-testid="video-input"
              type="file"
              accept="video/*"
              onChange={handleFileSelect}
              className="hidden"
            />
          </SurfaceCard>
        ) : (
          <div className="space-y-4">
            {/* The canvas. Overlays and mentions live OUTSIDE the background
                element so nothing is ever flattened into the picture. */}
            <div
              ref={canvasRef}
              data-testid="story-canvas"
              className="relative mx-auto aspect-[9/16] w-full max-w-xs touch-none overflow-hidden rounded-card bg-black"
            >
              {renderCanvasBackground()}

              {overlays.map((overlay, index) => (
                <span
                  key={overlay.id}
                  data-testid={"overlay-node-" + index}
                  role="button"
                  tabIndex={0}
                  aria-label={t("stories.move_sticker") || "Move sticker"}
                  onPointerDown={startDrag("overlay", index)}
                  onPointerMove={onDragMove}
                  onPointerUp={endDrag}
                  onPointerCancel={endDrag}
                  // The two numbers out of the JSON. Nothing else here is
                  // inline: font, weight, plate and size are all classes.
                  style={{
                    ...overlayPositionStyle(overlay.x, overlay.y),
                    color: overlay.color,
                  }}
                  className={[
                    "absolute -translate-x-1/2 -translate-y-1/2 cursor-move select-none whitespace-pre-wrap text-center leading-tight",
                    overlayScaleClass(overlay.scale),
                    OVERLAY_FONT_CLASS[overlay.fontStyle],
                    overlayPlateClass(overlay.bgMode, overlay.color),
                  ].join(" ")}
                >
                  {overlay.content || (t("stories.tap_to_type") || "Tap to type")}
                </span>
              ))}

              {mentions.map((mention, index) => (
                <span
                  key={mention.id}
                  data-testid={"mention-node-" + index}
                  role="button"
                  tabIndex={0}
                  aria-label={t("stories.move_sticker") || "Move sticker"}
                  onPointerDown={startDrag("mention", index)}
                  onPointerMove={onDragMove}
                  onPointerUp={endDrag}
                  onPointerCancel={endDrag}
                  style={overlayPositionStyle(mention.x, mention.y)}
                  className="absolute -translate-x-1/2 -translate-y-1/2 cursor-move select-none rounded-full bg-black/55 px-2.5 py-1 text-[13px] font-bold text-white"
                >
                  @{mention.name}
                </span>
              ))}

              {mediaType !== "text" && caption.trim() && (
                <p
                  data-testid="story-caption-preview"
                  className="pointer-events-none absolute inset-x-3 bottom-12 m-0 whitespace-pre-wrap break-words text-center text-sm text-white drop-shadow-[0_1px_3px_rgba(0,0,0,0.9)]"
                >
                  {caption.trim()}
                </p>
              )}

              {linkOn && parseLinkUrl(link.url) && (
                <span
                  data-testid="link-sticker-preview"
                  className="absolute bottom-3 left-1/2 -translate-x-1/2 rounded-chip bg-white/85 px-2.5 py-1 text-xs font-semibold text-ink-900"
                >
                  {link.displayText.trim() || parseLinkUrl(link.url)!.host}
                </span>
              )}
            </div>

            {/* Photo / video caption */}
            {mediaType !== "text" && (
              <SurfaceCard padding="md">
                <label className={LABEL} htmlFor="story-caption-field">
                  {t("stories.caption") || "Caption"}
                </label>
                <textarea
                  id="story-caption-field"
                  data-testid="story-caption"
                  value={caption}
                  onChange={(e) => setCaption(e.target.value)}
                  maxLength={2200}
                  rows={2}
                  placeholder={t("stories.caption_placeholder") || "Add a caption…"}
                  className={FIELD + " mt-1"}
                />
              </SurfaceCard>
            )}

            {/* Text story body */}
            {mediaType === "text" && (
              <SurfaceCard padding="md">
                <label className={LABEL} htmlFor="story-text-field">
                  {t("stories.story_text") || "Story text"}
                </label>
                <textarea
                  id="story-text-field"
                  data-testid="story-text"
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  maxLength={2200}
                  rows={3}
                  placeholder={t("stories.add_text") || "Type your story…"}
                  className={FIELD + " mt-1"}
                />
                <div className="mt-3 flex flex-wrap items-center gap-4">
                  <div>
                    <p className={LABEL}>{t("stories.background") || "Background"}</p>
                    <div className="mt-1 flex flex-wrap gap-1.5">
                      {OVERLAY_COLORS.map((color, i) => (
                        <button
                          key={color.hex}
                          type="button"
                          aria-label={t("stories.background") || "Background"}
                          data-testid={"bg-color-" + i}
                          onClick={() => setBackgroundColor(BG_COLORS[i])}
                          className={
                            "h-6 w-6 rounded-full border border-line " +
                            color.swatch +
                            (backgroundColor === color.hex ? " ring-2 ring-brand-deep" : "")
                          }
                        />
                      ))}
                    </div>
                  </div>
                  <div>
                    <p className={LABEL}>{t("stories.text_color") || "Text"}</p>
                    <div className="mt-1 flex flex-wrap gap-1.5">
                      {OVERLAY_COLORS.map((color, i) => (
                        <button
                          key={color.hex}
                          type="button"
                          aria-label={t("stories.text_color") || "Text"}
                          data-testid={"text-color-" + i}
                          onClick={() => setTextColor(color.hex)}
                          className={
                            "h-6 w-6 rounded-full border border-line " +
                            color.swatch +
                            (textColor === color.hex ? " ring-2 ring-brand-deep" : "")
                          }
                        />
                      ))}
                    </div>
                  </div>
                  <div>
                    <p className={LABEL}>{t("stories.font_style") || "Font"}</p>
                    <select
                      data-testid="story-font"
                      className={SELECT + " mt-1"}
                      value={fontStyle}
                      onChange={(e) => setFontStyle(e.target.value as any)}
                    >
                      {(["normal", "bold", "italic", "handwriting"] as const).map((s) => (
                        <option key={s} value={s}>
                          {t("stories.font." + s) || s}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </SurfaceCard>
            )}

            {/* Overlays */}
            <SurfaceCard padding="md">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <p className={LABEL}>{t("stories.stickers_text") || "Text & emoji"}</p>
                <span className="text-xs text-ink-500 dark:text-ink-400">
                  {overlays.length}/{OVERLAY_MAX_COUNT}
                </span>
              </div>
              <div className="mt-2 flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  data-testid="add-text-overlay"
                  className={GHOST}
                  disabled={overlays.length >= OVERLAY_MAX_COUNT}
                  onClick={() => addOverlay({ type: "text" })}
                >
                  <Plus size={16} aria-hidden />
                  {t("stories.add_text_sticker") || "Add text"}
                </button>
                {QUICK_EMOJI.map((emoji) => (
                  <button
                    key={emoji}
                    type="button"
                    data-testid={"add-emoji-" + emoji}
                    aria-label={t("stories.add_emoji_sticker") || "Add emoji"}
                    disabled={overlays.length >= OVERLAY_MAX_COUNT}
                    className={
                      "rounded-chip border border-line px-2 py-1 text-base transition hover:bg-ink-100 disabled:opacity-50 dark:border-line-dark dark:hover:bg-ink-800"
                    }
                    onClick={() => addOverlay({ type: "emoji", content: emoji, scale: 1.5 })}
                  >
                    {emoji}
                  </button>
                ))}
              </div>

              <ul className="mt-3 space-y-2">
                {overlays.map((overlay, index) => (
                  <li
                    key={overlay.id}
                    className="rounded-card border border-line p-2 dark:border-line-dark"
                  >
                    <div className="flex items-center gap-2">
                      <Move size={14} aria-hidden className="shrink-0 text-ink-400" />
                      <input
                        data-testid={"overlay-content-" + index}
                        value={overlay.content}
                        maxLength={500}
                        aria-label={t("stories.sticker_text") || "Sticker text"}
                        onChange={(e) => patchOverlay(index, { content: e.target.value })}
                        className={FIELD}
                      />
                      <button
                        type="button"
                        data-testid={"overlay-delete-" + index}
                        aria-label={t("stories.remove") || "Remove"}
                        onClick={() => removeOverlay(index)}
                        className="shrink-0 rounded-full p-1.5 text-ink-500 transition hover:bg-ink-100 dark:hover:bg-ink-800"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                    <div className="mt-2 flex flex-wrap items-center gap-2">
                      <select
                        data-testid={"overlay-font-" + index}
                        aria-label={t("stories.font_style") || "Font"}
                        className={SELECT}
                        value={overlay.fontStyle}
                        onChange={(e) =>
                          patchOverlay(index, { fontStyle: e.target.value as OverlayFontStyle })
                        }
                      >
                        {OVERLAY_FONT_STYLES.map((s) => (
                          <option key={s} value={s}>
                            {t("stories.font." + s) || s}
                          </option>
                        ))}
                      </select>
                      <select
                        data-testid={"overlay-bg-" + index}
                        aria-label={t("stories.sticker_background") || "Background"}
                        className={SELECT}
                        value={overlay.bgMode}
                        onChange={(e) =>
                          patchOverlay(index, { bgMode: e.target.value as OverlayBgMode })
                        }
                      >
                        {OVERLAY_BG_MODES.map((m) => (
                          <option key={m} value={m}>
                            {t("stories.bg_mode." + m) || m}
                          </option>
                        ))}
                      </select>
                      <select
                        data-testid={"overlay-scale-" + index}
                        aria-label={t("stories.sticker_size") || "Size"}
                        className={SELECT}
                        value={String(overlay.scale)}
                        onChange={(e) => patchOverlay(index, { scale: Number(e.target.value) })}
                      >
                        {OVERLAY_SCALE_STEPS.map((s) => (
                          <option key={s} value={String(s)}>
                            {s}x
                          </option>
                        ))}
                      </select>
                      <div className="flex flex-wrap gap-1">
                        {OVERLAY_COLORS.map((color, ci) => (
                          <button
                            key={color.hex}
                            type="button"
                            data-testid={"overlay-color-" + index + "-" + ci}
                            aria-label={t("stories.sticker_color") || "Colour"}
                            onClick={() => patchOverlay(index, { color: color.hex })}
                            className={
                              "h-5 w-5 rounded-full border border-line " +
                              color.swatch +
                              (overlay.color === color.hex ? " ring-2 ring-brand-deep" : "")
                            }
                          />
                        ))}
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            </SurfaceCard>

            {/* Stickers: mentions, link, poll XOR question, hashtags */}
            <SurfaceCard padding="md">
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  data-testid="open-mentions"
                  className={GHOST}
                  onClick={() => setPanel(panel === "mention" ? null : "mention")}
                >
                  <AtSign size={16} aria-hidden />
                  {t("stories.mention") || "Mention"}
                </button>
                <button
                  type="button"
                  data-testid="open-link"
                  className={GHOST}
                  onClick={() => {
                    setLinkOn(true);
                    setPanel(panel === "link" ? null : "link");
                  }}
                >
                  <Link2 size={16} aria-hidden />
                  {t("stories.link") || "Link"}
                </button>
                <button type="button" data-testid="open-poll" className={GHOST} onClick={openPoll}>
                  <BarChart3 size={16} aria-hidden />
                  {t("stories.poll") || "Poll"}
                </button>
                <button
                  type="button"
                  data-testid="open-question"
                  className={GHOST}
                  onClick={openQuestion}
                >
                  <MessageCircleQuestion size={16} aria-hidden />
                  {t("stories.question") || "Question"}
                </button>
                <button
                  type="button"
                  data-testid="open-hashtag"
                  className={GHOST}
                  onClick={() => setPanel(panel === "hashtag" ? null : "hashtag")}
                >
                  <Hash size={16} aria-hidden />
                  {t("stories.hashtag") || "Hashtag"}
                </button>
              </div>

              {panel === "mention" && (
                <div className="mt-3 space-y-2">
                  <input
                    data-testid="mention-search"
                    value={mentionQuery}
                    onChange={(e) => setMentionQuery(e.target.value)}
                    placeholder={t("stories.search_followings") || "Search people you follow"}
                    aria-label={t("stories.search_followings") || "Search people you follow"}
                    className={FIELD}
                  />
                  <p className="text-xs text-ink-500 dark:text-ink-400">
                    {mentions.length}/{MENTION_MAX_COUNT}
                  </p>
                  {isLoadingFollowings && (
                    <p className="text-xs text-ink-500">{t("stories.loading") || "Loading…"}</p>
                  )}
                  {/* Two different silences, and telling them apart is the
                      whole point of the hint: nobody followed yet, or nobody
                      matching what was typed. */}
                  {!isLoadingFollowings && followings.length === 0 && (
                    <p data-testid="mention-empty" className="text-xs text-ink-500 dark:text-ink-400">
                      {t("stories.mention_followings_only") ||
                        "You can only tag people you follow. Follow someone first."}
                    </p>
                  )}
                  {!isLoadingFollowings && followings.length > 0 && searchResults.length === 0 && (
                    <p data-testid="mention-no-match" className="text-xs text-ink-500 dark:text-ink-400">
                      {t("stories.mention_no_match") || "Nobody you follow matches that"}
                    </p>
                  )}
                  <ul className="space-y-1">
                    {searchResults.map((user: any) => (
                      <li key={user._id}>
                        <button
                          type="button"
                          data-testid={"mention-result-" + user._id}
                          disabled={
                            mentions.length >= MENTION_MAX_COUNT ||
                            mentions.some((m) => m.userId === user._id)
                          }
                          onClick={() => addMention(user)}
                          className={GHOST + " w-full justify-start"}
                        >
                          @{user.name}
                        </button>
                      </li>
                    ))}
                  </ul>
                  <ul className="flex flex-wrap gap-1.5">
                    {mentions.map((mention, index) => (
                      <li key={mention.id}>
                        <button
                          type="button"
                          data-testid={"mention-remove-" + index}
                          onClick={() => removeMention(index)}
                          className={GHOST}
                        >
                          @{mention.name}
                          <X size={12} aria-hidden />
                        </button>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {panel === "link" && (
                <div className="mt-3 space-y-2">
                  <input
                    data-testid="link-url"
                    type="url"
                    value={link.url}
                    onChange={(e) => setLink({ ...link, url: e.target.value })}
                    placeholder="https://example.com"
                    aria-label={t("stories.link_url") || "Link URL"}
                    className={FIELD}
                  />
                  {linkInvalid && (
                    <p data-testid="link-error" role="alert" className="text-xs text-red-600 dark:text-red-400">
                      {t("stories.link_invalid") || "Enter a full http:// or https:// address"}
                    </p>
                  )}
                  <input
                    data-testid="link-title"
                    value={link.title}
                    onChange={(e) => setLink({ ...link, title: e.target.value })}
                    placeholder={t("stories.link_title") || "Title"}
                    aria-label={t("stories.link_title") || "Title"}
                    className={FIELD}
                  />
                  <input
                    data-testid="link-display"
                    value={link.displayText}
                    maxLength={30}
                    onChange={(e) => setLink({ ...link, displayText: e.target.value })}
                    placeholder={t("stories.link_label") || "Sticker label"}
                    aria-label={t("stories.link_label") || "Sticker label"}
                    className={FIELD}
                  />
                  <button
                    type="button"
                    data-testid="remove-link"
                    className={GHOST}
                    onClick={() => {
                      setLinkOn(false);
                      setLink({ url: "", title: "", displayText: "" });
                      setPanel(null);
                    }}
                  >
                    <Trash2 size={16} aria-hidden />
                    {t("stories.remove") || "Remove"}
                  </button>
                </div>
              )}

              {panel === "poll" && poll && (
                <div className="mt-3 space-y-2">
                  <input
                    data-testid="poll-question"
                    value={poll.question}
                    onChange={(e) => {
                      setStickerError(null);
                      setPoll({ ...poll, question: e.target.value });
                    }}
                    placeholder={t("stories.poll_question") || "Ask something"}
                    aria-label={t("stories.poll_question") || "Ask something"}
                    className={FIELD}
                  />
                  {poll.options.map((option, index) => (
                    <div key={index} className="flex items-center gap-2">
                      <input
                        data-testid={"poll-option-" + index}
                        value={option}
                        onChange={(e) => {
                          const options = poll.options.slice();
                          options[index] = e.target.value;
                          setStickerError(null);
                          setPoll({ ...poll, options });
                        }}
                        aria-label={(t("stories.poll_option") || "Option") + " " + (index + 1)}
                        className={FIELD}
                      />
                      {poll.options.length > POLL_MIN_OPTIONS && (
                        <button
                          type="button"
                          data-testid={"poll-option-remove-" + index}
                          aria-label={t("stories.remove") || "Remove"}
                          onClick={() => {
                            setStickerError(null);
                            setPoll({ ...poll, options: poll.options.filter((_, i) => i !== index) });
                          }}
                          className="shrink-0 rounded-full p-1.5 text-ink-500 transition hover:bg-ink-100 dark:hover:bg-ink-800"
                        >
                          <X size={16} />
                        </button>
                      )}
                    </div>
                  ))}
                  <div className="flex flex-wrap items-center gap-2">
                    <button
                      type="button"
                      data-testid="poll-add-option"
                      className={GHOST}
                      disabled={poll.options.length >= POLL_MAX_OPTIONS}
                      onClick={() => {
                        if (poll.options.length >= POLL_MAX_OPTIONS) return;
                        setPoll({ ...poll, options: poll.options.concat([""]) });
                      }}
                    >
                      <Plus size={16} aria-hidden />
                      {t("stories.add_option") || "Add option"}
                    </button>
                    <label className="flex items-center gap-2 text-sm text-ink-700 dark:text-ink-200">
                      <input
                        type="checkbox"
                        checked={poll.isAnonymous}
                        onChange={(e) => setPoll({ ...poll, isAnonymous: e.target.checked })}
                      />
                      {t("stories.anonymous_voting") || "Anonymous voting"}
                    </label>
                    <button
                      type="button"
                      data-testid="remove-poll"
                      className={GHOST}
                      onClick={() => {
                        setPoll(null);
                        setStickerError(null);
                        setPanel(null);
                      }}
                    >
                      <Trash2 size={16} aria-hidden />
                      {t("stories.remove") || "Remove"}
                    </button>
                  </div>
                </div>
              )}

              {panel === "question" && questionBox && (
                <div className="mt-3 space-y-2">
                  <input
                    data-testid="question-prompt"
                    value={questionBox.prompt}
                    onChange={(e) => {
                      setStickerError(null);
                      setQuestionBox({ prompt: e.target.value });
                    }}
                    aria-label={t("stories.question_prompt") || "Question prompt"}
                    className={FIELD}
                  />
                  <button
                    type="button"
                    data-testid="remove-question"
                    className={GHOST}
                    onClick={() => {
                      setQuestionBox(null);
                      setStickerError(null);
                      setPanel(null);
                    }}
                  >
                    <Trash2 size={16} aria-hidden />
                    {t("stories.remove") || "Remove"}
                  </button>
                </div>
              )}

              {stickerError && (panel === "poll" || panel === "question") && (
                <p
                  data-testid="sticker-error"
                  role="alert"
                  className="mt-2 text-xs text-red-600 dark:text-red-400"
                >
                  {stickerError}
                </p>
              )}

              {panel === "hashtag" && (
                <div className="mt-3 space-y-2">
                  <div className="flex gap-2">
                    <input
                      data-testid="hashtag-input"
                      value={hashtagInput}
                      onChange={(e) => setHashtagInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          e.preventDefault();
                          addHashtag();
                        }
                      }}
                      placeholder="#hashtag"
                      aria-label={t("stories.hashtag") || "Hashtag"}
                      className={FIELD}
                    />
                    <button type="button" data-testid="add-hashtag" className={GHOST} onClick={addHashtag}>
                      <Plus size={16} aria-hidden />
                    </button>
                  </div>
                  <ul className="flex flex-wrap gap-1.5">
                    {hashtags.map((tag) => (
                      <li key={tag}>
                        <button
                          type="button"
                          className={GHOST}
                          onClick={() => setHashtags(hashtags.filter((h) => h !== tag))}
                        >
                          #{tag}
                          <X size={12} aria-hidden />
                        </button>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </SurfaceCard>

            {/* Privacy */}
            <SurfaceCard padding="md">
              {/* `stories.audience`, not `stories.privacy`: the latter is
                  already an OBJECT in this namespace (public / friends /
                  close_friends below), and i18next cannot hold a string and a
                  subtree at the same path. */}
              <label className={LABEL} htmlFor="story-privacy">
                {t("stories.audience") || "Who can see this"}
              </label>
              <select
                id="story-privacy"
                data-testid="privacy-select"
                className={FIELD + " mt-1"}
                value={privacy}
                onChange={(e) => setPrivacy(e.target.value as any)}
              >
                <option value="public">{t("stories.privacy.public") || "Everyone"}</option>
                <option value="friends">{t("stories.privacy.friends") || "Friends"}</option>
                <option value="close_friends">
                  {t("stories.privacy.close_friends") || "Close friends"}
                </option>
              </select>
              {privacy === "close_friends" && closeFriendsCount === 0 && (
                <p className="mt-2 text-xs text-ink-600 dark:text-ink-300">
                  {t("stories.close_friends_empty") ||
                    "Your close friends list is empty — nobody would see this story."}{" "}
                  <Link
                    data-testid="close-friends-hint"
                    to="/settings/close-friends"
                    className="font-semibold text-brand-deep underline"
                  >
                    {t("stories.manage_close_friends") || "Manage close friends"}
                  </Link>
                </p>
              )}
            </SurfaceCard>
          </div>
        )}
      </div>
    </div>
  );
};

export default CreateStory;
