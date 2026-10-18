import React, { useMemo, useState } from "react";
import ISO6391 from "iso-639-1";
import { useTranslation } from "react-i18next";
import { useCreateTopicRoomMutation, languageRoomErrorText } from "../../store/slices/languageRoomsSlice";
import { languageOptions } from "../moments/lib/languageOptions";

/** The signup picker stores English names ("Korean"); rooms take a code. */
export function toLanguageCode(value: string): string {
  const v = String(value || "").trim();
  if (!v) return "";
  if (ISO6391.validate(v.toLowerCase())) return v.toLowerCase();
  const code = ISO6391.getCode(v.replace(/\s*\([^)]*\)\s*$/, ""));
  return code || "";
}

interface Props {
  open: boolean;
  defaultLanguage: string;
  onClose(): void;
  onCreated(id: string): void;
}

const CreateTopicRoomDialog: React.FC<Props> = ({ open, defaultLanguage, onClose, onCreated }) => {
  const { t, i18n } = useTranslation();
  const locale = (i18n && i18n.language) || "en";
  const options = useMemo(() => languageOptions(locale), [locale]);
  const [create, { isLoading }] = useCreateTopicRoomMutation();
  const [title, setTitle] = useState("");
  const [language, setLanguage] = useState(toLanguageCode(defaultLanguage));
  const [description, setDescription] = useState("");
  const [error, setError] = useState("");
  if (!open) return null;
  const valid = title.trim().length > 0 && title.trim().length <= 60 && language.trim().length > 0;

  const submit = async () => {
    if (!valid || isLoading) return;
    setError("");
    try {
      const res = await create({ title: title.trim(), targetLanguage: language.trim(), description: description.trim() }).unwrap();
      const id = res && res.data && res.data._id;
      if (id) onCreated(String(id));
    } catch (err) {
      setError(languageRoomErrorText(err, t));
    }
  };

  return (
    <div className="vr-dialog-backdrop" role="presentation">
      <div className="vr-dialog" role="dialog" aria-modal="true" data-testid="create-topic-room-dialog">
        <h2 className="vr-dialog__title">{t("languageRooms.create.title") || "Start a topic room"}</h2>
        <label className="vr-field">
          <span>{t("languageRooms.create.name") || "Topic"}</span>
          <input data-testid="create-topic-room-title" value={title} maxLength={60} onChange={(e) => setTitle(e.target.value)} />
        </label>
        <label className="vr-field">
          <span>{t("languageRooms.create.language") || "Language"}</span>
          {/* The whole ISO 639-1 list, like the signup picker, named in the reader's language. */}
          <select data-testid="create-topic-room-language" value={language} onChange={(e) => setLanguage(e.target.value)}>
            <option value="">{t("languageRooms.create.pickLanguage") || "Choose a language"}</option>
            {options.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </label>
        <label className="vr-field">
          <span>{t("languageRooms.create.description") || "Description (optional)"}</span>
          <textarea data-testid="create-topic-room-description" value={description} maxLength={300} onChange={(e) => setDescription(e.target.value)} />
        </label>
        {error && (
          <p className="vr-error" role="alert" data-testid="create-topic-room-error">
            {error}
          </p>
        )}
        <div className="vr-dialog__actions">
          <button type="button" className="vr-btn vr-btn--ghost" onClick={onClose} disabled={isLoading}>
            {t("common.cancel") || "Cancel"}
          </button>
          <button type="button" className="vr-btn vr-btn--primary" data-testid="create-topic-room-submit" disabled={!valid || isLoading} onClick={submit}>
            {t("languageRooms.create.submit") || "Create room"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default CreateTopicRoomDialog;
