import React, { useEffect, useState } from "react";
import { Globe, BookmarkPlus, Check, X } from "lucide-react";
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
        setError(
          e?.data?.message ||
            e?.data?.error ||
            "Failed to translate message"
        );
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
      setSaveError(e?.data?.message || "Failed to save phrase");
    }
  };

  return (
    <div className="translation-card">
      <div className="translation-header">
        <Globe size={14} />
        <span className="translation-label">
          Translation · {targetLanguage.toUpperCase()}
        </span>
        <button
          type="button"
          className="translation-close"
          onClick={onClose}
          aria-label="Close translation"
        >
          <X size={14} />
        </button>
      </div>

      {isTranslating && (
        <div className="translation-status">Translating…</div>
      )}

      {!isTranslating && error && (
        <div className="translation-error">{error}</div>
      )}

      {!isTranslating && !error && translation && (
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
                ? "Saved to study queue"
                : isSaving
                  ? "Saving…"
                  : "Save phrase"}
            </span>
          </button>
          {saveError && (
            <div className="translation-save-error">{saveError}</div>
          )}
        </>
      )}
    </div>
  );
};

export default TranslationCard;
