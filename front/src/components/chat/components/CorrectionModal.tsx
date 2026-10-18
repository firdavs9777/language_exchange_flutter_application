import React, { useState } from 'react';
import { X, CheckCircle, AlertCircle } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import './CorrectionModal.scss';

interface Message {
  _id: string;
  content?: string;
  message?: string;
  sender?: {
    _id: string;
    name: string;
  };
}

interface CorrectionModalProps {
  message: Message;
  onSubmit: (data: {
    originalText: string;
    correctedText: string;
    explanation?: string;
  }) => void;
  onClose: () => void;
}

const CorrectionModal: React.FC<CorrectionModalProps> = ({
  message,
  onSubmit,
  onClose,
}) => {
  const { t } = useTranslation();
  const originalText = message.content || message.message || '';
  const [correctedText, setCorrectedText] = useState(originalText);
  const [explanation, setExplanation] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!correctedText.trim()) {
      setError(t('chatPage.correctionModal.empty') || 'Please provide a correction');
      return;
    }

    if (correctedText === originalText) {
      setError(
        t('chatPage.correctionModal.unchanged') || 'The correction should be different from the original'
      );
      return;
    }

    onSubmit({
      originalText,
      correctedText: correctedText.trim(),
      explanation: explanation.trim() || undefined,
    });
  };

  return (
    <div className="correction-modal-overlay" onClick={onClose}>
      <div className="correction-modal" onClick={(e) => e.stopPropagation()}>
        <header className="modal-header">
          <div className="header-title">
            <CheckCircle size={20} className="title-icon" />
            <h2>{t('chatPage.correctionModal.title') || 'Language Correction'}</h2>
          </div>
          <button
            type="button"
            className="close-btn"
            onClick={onClose}
            aria-label={t('chatPage.correctionModal.close') || 'Close'}
          >
            <X size={20} />
          </button>
        </header>

        <form onSubmit={handleSubmit}>
          <div className="form-section">
            <label>{t('chatPage.correctionModal.original') || 'Original Message'}</label>
            <div className="original-text">{originalText}</div>
          </div>

          <div className="form-section">
            <label htmlFor="corrected">{t('chatPage.correctionModal.yours') || 'Your Correction'}</label>
            <textarea
              id="corrected"
              value={correctedText}
              onChange={(e) => {
                setCorrectedText(e.target.value);
                setError('');
              }}
              placeholder={t('chatPage.correctionModal.yoursPlaceholder') || 'Type the corrected version...'}
              rows={3}
            />
          </div>

          <div className="form-section">
            <label htmlFor="explanation">
              {t('chatPage.correctionModal.explanation') || 'Explanation'}{' '}
              <span className="optional">{t('chatPage.correctionModal.optional') || '(optional)'}</span>
            </label>
            <textarea
              id="explanation"
              value={explanation}
              onChange={(e) => setExplanation(e.target.value)}
              placeholder={
                t('chatPage.correctionModal.explanationPlaceholder') || 'Explain why this correction is helpful...'
              }
              rows={2}
            />
            <span className="hint">
              {t('chatPage.correctionModal.hint') ||
                "e.g., \"Use 'went' instead of 'goed' - irregular past tense\""}
            </span>
          </div>

          {error && (
            <div className="error-message">
              <AlertCircle size={16} />
              {error}
            </div>
          )}

          <div className="modal-actions">
            <button type="button" className="cancel-btn" onClick={onClose}>
              {t('chatPage.correctionModal.cancel') || 'Cancel'}
            </button>
            <button type="submit" className="submit-btn">
              <CheckCircle size={18} />
              {t('chatPage.correctionModal.submit') || 'Send Correction'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CorrectionModal;
