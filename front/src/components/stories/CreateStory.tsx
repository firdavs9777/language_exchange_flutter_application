import React, { useState, useRef, useCallback, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import {
  FaTimes,
  FaCheck,
  FaTextHeight,
  FaPalette,
  FaPoll,
  FaQuestionCircle,
  FaMapMarkerAlt,
  FaAt,
  FaLink,
  FaMusic,
  FaHashtag,
  FaLock,
  FaUsers,
  FaGlobe,
  FaImage,
  FaVideo,
  FaFont,
} from "react-icons/fa";
import {
  useCreateStoryMutation,
} from "../../store/slices/storiesSlice";
import { toast } from "react-toastify";
import "./CreateStory.scss";

interface RootState {
  auth: {
    userInfo?: {
      user?: {
        _id: string;
        name: string;
        imageUrls?: string[];
      };
      data?: {
        _id: string;
        name: string;
        imageUrls?: string[];
      };
    };
  };
}

const CreateStory: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [step, setStep] = useState<"media" | "edit">("media");
  const [mediaFiles, setMediaFiles] = useState<File[]>([]);
  const [mediaPreviews, setMediaPreviews] = useState<string[]>([]);
  const [mediaType, setMediaType] = useState<"image" | "video" | "text">("image");
  const [currentMediaIndex, setCurrentMediaIndex] = useState(0);

  // Text story options
  const [text, setText] = useState("");
  const [backgroundColor, setBackgroundColor] = useState("#000000");
  const [textColor, setTextColor] = useState("#ffffff");
  const [fontStyle, setFontStyle] = useState<"normal" | "bold" | "italic" | "handwriting">("normal");

  // Privacy
  const [privacy, setPrivacy] = useState<"public" | "friends" | "close_friends">("public");
  const [showPrivacyMenu, setShowPrivacyMenu] = useState(false);

  // Stickers
  const [showStickers, setShowStickers] = useState(false);
  const [activeSticker, setActiveSticker] = useState<string | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);
  const privacyMenuRef = useRef<HTMLDivElement>(null);

  // Close privacy menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        privacyMenuRef.current &&
        !privacyMenuRef.current.contains(event.target as Node)
      ) {
        setShowPrivacyMenu(false);
      }
    };

    if (showPrivacyMenu) {
      document.addEventListener("mousedown", handleClickOutside);
    }

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [showPrivacyMenu]);

  // Poll
  const [poll, setPoll] = useState<{
    question: string;
    options: string[];
    isAnonymous: boolean;
  } | null>(null);

  // Question Box
  const [questionBox, setQuestionBox] = useState<{
    prompt: string;
  } | null>(null);

  // Location
  const [location, setLocation] = useState<{
    name: string;
    address: string;
    coordinates: { type: "Point"; coordinates: [number, number] };
  } | null>(null);

  // Link
  const [link, setLink] = useState<{
    url: string;
    title: string;
    displayText: string;
  } | null>(null);

  // Hashtags
  const [hashtags, setHashtags] = useState<string[]>([]);
  const [hashtagInput, setHashtagInput] = useState("");

  const [createStory, { isLoading: isCreating }] = useCreateStoryMutation();

  const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    const imageFiles = files.filter((f) => f.type.startsWith("image/"));
    const videoFiles = files.filter((f) => f.type.startsWith("video/"));

    if (imageFiles.length > 0) {
      setMediaType("image");
      setMediaFiles(imageFiles.slice(0, 5)); // Max 5 files
      const previews = imageFiles.slice(0, 5).map((file) => URL.createObjectURL(file));
      setMediaPreviews(previews);
      setStep("edit");
    } else if (videoFiles.length > 0) {
      setMediaType("video");
      setMediaFiles(videoFiles.slice(0, 1)); // Max 1 video
      const previews = videoFiles.slice(0, 1).map((file) => URL.createObjectURL(file));
      setMediaPreviews(previews);
      setStep("edit");
    }

    // Reset input
    if (fileInputRef.current) fileInputRef.current.value = "";
    if (videoInputRef.current) videoInputRef.current.value = "";
  }, []);

  const handleCreateTextStory = useCallback(() => {
    setMediaType("text");
    setStep("edit");
  }, []);

  const handleRemoveMedia = useCallback((index: number) => {
    setMediaFiles((prev) => prev.filter((_, i) => i !== index));
    setMediaPreviews((prev) => {
      URL.revokeObjectURL(prev[index]);
      return prev.filter((_, i) => i !== index);
    });
    if (currentMediaIndex >= mediaFiles.length - 1) {
      setCurrentMediaIndex(Math.max(0, mediaFiles.length - 2));
    }
  }, [currentMediaIndex, mediaFiles.length]);

  const handleAddPoll = useCallback(() => {
    setPoll({
      question: "",
      options: ["", ""],
      isAnonymous: false,
    });
    setActiveSticker("poll");
    setShowStickers(false);
  }, []);

  const handleAddQuestion = useCallback(() => {
    setQuestionBox({
      prompt: t("stories.question_box.ask_me_anything") || "Ask me anything!",
    });
    setActiveSticker("question");
    setShowStickers(false);
  }, [t]);

  const handleAddHashtag = useCallback(() => {
    const tag = hashtagInput.trim().replace("#", "");
    if (tag && !hashtags.includes(tag)) {
      setHashtags([...hashtags, tag]);
      setHashtagInput("");
    }
  }, [hashtagInput, hashtags]);

  const handleRemoveHashtag = useCallback((tag: string) => {
    setHashtags(hashtags.filter((t) => t !== tag));
  }, [hashtags]);

  const handleSubmit = useCallback(async () => {
    if (mediaType === "text" && !text.trim()) {
      toast.error(t("stories.media.add_text") || "Please add text to your story");
      return;
    }

    if (mediaType !== "text" && mediaFiles.length === 0) {
      toast.error(t("stories.media.upload_media") || "Please upload media");
      return;
    }

    try {
      const formData = new FormData();

      // Add media files
      if (mediaType !== "text") {
        mediaFiles.forEach((file) => {
          formData.append("media", file);
        });
      }

      // Add text story data
      if (mediaType === "text") {
        formData.append("text", text);
        formData.append("backgroundColor", backgroundColor);
        formData.append("textColor", textColor);
        formData.append("fontStyle", fontStyle);
      }

      // Add privacy
      formData.append("privacy", privacy);

      // Add poll
      if (poll && poll.question && poll.options.filter((o) => o.trim()).length >= 2) {
        formData.append("poll", JSON.stringify({
          question: poll.question,
          options: poll.options.filter((o) => o.trim()),
          isAnonymous: poll.isAnonymous,
        }));
      }

      // Add question box
      if (questionBox && questionBox.prompt) {
        formData.append("questionBox", JSON.stringify(questionBox));
      }

      // Add location
      if (location) {
        formData.append("location", JSON.stringify(location));
      }

      // Add link
      if (link && link.url) {
        formData.append("link", JSON.stringify(link));
      }

      // Add hashtags
      if (hashtags.length > 0) {
        formData.append("hashtags", JSON.stringify(hashtags));
      }

      await createStory(formData).unwrap();
      toast.success(t("stories.create_first_story") || "Story created successfully!");
      navigate("/moments");
    } catch (error: any) {
      toast.error(error?.data?.error || t("stories.error_loading") || "Failed to create story");
    }
  }, [
    mediaType,
    text,
    backgroundColor,
    textColor,
    fontStyle,
    mediaFiles,
    privacy,
    poll,
    questionBox,
    location,
    link,
    hashtags,
    createStory,
    navigate,
    t,
  ]);

  const handleClose = useCallback(() => {
    // Clean up preview URLs
    mediaPreviews.forEach((url) => URL.revokeObjectURL(url));
    navigate("/moments");
  }, [mediaPreviews, navigate]);

  const backgroundColors = [
    "#000000", "#ffffff", "#ff0000", "#00ff00", "#0000ff",
    "#ffff00", "#ff00ff", "#00ffff", "#ffa500", "#800080",
    "#ffc0cb", "#a52a2a", "#808080", "#008000", "#000080",
  ];

  const textColors = [
    "#ffffff", "#000000", "#ff0000", "#00ff00", "#0000ff",
    "#ffff00", "#ff00ff", "#00ffff", "#ffa500", "#800080",
  ];

  return (
    <div className="create-story-page">
      <div className="create-story-container">
        {/* Header */}
        <div className="create-story-header">
          <button className="close-btn" onClick={handleClose}>
            <FaTimes />
          </button>
          <h2>{t("stories.create_first_story") || "Create Story"}</h2>
          {step === "edit" && (
            <button
              className="share-btn"
              onClick={handleSubmit}
              disabled={isCreating}
            >
              {isCreating ? (
                <span>{t("stories.sharing.share_to_story") || "Sharing..."}</span>
              ) : (
                <>
                  <FaCheck /> {t("stories.share_story") || "Share"}
                </>
              )}
            </button>
          )}
        </div>

        {/* Content */}
        <div className="create-story-content">
          {step === "media" ? (
            <div className="media-selection">
              <div className="selection-options">
                <button
                  className="selection-btn"
                  onClick={() => fileInputRef.current?.click()}
                >
                  <FaImage />
                  <span>{t("stories.media.choose_from_gallery") || "Choose from Gallery"}</span>
                </button>
                <button
                  className="selection-btn"
                  onClick={() => videoInputRef.current?.click()}
                >
                  <FaVideo />
                  <span>{t("stories.media.take_photo") || "Take Photo/Video"}</span>
                </button>
                <button className="selection-btn" onClick={handleCreateTextStory}>
                  <FaFont />
                  <span>{t("stories.media.add_text") || "Create Text Story"}</span>
                </button>
              </div>

              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                multiple
                onChange={handleFileSelect}
                style={{ display: "none" }}
              />
              <input
                ref={videoInputRef}
                type="file"
                accept="video/*"
                onChange={handleFileSelect}
                style={{ display: "none" }}
              />
            </div>
          ) : (
            <div className="story-editor">
              {/* Media Preview */}
              {mediaType !== "text" && mediaPreviews.length > 0 && (
                <div className="media-preview-container">
                  {mediaPreviews.length > 1 && (
                    <div className="media-indicators">
                      {mediaPreviews.map((_, index) => (
                        <button
                          key={index}
                          className={`indicator ${index === currentMediaIndex ? "active" : ""}`}
                          onClick={() => setCurrentMediaIndex(index)}
                        />
                      ))}
                    </div>
                  )}

                  <div className="media-preview">
                    {mediaType === "image" ? (
                      <img
                        src={mediaPreviews[currentMediaIndex]}
                        alt="Story preview"
                      />
                    ) : (
                      <video src={mediaPreviews[currentMediaIndex]} controls />
                    )}

                    {mediaPreviews.length > 1 && (
                      <button
                        className="remove-media-btn"
                        onClick={() => handleRemoveMedia(currentMediaIndex)}
                      >
                        <FaTimes />
                      </button>
                    )}
                  </div>
                </div>
              )}

              {/* Text Story Editor */}
              {mediaType === "text" && (
                <div
                  className="text-story-preview"
                  style={{
                    backgroundColor,
                    color: textColor,
                    fontFamily:
                      fontStyle === "handwriting"
                        ? "'Kalam', cursive"
                        : "inherit",
                    fontWeight: fontStyle === "bold" ? "bold" : "normal",
                    fontStyle: fontStyle === "italic" ? "italic" : "normal",
                  }}
                >
                  <textarea
                    value={text}
                    onChange={(e) => setText(e.target.value)}
                    placeholder={t("stories.media.add_text") || "Type your story..."}
                    className="text-story-input"
                    style={{ color: textColor }}
                    maxLength={2200}
                  />
                  <div className="text-story-controls">
                    <div className="color-picker-group">
                      <label>
                        <FaPalette /> {t("stories.media.background_color") || "Background"}
                      </label>
                      <div className="color-grid">
                        {backgroundColors.map((color) => (
                          <button
                            key={color}
                            className={`color-option ${backgroundColor === color ? "active" : ""}`}
                            style={{ backgroundColor: color }}
                            onClick={() => setBackgroundColor(color)}
                          />
                        ))}
                      </div>
                    </div>
                    <div className="color-picker-group">
                      <label>
                        <FaTextHeight /> {t("stories.media.text_color") || "Text"}
                      </label>
                      <div className="color-grid">
                        {textColors.map((color) => (
                          <button
                            key={color}
                            className={`color-option ${textColor === color ? "active" : ""}`}
                            style={{ backgroundColor: color }}
                            onClick={() => setTextColor(color)}
                          />
                        ))}
                      </div>
                    </div>
                    <div className="font-style-group">
                      <label>{t("stories.media.font_style") || "Font Style"}</label>
                      <div className="font-buttons">
                        {(["normal", "bold", "italic", "handwriting"] as const).map((style) => (
                          <button
                            key={style}
                            className={`font-btn ${fontStyle === style ? "active" : ""}`}
                            onClick={() => setFontStyle(style)}
                          >
                            {style.charAt(0).toUpperCase() + style.slice(1)}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Editor Tools */}
              <div className="editor-tools">
                {/* Stickers */}
                <button
                  className={`tool-btn ${showStickers ? "active" : ""}`}
                  onClick={() => setShowStickers(!showStickers)}
                >
                  <FaHashtag />
                  <span>{t("stories.stickers.hashtag") || "Stickers"}</span>
                </button>

                {/* Privacy */}
                <div className="privacy-selector" ref={privacyMenuRef}>
                  <button
                    className="tool-btn"
                    onClick={() => setShowPrivacyMenu(!showPrivacyMenu)}
                  >
                    {privacy === "public" && <FaGlobe />}
                    {privacy === "friends" && <FaUsers />}
                    {privacy === "close_friends" && <FaLock />}
                    <span>{t(`stories.privacy.${privacy}`) || privacy}</span>
                  </button>
                  {showPrivacyMenu && (
                    <div className="privacy-menu">
                      {(["public", "friends", "close_friends"] as const).map((p) => (
                        <button
                          key={p}
                          className={privacy === p ? "active" : ""}
                          onClick={() => {
                            setPrivacy(p);
                            setShowPrivacyMenu(false);
                          }}
                        >
                          {p === "public" && <FaGlobe />}
                          {p === "friends" && <FaUsers />}
                          {p === "close_friends" && <FaLock />}
                          {t(`stories.privacy.${p}`) || p}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* Stickers Panel */}
              {showStickers && (
                <div className="stickers-panel">
                  <div className="sticker-options">
                    <button
                      className={`sticker-option ${activeSticker === "poll" ? "active" : ""}`}
                      onClick={handleAddPoll}
                    >
                      <FaPoll />
                      <span>{t("stories.stickers.poll") || "Poll"}</span>
                    </button>
                    <button
                      className={`sticker-option ${activeSticker === "question" ? "active" : ""}`}
                      onClick={handleAddQuestion}
                    >
                      <FaQuestionCircle />
                      <span>{t("stories.stickers.question") || "Question"}</span>
                    </button>
                    <button
                      className={`sticker-option ${activeSticker === "hashtag" ? "active" : ""}`}
                      onClick={() => setActiveSticker("hashtag")}
                    >
                      <FaHashtag />
                      <span>{t("stories.stickers.hashtag") || "Hashtag"}</span>
                    </button>
                  </div>

                  {/* Poll Editor */}
                  {activeSticker === "poll" && poll && (
                    <div className="sticker-editor">
                      <h4>{t("stories.poll.question") || "Create Poll"}</h4>
                      <input
                        type="text"
                        placeholder={t("stories.poll.question") || "Question"}
                        value={poll.question}
                        onChange={(e) =>
                          setPoll({ ...poll, question: e.target.value })
                        }
                      />
                      {poll.options.map((option, index) => (
                        <input
                          key={index}
                          type="text"
                          placeholder={`${t("stories.poll.options") || "Option"} ${index + 1}`}
                          value={option}
                          onChange={(e) => {
                            const newOptions = [...poll.options];
                            newOptions[index] = e.target.value;
                            setPoll({ ...poll, options: newOptions });
                          }}
                        />
                      ))}
                      <button
                        onClick={() =>
                          setPoll({
                            ...poll,
                            options: [...poll.options, ""],
                          })
                        }
                      >
                        {t("stories.poll.add_option") || "Add Option"}
                      </button>
                      <label>
                        <input
                          type="checkbox"
                          checked={poll.isAnonymous}
                          onChange={(e) =>
                            setPoll({ ...poll, isAnonymous: e.target.checked })
                          }
                        />
                        {t("stories.poll.anonymous_voting") || "Anonymous Voting"}
                      </label>
                      <button onClick={() => setPoll(null)}>
                        <FaTimes /> {t("stories.close") || "Remove"}
                      </button>
                    </div>
                  )}

                  {/* Question Editor */}
                  {activeSticker === "question" && questionBox && (
                    <div className="sticker-editor">
                      <h4>{t("stories.question_box.prompt") || "Question Box"}</h4>
                      <input
                        type="text"
                        placeholder={t("stories.question_box.ask_me_anything") || "Ask me anything!"}
                        value={questionBox.prompt}
                        onChange={(e) =>
                          setQuestionBox({ ...questionBox, prompt: e.target.value })
                        }
                      />
                      <button onClick={() => setQuestionBox(null)}>
                        <FaTimes /> {t("stories.close") || "Remove"}
                      </button>
                    </div>
                  )}

                  {/* Hashtag Editor */}
                  {activeSticker === "hashtag" && (
                    <div className="sticker-editor">
                      <h4>{t("stories.stickers.hashtag") || "Hashtags"}</h4>
                      <div className="hashtag-input-group">
                        <input
                          type="text"
                          placeholder="#hashtag"
                          value={hashtagInput}
                          onChange={(e) => setHashtagInput(e.target.value)}
                          onKeyPress={(e) => {
                            if (e.key === "Enter") {
                              e.preventDefault();
                              handleAddHashtag();
                            }
                          }}
                        />
                        <button onClick={handleAddHashtag}>
                          {t("stories.stickers.hashtag") || "Add"}
                        </button>
                      </div>
                      <div className="hashtags-list">
                        {hashtags.map((tag) => (
                          <span key={tag} className="hashtag-tag">
                            #{tag}
                            <button onClick={() => handleRemoveHashtag(tag)}>
                              <FaTimes />
                            </button>
                          </span>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Location Editor */}
                  {activeSticker === "location" && location && (
                    <div className="sticker-editor">
                      <h4>{t("stories.stickers.location") || "Location"}</h4>
                      <input
                        type="text"
                        placeholder={t("stories.stickers.location") || "Location name"}
                        value={location.name}
                        onChange={(e) =>
                          setLocation({ ...location, name: e.target.value })
                        }
                      />
                      <input
                        type="text"
                        placeholder={t("stories.stickers.location") || "Address"}
                        value={location.address}
                        onChange={(e) =>
                          setLocation({ ...location, address: e.target.value })
                        }
                      />
                      <button onClick={() => setLocation(null)}>
                        <FaTimes /> {t("stories.close") || "Remove"}
                      </button>
                    </div>
                  )}

                  {/* Link Editor */}
                  {activeSticker === "link" && link && (
                    <div className="sticker-editor">
                      <h4>{t("stories.stickers.link") || "Link"}</h4>
                      <input
                        type="url"
                        placeholder="https://example.com"
                        value={link.url}
                        onChange={(e) =>
                          setLink({ ...link, url: e.target.value })
                        }
                      />
                      <input
                        type="text"
                        placeholder={t("stories.stickers.link") || "Title"}
                        value={link.title}
                        onChange={(e) =>
                          setLink({ ...link, title: e.target.value })
                        }
                      />
                      <input
                        type="text"
                        placeholder={t("stories.sharing.share_externally") || "Display Text"}
                        value={link.displayText}
                        onChange={(e) =>
                          setLink({ ...link, displayText: e.target.value })
                        }
                      />
                      <button onClick={() => setLink(null)}>
                        <FaTimes /> {t("stories.close") || "Remove"}
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default CreateStory;

