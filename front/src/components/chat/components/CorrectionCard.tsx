import React, { useState } from "react";
import { CheckCircle, BookCheck, Check } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useAcceptCorrectionMutation } from "../../../store/slices/learningSlice";
import "./CorrectionCard.scss";

export interface MessageCorrection {
  _id: string;
  corrector?: { _id: string; name: string };
  originalText: string;
  correctedText: string;
  explanation?: string;
  isAccepted?: boolean;
  createdAt?: string;
}

interface CorrectionCardProps {
  messageId: string;
  correction: MessageCorrection;
  isMe: boolean;
  currentUserId: string;
  otherUserName: string;
  onAccepted?: (correctionId: string) => void;
}

const CorrectionCard: React.FC<CorrectionCardProps> = ({
  messageId,
  correction,
  isMe,
  currentUserId,
  otherUserName,
  onAccepted,
}) => {
  const { t } = useTranslation();
  const [acceptCorrection, { isLoading }] = useAcceptCorrectionMutation();
  const [localAccepted, setLocalAccepted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const accepted = correction.isAccepted || localAccepted;
  const isCorrector = correction.corrector?._id === currentUserId;
  const canAccept = isMe && !isCorrector;
  const correctorName = isCorrector
    ? t("chatPage.correction.you") || "You"
    : correction.corrector?.name || otherUserName;

  const handleAccept = async () => {
    setError(null);
    try {
      await acceptCorrection({ messageId, correctionId: correction._id }).unwrap();
      setLocalAccepted(true);
      onAccepted?.(correction._id);
    } catch (e: any) {
      setError(e?.data?.message || t("chatPage.correction.acceptFailed") || "Failed to accept correction");
    }
  };

  return (
    <div className={`correction-card ${isMe ? "own" : "other"}`}>
      <div className="correction-header">
        <BookCheck size={14} />
        <span className="corrector-name">
          {t("chatPage.correction.corrected", { name: correctorName }) || `${correctorName} corrected`}
        </span>
        {accepted && <CheckCircle size={12} className="accepted-icon" />}
      </div>

      <div className="correction-diff">
        <div className="diff-original">{correction.originalText}</div>
        <div className="diff-corrected">{correction.correctedText}</div>
      </div>

      {correction.explanation && (
        <div className="correction-explanation">{correction.explanation}</div>
      )}

      {canAccept && !accepted && (
        <button
          className="correction-accept-btn"
          onClick={handleAccept}
          disabled={isLoading}
        >
          {isLoading ? (
            <span className="spinner" />
          ) : (
            <Check size={16} />
          )}
          <span>
            {isLoading
              ? t("chatPage.correction.accepting") || "Accepting…"
              : t("chatPage.correction.accept") || "Accept correction"}
          </span>
        </button>
      )}

      {canAccept && accepted && (
        <div className="correction-accepted-state">
          <CheckCircle size={14} />
          <span>
            {t("chatPage.correction.accepted") ||
              "Correction accepted — added to your learning record"}
          </span>
        </div>
      )}

      {error && <div className="correction-error">{error}</div>}
    </div>
  );
};

export default CorrectionCard;
