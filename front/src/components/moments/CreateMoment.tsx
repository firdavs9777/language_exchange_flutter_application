import React, {
  ChangeEvent,
  FormEvent,
  useEffect,
  useRef,
  useState,
} from "react";
import { useTranslation } from 'react-i18next';
import { useSelector } from "react-redux";
import { useLocation, useNavigate } from "react-router-dom";
import { Bounce, toast } from "react-toastify";
import { showDailyLimitToast } from "../vip/dailyLimit";
import {
  useCreateMomentMutation,
  useDeleteMomentMutation,
  useUploadMomentPhotosMutation,
  useUploadMomentVideoMutation,
  useUploadMomentAudioMutation,
} from "../../store/slices/momentsSlice";
import {
  Image as ImageIcon,
  Video as VideoIcon,
  Mic as MicIcon,
  Type as TypeIcon,
} from "lucide-react";
import GradientMomentCard from "./media/GradientMomentCard";
import BackgroundField from "./fields/BackgroundField";
import CategoryField, { categoryLabel } from "./fields/CategoryField";
import LanguageField from "./fields/LanguageField";
import MoodField, { moodEmoji, moodLabel } from "./fields/MoodField";
import PrivacyField, { privacyLabel, privacyOption } from "./fields/PrivacyField";
import TagsField from "./fields/TagsField";
import ScheduleField from "./fields/ScheduleField";
import { isFutureInput, localInputToIso } from "./lib/scheduling";
import { useMomentSchedulingEnabled } from "./lib/useMomentSchedulingEnabled";
import { useCurrentLocation } from "./fields/useCurrentLocation";
import VoiceNoteRecorder from "./media/VoiceNoteRecorder";
import ISO6391 from "iso-639-1";
import { audioUpload } from "../../utils/audioUpload";

import {
  FaArrowLeft,
  FaChevronDown,
  FaImage,
  FaMapMarkerAlt,
  FaSmile,
  FaTag,
  FaTimes,
} from "react-icons/fa";

interface Moment {
  success: string;
  data: {
    _id: string;
    title: string;
    description: string;
    user: string;
    comments: string[];
    likeCount: number;
    likedUsers: string[];
    slug: string;
    location: { location: string };
    images: string[];
    createdAt: string;
    updatedAt: string;
  };
}

interface LocationData {
  formattedAddress?: string;
  type: "Point";
  coordinates: [number, number]; // [lng, lat]
}

// Media types are mutually exclusive: image XOR video XOR audio XOR text/gradient.
type MediaMode = "photo" | "video" | "voice" | "text";

interface AudioNote {
  blob: Blob;
  dur: number;
  wf: number[];
}

// Prompt-of-the-day handoff: MainMoments navigates here with this router state
// when the user taps "Answer" on the prompt card.
interface PromptHandoff {
  promptText?: string;
  promptId?: string;
  promptLanguage?: string;
  promptEmoji?: string;
}

interface AnsweredPrompt {
  id?: string;
  text: string;
  emoji?: string;
}

const readPromptHandoff = (state: unknown): PromptHandoff | null =>
  state && typeof state === "object" ? (state as PromptHandoff) : null;

const promptFromHandoff = (handoff: PromptHandoff | null): AnsweredPrompt | null =>
  handoff && handoff.promptText
    ? { id: handoff.promptId, text: handoff.promptText, emoji: handoff.promptEmoji }
    : null;

// The prompt's language as the language select's value (an ISO 639-1 code),
// or null when it is missing or not one the select offers.
const promptLanguageCode = (handoff: PromptHandoff | null): string | null => {
  const code = handoff && handoff.promptLanguage ? handoff.promptLanguage.toLowerCase() : "";
  return code && ISO6391.validate(code) ? code : null;
};

