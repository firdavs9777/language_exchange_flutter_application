import React, { useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import ConfirmDialog from "../../../design/ConfirmDialog";
import notify from "../../../design/notify";
import {
  useDeleteMomentAudioMutation,
  useDeleteMomentVideoMutation,
  useUploadMomentAudioMutation,
  useUploadMomentVideoMutation,
} from "../../../store/slices/momentsSlice";
import MomentVideoPlayer from "../media/MomentVideoPlayer";
import VoiceNotePlayer from "../media/VoiceNotePlayer";
import VoiceNoteRecorder from "../media/VoiceNoteRecorder";
import { audioUpload } from "../../../utils/audioUpload";

interface Props {
  moment: any;
}

const BUTTON =
  "rounded-chip border border-line px-3 py-1.5 text-sm font-semibold text-ink-700 transition-colors hover:bg-ink-100 disabled:opacity-50 dark:border-line-dark dark:text-ink-200";

/**
 * The editor's video / voice-note section: replace through the existing PUT
 * upload endpoints, remove through DELETE /:id/video or /:id/audio, behind a
 * confirm. A moment carries one kind of media, so image and text moments get
 * nothing here.
 */
const MediaEditor: React.FC<Props> = ({ moment }) => {
  const { t } = useTranslation();
  const tr = (key: string, fallback: string) => t(key) || fallback;
  const [uploadVideo, { isLoading: uploadingVideo }] = useUploadMomentVideoMutation();
  const [deleteVideo, { isLoading: deletingVideo }] = useDeleteMomentVideoMutation();
  const [uploadAudio, { isLoading: uploadingAudio }] = useUploadMomentAudioMutation();
  const [deleteAudio, { isLoading: deletingAudio }] = useDeleteMomentAudioMutation();
  const [confirming, setConfirming] = useState(false);
  const [recording, setRecording] = useState(false);
  const [error, setError] = useState("");
  const videoInput = useRef<HTMLInputElement>(null);

  const kind = moment && moment.mediaType === "video" && moment.video && moment.video.url
    ? "video"
    : moment && moment.mediaType === "audio" && moment.audio && moment.audio.url
    ? "audio"
    : null;
  if (!kind) return null;

  const busy = uploadingVideo || deletingVideo || uploadingAudio || deletingAudio;
  const failed = () => notify.error(tr("editMoment.media.failed", "That didn't work. Try again."));
  const done = () => notify.success(tr("editMoment.media.done", "Updated"));

  const replaceVideo = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files && event.target.files[0];
    event.target.value = "";
    if (!file) return;
    const formData = new FormData();
    formData.append("video", file);
    try {
      await uploadVideo({ momentId: moment._id, formData }).unwrap();
      done();
    } catch (e) {
      failed();
    }
  };

  const replaceAudio = async (blob: Blob, durationSec: number, waveform: number[]) => {
    setRecording(false);
    const formData = new FormData();
    const upload = audioUpload(blob, "voice-note");
    formData.append("audio", upload.blob, upload.filename);
    formData.append("duration", String(durationSec));
    formData.append("waveform", JSON.stringify(waveform));
    try {
      await uploadAudio({ momentId: moment._id, formData }).unwrap();
      done();
    } catch (e) {
      failed();
    }
  };

  const remove = async () => {
    setError("");
    try {
      await (kind === "video" ? deleteVideo(moment._id) : deleteAudio(moment._id)).unwrap();
      setConfirming(false);
      done();
    } catch (e) {
      setError(tr("editMoment.media.failed", "That didn't work. Try again."));
    }
  };

  return (
    <div data-testid="media-editor" className="space-y-3">
      <h2 className="block pb-1 text-xs font-semibold uppercase tracking-wide text-ink-500 dark:text-ink-400">
        {kind === "video" ? tr("editMoment.media.video", "Video") : tr("editMoment.media.audio", "Voice note")}
      </h2>
      {kind === "video" ? <MomentVideoPlayer video={moment.video} /> : <VoiceNotePlayer audio={moment.audio} />}
      {recording && <VoiceNoteRecorder onComplete={replaceAudio} onCancel={() => setRecording(false)} />}
      <div className="flex gap-2">
        <button
          type="button"
          className={BUTTON}
          disabled={busy}
          onClick={() => (kind === "video" ? videoInput.current && videoInput.current.click() : setRecording(true))}
        >
          {tr("editMoment.media.replace", "Replace")}
        </button>
        <button type="button" className={BUTTON} disabled={busy} onClick={() => setConfirming(true)}>
          {tr("editMoment.media.remove", "Remove")}
        </button>
      </div>
      <input
        ref={videoInput}
        data-testid="replace-video-input"
        type="file"
        accept="video/*"
        className="hidden"
        onChange={replaceVideo}
      />
      <ConfirmDialog
        open={confirming}
        title={
          kind === "video"
            ? tr("editMoment.media.removeVideoTitle", "Remove the video?")
            : tr("editMoment.media.removeAudioTitle", "Remove the voice note?")
        }
        body={tr("editMoment.media.removeBody", "This can't be undone.")}
        confirmLabel={tr("editMoment.media.remove", "Remove")}
        cancelLabel={tr("editMoment.form.cancelButton", "Cancel")}
        danger
        busy={deletingVideo || deletingAudio}
        error={error || undefined}
        onConfirm={remove}
        onCancel={() => {
          setError("");
          setConfirming(false);
        }}
      />
    </div>
  );
};

export default MediaEditor;
