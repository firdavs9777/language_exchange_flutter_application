import React, { useEffect, useState } from "react";
import { Globe, BookmarkPlus, Check, X } from "lucide-react";
import { useTranslation } from "react-i18next";
import {
  useTranslateMessageMutation,
  useSaveMessageVocabularyMutation,
} from "../../../store/slices/chatSlice";
import "./TranslationCard.scss";

interface TranslationCardProps {
  messageId: string;
  originalText: string;
  targetLanguage: string;
  onClose: () => void;
}

const TranslationCard: React.FC<TranslationCardProps> = ({
  messageId,
  originalText,
  targetLanguage,
  onClose,
}) => {
  const { t } = useTranslation();
  const [translateMessage, { isLoading: isTranslating }] =
    useTranslateMessageMutation();
  const [saveMessageVocabulary, { isLoading: isSaving }] =
    useSaveMessageVocabularyMutation();

  const [translation, setTranslation] = useState<string>("");
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setError(null);
    setSaved(false);
    setSaveError(null);
    setTranslation("");

    (async () => {
      try {
        const res: any = await translateMessage({
          messageId,
          targetLanguage,
        }).unwrap();
        if (cancelled) return;
        const translatedText =
          res?.data?.translatedText || res?.translatedText || "";
        setTranslation(translatedText);
      } catch (e: any) {
        if (cancelled) return;
        // "" = no server text; the generic line is translated at render.
        setError(e?.data?.message || e?.data?.error || "");
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [messageId, targetLanguage, translateMessage]);

  const handleSave = async () => {
    if (!translation || saved || isSaving) return;
    setSaveError(null);
    try {
      await saveMessageVocabulary({
        messageId,
        word: originalText,
        translation,
        language: targetLanguage,
      }).unwrap();
      setSaved(true);
    } catch (e: any) {
      setSaveError(e?.data?.message || "");
    }
  };

  return (
    <div className="translation-card">
      <div className="translation-header">
        <Globe size={14} />
        <span className="translation-label">
          {t("chatPage.translation.label", { lang: targetLanguage.toUpperCase() }) ||
            `Translation · ${targetLanguage.toUpperCase()}`}
        </span>
        <button
          type="button"
          className="translation-close"
          onClick={onClose}
          aria-label={t("chatPage.translation.close") || "Close translation"}
        >
          <X size={14} />
        </button>
      </div>

      {isTranslating && (
        <div className="translation-status">
          {t("chatPage.translation.translating") || "Translating…"}
        </div>
      )}

      {!isTranslating && error !== null && (
        <div className="translation-error">
          {error || t("chatPage.translation.failed") || "Failed to translate message"}
        </div>
      )}

      {!isTranslating && error === null && translation && (
        <>
          <div className="translation-text">{translation}</div>
          <button
            type="button"
            className={`translation-save-btn ${saved ? "saved" : ""}`}
            onClick={handleSave}
            disabled={isSaving || saved}
          >
            {saved ? <Check size={14} /> : <BookmarkPlus size={14} />}
            <span>
              {saved
                ? t("chatPage.translation.saved") || "Saved to study queue"
                : isSaving
                  ? t("chatPage.translation.saving") || "Saving…"
                  : t("chatPage.translation.save") || "Save phrase"}
            </span>
          </button>
          {saveError !== null && (
            <div className="translation-save-error">
              {saveError || t("chatPage.translation.saveFailed") || "Failed to save phrase"}
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default TranslationCard;
