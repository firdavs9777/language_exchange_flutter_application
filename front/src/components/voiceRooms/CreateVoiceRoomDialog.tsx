import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { useCreateVoiceRoomMutation, voiceRoomErrorText, CreateVoiceRoomBody } from "../../store/slices/voiceRoomsSlice";

export const VOICE_ROOM_CATEGORIES = ["casual", "language_practice", "topic", "qa"];

export interface CreateVoiceRoomForm {
  title: string;
  description: string;
  language: string;
  category: string;
  maxParticipants: number;
  /** <input type="datetime-local"> value, local time, or "" for "start now". */
  when: string;
}

/** The body the app sends (POST /voicerooms). A past start time means "now". */
export function buildCreateBody(form: CreateVoiceRoomForm): CreateVoiceRoomBody {
  const body: CreateVoiceRoomBody = {
    title: form.title.trim(),
    topic: "language_exchange",
    language: form.language.trim(),
    maxParticipants: Math.min(50, Math.max(2, Math.round(form.maxParticipants || 8))),
  };
  if (form.description.trim()) body.description = form.description.trim();
  if (VOICE_ROOM_CATEGORIES.indexOf(form.category) > -1) body.category = form.category;
  if (form.when) {
    const start = new Date(form.when);
    if (!isNaN(start.getTime()) && start.getTime() > Date.now()) body.scheduledFor = start.toISOString();
  }
  // Key order mirrors the app's request; tests compare with toEqual, which
  // ignores order anyway.
  return body;
}

interface Props {
  open: boolean;
  defaultLanguage: string;
  onClose(): void;
  onCreated(roomId: string): void;
}

const CreateVoiceRoomDialog: React.FC<Props> = ({ open, defaultLanguage, onClose, onCreated }) => {
  const { t } = useTranslation();
  const [createRoom, { isLoading }] = useCreateVoiceRoomMutation();
  const [form, setForm] = useState<CreateVoiceRoomForm>({
    title: "",
    description: "",
    language: defaultLanguage || "",
    category: "language_practice",
    maxParticipants: 8,
    when: "",
  });
  const [error, setError] = useState("");
  if (!open) return null;

  const set = (patch: Partial<CreateVoiceRoomForm>) => setForm((f) => Object.assign({}, f, patch));
  const valid = form.title.trim().length > 0 && form.title.trim().length <= 100 && form.language.trim().length > 0;

  const submit = async () => {
    if (!valid || isLoading) return;
    setError("");
    try {
      const res = await createRoom(buildCreateBody(form)).unwrap();
      const id = res && res.data && res.data._id;
      if (id) onCreated(String(id));
    } catch (err) {
      setError(voiceRoomErrorText(err, t));
    }
  };

  return (
    <div className="vr-dialog-backdrop" role="presentation">
      <div className="vr-dialog" role="dialog" aria-modal="true" data-testid="create-voice-room-dialog">
        <h2 className="vr-dialog__title">{t("voiceRooms.create.title") || "Start a voice room"}</h2>
        <label className="vr-field">
          <span>{t("voiceRooms.create.name") || "Room name"}</span>
          <input
            data-testid="create-voice-room-title"
            value={form.title}
            maxLength={100}
            onChange={(e) => set({ title: e.target.value })}
          />
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.description") || "What will you talk about? (optional)"}</span>
          <textarea value={form.description} maxLength={500} onChange={(e) => set({ description: e.target.value })} />
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.language") || "Language"}</span>
          <input
            data-testid="create-voice-room-language"
            value={form.language}
            onChange={(e) => set({ language: e.target.value })}
          />
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.category") || "Kind of room"}</span>
          <select
            data-testid="create-voice-room-category"
            value={form.category}
            onChange={(e) => set({ category: e.target.value })}
          >
            <option value="casual">{t("voiceRooms.category.casual") || "Casual chat"}</option>
            <option value="language_practice">{t("voiceRooms.category.language_practice") || "Language practice"}</option>
            <option value="topic">{t("voiceRooms.category.topic") || "Topic"}</option>
            <option value="qa">{t("voiceRooms.category.qa") || "Q&A"}</option>
          </select>
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.max") || "Up to how many people"}</span>
          <input
            data-testid="create-voice-room-max"
            type="number"
            min={2}
            max={50}
            value={form.maxParticipants}
            onChange={(e) => set({ maxParticipants: parseInt(e.target.value, 10) || 8 })}
          />
        </label>
        <label className="vr-field">
          <span>{t("voiceRooms.create.when") || "Start later (optional)"}</span>
          <input
            data-testid="create-voice-room-when"
            type="datetime-local"
            value={form.when}
            onChange={(e) => set({ when: e.target.value })}
          />
        </label>
        {error && (
          <p className="vr-error" role="alert" data-testid="create-voice-room-error">
            {error}
          </p>
        )}
        <div className="vr-dialog__actions">
          <button type="button" className="vr-btn vr-btn--ghost" onClick={onClose} disabled={isLoading}>
            {t("common.cancel") || "Cancel"}
          </button>
          <button
            type="button"
            className="vr-btn vr-btn--primary"
            data-testid="create-voice-room-submit"
            disabled={!valid || isLoading}
            onClick={submit}
          >
            {form.when ? t("voiceRooms.create.schedule") || "Schedule" : t("voiceRooms.create.start") || "Start room"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default CreateVoiceRoomDialog;