const CreateMoment: React.FC = () => {
  const navigate = useNavigate();
  const routerLocation = useLocation();
  const [createMoment] = useCreateMomentMutation();
  const [uploadMomentPhotos] = useUploadMomentPhotosMutation();
  const [uploadMomentVideo] = useUploadMomentVideoMutation();
  const [uploadMomentAudio] = useUploadMomentAudioMutation();
  const [deleteMoment] = useDeleteMomentMutation();
  const { t } = useTranslation();

  // Read the prompt handoff during the first render, not in an effect, so the
  // textarea shows the prompt text on its very first paint.
  const initialHandoff = readPromptHandoff(routerLocation.state);

  // Basic form state
  const [description, setDescription] = useState<string>(
    () => (initialHandoff && initialHandoff.promptText) || ""
  );
  // The prompt being answered, shown as a dismissible chip. Dismissing it
  // keeps the text but drops promptId from the payload (the app's behaviour).
  const [answeredPrompt, setAnsweredPrompt] = useState<AnsweredPrompt | null>(
    () => promptFromHandoff(initialHandoff)
  );
  const [selectedImages, setSelectedImages] = useState<File[]>([]);
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [isButtonEnabled, setIsButtonEnabled] = useState<boolean>(false);

  // Media mode (mutually exclusive: photo / video / voice / text-gradient)
  const [mediaMode, setMediaMode] = useState<MediaMode>("photo");
  const [selectedVideo, setSelectedVideo] = useState<File | null>(null);
  const [videoPreview, setVideoPreview] = useState<string>("");
  const [audioNote, setAudioNote] = useState<AudioNote | null>(null);
  const [showRecorder, setShowRecorder] = useState<boolean>(false);
  const [backgroundColor, setBackgroundColor] = useState<string>(""); // "" = None (plain text)

  // Enhanced features state
  const [location, setLocation] = useState<LocationData | null>(null);
  const [mood, setMood] = useState<string>("");
  const [tags, setTags] = useState<string[]>([]);
  const [privacy, setPrivacy] = useState<string>("public");
  // Answering a prompt defaults the moment's language to the prompt's.
  const [language, setLanguage] = useState<string>(
    () => promptLanguageCode(initialHandoff) || "en"
  );
  const [category, setCategory] = useState<string>("general");
  const [scheduledFor, setScheduledFor] = useState<string>(""); // datetime-local; "" = now
  const schedulingEnabled = useMomentSchedulingEnabled();
  const scheduleBlocked = schedulingEnabled && Boolean(scheduledFor) && !isFutureInput(scheduledFor);

  // UI state
  const [showOptions, setShowOptions] = useState<boolean>(false);
  const [showMoodSelector, setShowMoodSelector] = useState<boolean>(false);
  const [showTagInput, setShowTagInput] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);
  const userInfo = useSelector((state: any) => state.auth.userInfo?.user);

  // A moment is a caption OR media (backend momentValidator + hasMomentContent).
  // Only the active mode's media counts; a text moment always needs words.
  const hasMedia =
    (mediaMode === "photo" && selectedImages.length > 0) ||
    (mediaMode === "video" && selectedVideo !== null) ||
    (mediaMode === "voice" && audioNote !== null);
  useEffect(() => {
    setIsButtonEnabled(description.trim() !== "" || hasMedia);
  }, [description, hasMedia]);

  // A later handoff while the composer is already mounted (e.g. Answer tapped
  // again from history). The first one was consumed by the state initialisers
  // above. Never clobber anything the user has already typed; the functional
  // update reads the live description rather than a stale closure.
  const firstLocationKey = useRef(routerLocation.key);
  useEffect(() => {
    if (routerLocation.key === firstLocationKey.current) return;
    const handoff = readPromptHandoff(routerLocation.state);
    const next = promptFromHandoff(handoff);
    if (!next) return;
    setAnsweredPrompt(next);
    setDescription((current) => (current.trim() === "" ? next.text : current));
    const code = promptLanguageCode(handoff);
    if (code) setLanguage(code);
  }, [routerLocation.key, routerLocation.state]);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${textareaRef.current.scrollHeight}px`;
    }
  }, [description]);

  const handleImageUpload = (event: ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    if (files.length + selectedImages.length > 10) {
      toast.error(t("createMoment.toast.maxImagesError") || "Maximum 10 images allowed", {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }
    setSelectedImages((prevImages) => [...prevImages, ...files]);

    const newPreviews = files.map((file) => URL.createObjectURL(file));
    setImagePreviews((prevPreviews) => [...prevPreviews, ...newPreviews]);
  };

  const handleRemoveImage = (index: number) => {
    setSelectedImages((prevImages) => prevImages.filter((_, i) => i !== index));
    setImagePreviews((prevPreviews) =>
      prevPreviews.filter((_, i) => i !== index)
    );
    URL.revokeObjectURL(imagePreviews[index]);
  };

  // Clear every kind of media so a mode switch enforces mutual exclusivity.
  const clearAllMedia = () => {
    imagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
    setSelectedImages([]);
    setImagePreviews([]);
    if (videoPreview) URL.revokeObjectURL(videoPreview);
    setSelectedVideo(null);
    setVideoPreview("");
    setAudioNote(null);
    setShowRecorder(false);
    setBackgroundColor("");
  };

  const handleSelectMode = (mode: MediaMode) => {
    if (mode === mediaMode) return;
    clearAllMedia();
    setMediaMode(mode);
  };

  const handleVideoUpload = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    if (videoPreview) URL.revokeObjectURL(videoPreview);
    setSelectedVideo(file);
    setVideoPreview(URL.createObjectURL(file));
    event.target.value = ""; // allow re-selecting the same file
  };

  const handleRemoveVideo = () => {
    if (videoPreview) URL.revokeObjectURL(videoPreview);
    setSelectedVideo(null);
    setVideoPreview("");
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!isButtonEnabled || isSubmitting || scheduleBlocked) return;

    setIsSubmitting(true);

    // Track whether the moment itself was created so a failed media upload
    // never re-creates it on retry (surfaces a "posted, edit to add media" toast).
    let momentCreated = false;

    try {
      const payload: any = {
        description,
        location,
        mood,
        tags,
        privacy,
        language,
        category,
      };
      // Only while the server enforces scheduling: otherwise it would post now.
      const scheduledIso = schedulingEnabled && scheduledFor ? localInputToIso(scheduledFor) : null;
      if (scheduledIso) payload.scheduledFor = scheduledIso;
      if (mediaMode === "text" && backgroundColor) payload.backgroundColor = backgroundColor;
      if (answeredPrompt && answeredPrompt.id) payload.promptId = answeredPrompt.id;

      const response = await createMoment(payload).unwrap();
      const newMoment = response as Moment;
      const momentId = newMoment.data._id;
      momentCreated = true;

      // Step 2: upload the attached media for the active mode. If this throws,
      // the moment already exists — warn instead of erroring and do NOT re-create.
      try {
        if (mediaMode === "photo" && selectedImages.length > 0 && momentId) {
          const formData = new FormData();
          selectedImages.forEach((file) => {
            formData.append("file", file);
          });
          await uploadMomentPhotos({
            momentId,
            imageFiles: formData,
          }).unwrap();
        } else if (mediaMode === "video" && selectedVideo && momentId) {
          const formData = new FormData();
          formData.append("video", selectedVideo);
          await uploadMomentVideo({ momentId, formData }).unwrap();
        } else if (mediaMode === "voice" && audioNote && momentId) {
          const formData = new FormData();
          const upload = audioUpload(audioNote.blob, "voice-note");
          formData.append("audio", upload.blob, upload.filename);
          formData.append("duration", String(audioNote.dur));
          formData.append("waveform", JSON.stringify(audioNote.wf));
          await uploadMomentAudio({ momentId, formData }).unwrap();
        }
      } catch (uploadError) {
        if (description.trim() === "") {
          // Nothing but the media made this a moment: without it the feed
          // would show an empty card. Take it back and let the user retry.
          try {
            await deleteMoment(momentId).unwrap();
          } catch (e) {
            // Best effort; the owner can still delete it from My moments.
          }
          toast.error(
            t("moments_section.create.mediaFailedNothingPosted") ||
              "The upload failed, so nothing was posted. Try again.",
            { autoClose: 4000, hideProgressBar: false, theme: "dark", transition: Bounce }
          );
          return;
        }
        toast.warn(
          t("moments_section.create.mediaFailedPosted") ||
            "Posted, but media upload failed — try editing the moment to add it.",
          { autoClose: 4000, hideProgressBar: false, theme: "dark", transition: Bounce }
        );
        navigate("/moments");
        return;
      }

      toast.success(t("createMoment.toast.createSuccess"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      navigate("/moments");
    } catch (error) {
      // Only the create step can reach here (upload failures are handled above).
      // The daily moment limit (429) gets the VIP upgrade toast instead.
      if (!momentCreated && !showDailyLimitToast(error)) {
        toast.error(t("createMoment.toast.createError"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const getCurrentLocation = useCurrentLocation(setLocation as any);
  const PrivacyIcon = privacyOption(privacy).Icon;

  useEffect(() => {
    return () => {
      imagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
    };
  }, [imagePreviews]);

  useEffect(() => {
    return () => {
      if (videoPreview) URL.revokeObjectURL(videoPreview);
    };
  }, [videoPreview]);

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <div className="bg-white shadow-sm border-b sticky top-0 z-50">
        <div className="max-w-2xl mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button
                onClick={() => navigate(-1)}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <FaArrowLeft className="w-5 h-5 text-gray-600" />
              </button>
              <h1 className="text-xl font-semibold text-gray-900">
                {t("moments_section.create.header") || "Create moment"}
              </h1>
            </div>
            <button
              onClick={handleSubmit}
              disabled={!isButtonEnabled || isSubmitting || scheduleBlocked}
              className={`px-6 py-2 rounded-full font-medium text-sm transition-all ${
                isButtonEnabled && !isSubmitting && !scheduleBlocked
                  ? 'bg-blue-500 hover:bg-blue-600 text-white'
                  : 'bg-gray-200 text-gray-400 cursor-not-allowed'
              }`}
            >
              {isSubmitting ? t("moments_section.create.sharing") || "Sharing..." : t("moments_section.create.share") || "Share"}
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-2xl mx-auto p-4">
        {/* User Info */}
        <div className="bg-white rounded-lg shadow-sm mb-4">
          <div className="p-4">
            <div className="flex items-center gap-3 mb-4">
              <img
                src={userInfo?.imageUrls?.[0] || "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face"}
                alt="Profile"
                className="w-10 h-10 rounded-full object-cover"
              />
              <div className="flex-1">
                <div className="font-medium text-gray-900">{userInfo?.name || "User"}</div>
                <button
                  onClick={() => setShowOptions(!showOptions)}
                  className="flex items-center gap-1 text-sm text-gray-600 hover:bg-gray-100 px-2 py-1 rounded transition-colors"
                >
                  <PrivacyIcon />
                  <span>{privacyLabel(t, privacy)}</span>
                  <FaChevronDown className="w-3 h-3" />
                </button>
              </div>
            </div>

            {/* Privacy Dropdown */}
            {showOptions && (
              <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                <PrivacyField value={privacy} onChange={setPrivacy} />
              </div>
            )}

            {/* Media mode selector — image XOR video XOR voice XOR text/gradient */}
            <div className="mb-4 grid grid-cols-4 gap-2">
              {[
                { mode: "photo" as MediaMode, icon: <ImageIcon className="w-5 h-5" />, label: t("moments_section.create.modePhoto") || "Photo" },
                { mode: "video" as MediaMode, icon: <VideoIcon className="w-5 h-5" />, label: t("moments_section.create.modeVideo") || "Video" },
                { mode: "voice" as MediaMode, icon: <MicIcon className="w-5 h-5" />, label: t("moments_section.create.modeVoice") || "Voice" },
                { mode: "text" as MediaMode, icon: <TypeIcon className="w-5 h-5" />, label: t("moments_section.create.modeText") || "Text" },
              ].map((option) => (
                <button
                  key={option.mode}
                  type="button"
                  onClick={() => handleSelectMode(option.mode)}
                  className={`flex flex-col items-center gap-1 rounded-lg border py-2 text-xs font-medium transition-colors ${
                    mediaMode === option.mode
                      ? "border-blue-500 bg-blue-50 text-blue-600 dark:bg-blue-900/30"
                      : "border-gray-200 text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
                  }`}
                >
                  {option.icon}
                  {option.label}
                </button>
              ))}
            </div>

            {/* Content Input */}
            <div className="w-full bg-white border border-gray-300 rounded-lg p-4 space-y-3">
              {/* Prompt of the day being answered (dismissible) */}
              {answeredPrompt && (
                <div className="flex">
                  <span
                    data-testid="create-moment-prompt-chip"
                    className="inline-flex max-w-full items-center gap-1.5 rounded-full border border-amber-300/60 bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700 dark:border-amber-600/40 dark:bg-amber-900/20 dark:text-amber-300"
                  >
                    <span aria-hidden="true">{answeredPrompt.emoji || "☀️"}</span>
                    <span className="truncate">
                      {t("moments_section.prompt.answeringPromptOfDay") || "Answering prompt of the day"}
                      {": "}
                      {answeredPrompt.text}
                    </span>
                    <button
                      type="button"
                      onClick={() => setAnsweredPrompt(null)}
                      aria-label={t("moments_section.prompt.dismissChip") || "Stop answering the prompt"}
                      className="ml-0.5 shrink-0 rounded-full p-0.5 hover:bg-amber-100 dark:hover:bg-amber-800/40"
                    >
                      <FaTimes className="w-3 h-3" />
                    </button>
                  </span>
                </div>
              )}

              {/* Main textarea */}
              <textarea
                ref={textareaRef}
                placeholder={t("moments_section.create.placeholder", { name: userInfo?.name?.split(" ")[0] || "" }) || `What's on your mind, ${userInfo?.name?.split(" ")[0] || "there"}?`}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full border-none outline-none resize-none text-lg placeholder-gray-500 min-h-[120px]"
                maxLength={2000}
              />

              {/* Character count */}
              <div className="text-right text-xs text-gray-400">
                {description.length}/2000
              </div>
            </div>

            {/* Image Previews */}
            {imagePreviews.length > 0 && (
              <div className="mt-4">
                <div className="grid grid-cols-2 gap-2">
                  {imagePreviews.map((preview, index) => (
                    <div key={index} className="relative group">
                      <img
                        src={preview}
                        alt={`Preview ${index + 1}`}
                        className="w-full h-48 object-cover rounded-lg"
                      />
                      <button
                        onClick={() => handleRemoveImage(index)}
                        className="absolute top-2 right-2 w-8 h-8 bg-black bg-opacity-50 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <FaTimes className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Video mode */}
            {mediaMode === "video" && (
              <div className="mt-4">
                {selectedVideo ? (
                  <div className="relative">
                    <video
                      src={videoPreview}
                      controls
                      className="w-full max-h-96 rounded-lg bg-black"
                    />
                    <button
                      type="button"
                      onClick={handleRemoveVideo}
                      className="absolute top-2 right-2 w-8 h-8 bg-black bg-opacity-50 text-white rounded-full flex items-center justify-center"
                    >
                      <FaTimes className="w-4 h-4" />
                    </button>
                    <div className="mt-1 text-xs text-gray-500 truncate">
                      {selectedVideo.name}
                    </div>
                  </div>
                ) : (
                  <button
                    type="button"
                    onClick={() => videoInputRef.current?.click()}
                    className="flex w-full items-center justify-center gap-2 rounded-lg border-2 border-dashed border-gray-300 py-8 text-sm text-gray-600 transition-colors hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
                  >
                    <VideoIcon className="w-5 h-5" />
                    {t("moments_section.create.attachVideo") || "Attach a video"}
                  </button>
                )}
              </div>
            )}

            {/* Voice mode */}
            {mediaMode === "voice" && (
              <div className="mt-4">
                {showRecorder ? (
                  <VoiceNoteRecorder
                    onComplete={(blob, dur, wf) => {
                      setAudioNote({ blob, dur, wf });
                      setShowRecorder(false);
                    }}
                    onCancel={() => setShowRecorder(false)}
                  />
                ) : audioNote ? (
                  <div className="flex items-center justify-between rounded-lg bg-gray-100 px-4 py-3 text-sm text-gray-700 dark:bg-gray-800 dark:text-gray-200">
                    <span className="flex items-center gap-2">
                      <MicIcon className="w-4 h-4" />
                      {t("moments_section.create.voiceNoteLength", { seconds: Math.round(audioNote.dur) }) || `Voice note · ${Math.round(audioNote.dur)}s`}
                    </span>
                    <button
                      type="button"
                      onClick={() => setAudioNote(null)}
                      className="text-red-500 hover:text-red-600"
                    >
                      {t("moments_section.create.remove") || "Remove"}
                    </button>
                  </div>
                ) : (
                  <button
                    type="button"
                    onClick={() => setShowRecorder(true)}
                    className="flex w-full items-center justify-center gap-2 rounded-lg border-2 border-dashed border-gray-300 py-8 text-sm text-gray-600 transition-colors hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
                  >
                    <MicIcon className="w-5 h-5" />
                    {t("moments_section.create.recordVoice") || "Record a voice note"}
                  </button>
                )}
              </div>
            )}

            {/* Text / gradient mode */}
            {mediaMode === "text" && (
              <div className="mt-4">
                <BackgroundField value={backgroundColor} onChange={setBackgroundColor} />
                {backgroundColor && (
                  <div className="mt-3">
                    <GradientMomentCard
                      text={description || t("moments_section.create.textPreview") || "Your text moment"}
                      backgroundColor={backgroundColor}
                    />
                  </div>
                )}
              </div>
            )}

            {/* Selected enhancements */}
            {(mood || location || category !== 'general' || language !== 'en') && (
              <div className="mt-4 flex flex-wrap gap-2">
                {mood && (
                  <span className="inline-flex items-center gap-1 px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm">
                    {moodEmoji(mood)} {moodLabel(t, mood)}
                    <button onClick={() => setMood("")} className="ml-1 hover:text-yellow-900">
                      <FaTimes className="w-3 h-3" />
                    </button>
                  </span>
                )}
                {location && (
                  <span className="inline-flex items-center gap-1 px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm">
                    📍 {location.formattedAddress}
                    <button onClick={() => setLocation(null)} className="ml-1 hover:text-green-900">
                      <FaTimes className="w-3 h-3" />
                    </button>
                  </span>
                )}
                {category !== 'general' && (
                  <span className="inline-flex items-center gap-1 px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm">
                    {categoryLabel(t, category)}
                  </span>
                )}
                {language !== 'en' && (
                  <span className="inline-flex items-center gap-1 px-3 py-1 bg-indigo-100 text-indigo-800 rounded-full text-sm">
                    🌐 {language}
                  </span>
                )}
              </div>
            )}
          </div>

          {/* Action Bar */}
          <div className="border-t p-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">
                {t("moments_section.create.addToMoment") || "Add to your moment"}
              </span>
              <div className="flex items-center gap-2 relative">
                {/* Photo Button (photo mode only) */}
                {mediaMode === "photo" && (
                  <button
                    onClick={() => fileInputRef.current?.click()}
                    className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                    title={t("moments_section.create.addPhotos") || "Add photos"}
                  >
                    <FaImage className="w-6 h-6 text-green-500" />
                  </button>
                )}

                {/* Mood Button */}
                <div className="relative">
                  <button
                    onClick={() => setShowMoodSelector(!showMoodSelector)}
                    className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                    title={t("moments_section.create.addMood") || "Add mood"}
                  >
                    <FaSmile className="w-6 h-6 text-yellow-500" />
                  </button>

                  {/* Mood Selector Dropdown */}
                  {showMoodSelector && (
                    <div className="absolute bottom-12 right-0 bg-white border rounded-lg shadow-lg p-3 z-50 min-w-48">
                      <div className="text-sm font-medium mb-2">{t("moments_section.create.moodQuestion") || "How are you feeling?"}</div>
                      <MoodField
                        value={mood}
                        onChange={(value) => {
                          setMood(value);
                          setShowMoodSelector(false);
                        }}
                      />
                    </div>
                  )}
                </div>

                {/* Location Button */}
                <button
                  onClick={getCurrentLocation}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                  title={t("moments_section.create.addLocation") || "Add location"}
                >
                  <FaMapMarkerAlt className="w-6 h-6 text-red-500" />
                </button>

                {/* Tag Button */}
                <button
                  onClick={() => setShowTagInput(!showTagInput)}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                  title={t("moments_section.create.addTags") || "Add tags"}
                >
                  <FaTag className="w-6 h-6 text-blue-500" />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Options */}
        <div className="bg-white rounded-lg shadow-sm p-4">
          <div className="grid grid-cols-2 gap-4">
            <CategoryField value={category} onChange={setCategory} />
            <LanguageField value={language} onChange={setLanguage} />
          </div>

          {/* Tag Input */}
          {(showTagInput || tags.length > 0) && (
            <div className="mt-4">
              <TagsField value={tags} onChange={setTags} />
            </div>
          )}

          {schedulingEnabled && (
            <div className="mt-4">
              <ScheduleField value={scheduledFor} onChange={setScheduledFor} />
            </div>
          )}
        </div>

        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept="image/*"
          onChange={handleImageUpload}
          className="hidden"
        />

        <input
          ref={videoInputRef}
          type="file"
          accept="video/*"
          onChange={handleVideoUpload}
          className="hidden"
        />
      </div>
    </div>
  );
};

export default CreateMoment;
