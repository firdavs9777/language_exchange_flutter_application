import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import {
  useCreateMomentMutation,
  useDeleteMomentMutation,
  useUploadMomentVideoMutation,
} from "../../store/slices/momentsSlice";
import { DEFAULT_VIDEO_CONFIG, useGetReelVideoConfigQuery } from "../../store/slices/reelsSlice";
import LanguageField from "../moments/fields/LanguageField";
import ReelPolicyGate from "./ReelPolicyGate";
import { checkReelFile, readVideoDuration, REEL_ACCEPT } from "./lib/videoChecks";
import { formatReelDuration, REEL_MAX_SECONDS } from "./lib/reelModel";
import "./Reels.scss";

const CAPTION_MAX = 2000;

function serverError(err: any): string {
  const d = err && err.data;
  const msg = d && (d.error || d.message);
  return typeof msg === "string" ? msg : "";
}

/**
 * /reels/new -- the app's reel composer (create_reel_flow.dart +
 * CreateMoment in isReel mode), minus the trim/filter editor (spec
 * non-goal): pick a video of at most 3 minutes, caption, language, post.
 */
const ReelCreatePage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { data: config } = useGetReelVideoConfigQuery(undefined);
  const [createMoment] = useCreateMomentMutation();
  const [uploadMomentVideo] = useUploadMomentVideoMutation();
  const [deleteMoment] = useDeleteMomentMutation();

  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string>("");
  const [caption, setCaption] = useState("");
  const [language, setLanguage] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    return () => {
      if (preview) {
        try {
          URL.revokeObjectURL(preview);
        } catch (e) {
          // ignore
        }
      }
    };
  }, [preview]);

  const tooLongText = (seconds?: number | null) =>
    t("reels.create.too_long", { duration: formatReelDuration(seconds || 0) || "" }) ||
    `Reels can be up to 3:00. This video is ${formatReelDuration(seconds || 0) || "longer"}.`;

  const onPick = async (picked: File | null) => {
    setError("");
    setFile(null);
    setPreview("");
    if (!picked) return;
    const verdict = checkReelFile(picked, config || DEFAULT_VIDEO_CONFIG);
    if (verdict === "type") {
      setError(t("reels.create.bad_type") || "This file type isn't supported. Use MP4, MOV or WebM.");
      return;
    }
    if (verdict === "size") {
      setError(t("reels.create.too_big") || "This video is too large to upload.");
      return;
    }
    const duration = await readVideoDuration(picked);
    if (duration !== null && duration > REEL_MAX_SECONDS) {
      setError(tooLongText(duration));
      return;
    }
    setFile(picked);
    setPreview(URL.createObjectURL(picked));
  };

  const post = async () => {
    if (!file || busy) return;
    setBusy(true);
    setError("");
    let momentId = "";
    try {
      // The app's reel body: public only (the feed serves public reels),
      // isReel a literal boolean, language only when chosen.
      const body: any = { description: caption.trim(), privacy: "public", category: "general" };
      if (language) body.language = language;
      body.isReel = true;
      const created: any = await createMoment(body).unwrap();
      momentId = created && created.data && created.data._id ? String(created.data._id) : "";
      if (!momentId) throw new Error("no id");
    } catch (err) {
      setBusy(false);
      setError(serverError(err) || t("reels.create.failed") || "Couldn't post your reel. Try again.");
      return;
    }
    try {
      const formData = new FormData();
      formData.append("video", file, file.name);
      await uploadMomentVideo({ momentId, formData }).unwrap();
    } catch (err) {
      // No empty reel left behind (P3-MOM-1's rule).
      Promise.resolve()
        .then(() => deleteMoment(momentId).unwrap())
        .catch(() => {});
      setBusy(false);
      const code = err && (err as any).data && (err as any).data.code;
      setError(
        code === "REEL_TOO_LONG"
          ? t("reels.create.server_too_long") || "Reels must be 3 minutes or shorter."
          : t("reels.create.upload_failed") || "The video didn't upload. Nothing was posted — try again."
      );
      return;
    }
    toast.success(t("reels.create.posted") || "Your reel is posted.");
    navigate(`/moment/${momentId}`);
  };

  return (
    <ReelPolicyGate onDeclined={() => navigate("/moments")}>
      <section className="reel-create" data-testid="reel-create">
        <h1 className="reels-title">{t("reels.create.title") || "New reel"}</h1>
        <p className="reel-create-hint">
          {t("reels.create.hint") || "A short language-learning video, up to 3 minutes. Vertical (9:16) looks best."}
        </p>

        <label className="reel-file-label">
          <span>{file ? t("reels.create.change_video") || "Choose another video" : t("reels.create.choose_video") || "Choose a video"}</span>
          <input
            type="file"
            accept={REEL_ACCEPT}
            data-testid="reel-file"
            className="reel-file-input"
            disabled={busy}
            onChange={(e) => onPick(e.target.files && e.target.files[0] ? e.target.files[0] : null)}
          />
        </label>

        {preview && (
          <video data-testid="reel-preview" className="reel-preview" src={preview} controls muted playsInline />
        )}

        <label htmlFor="reel-caption" className="reel-field-label">
          {t("reels.create.caption") || "Caption"}
        </label>
        <textarea
          id="reel-caption"
          data-testid="reel-caption"
          className="reel-caption-input"
          value={caption}
          maxLength={CAPTION_MAX}
          rows={3}
          disabled={busy}
          onChange={(e) => setCaption(e.target.value)}
          placeholder={t("reels.create.caption_placeholder") || "What are you practising?"}
        />

        <LanguageField id="reel-language" value={language} onChange={setLanguage} />

        {error && (
          <p className="reel-create-error" role="alert" data-testid="reel-create-error">
            {error}
          </p>
        )}

        <button type="button" className="reel-btn reel-btn-primary reel-post" data-testid="reel-post"
          disabled={!file || busy} onClick={post}>
          {busy ? t("reels.create.posting") || "Posting…" : t("reels.create.post") || "Post reel"}
        </button>
      </section>
    </ReelPolicyGate>
  );
};

export default ReelCreatePage;
