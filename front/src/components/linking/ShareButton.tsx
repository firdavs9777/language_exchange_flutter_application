import React from 'react';
import { toast } from 'react-toastify';
import { useTranslation } from 'react-i18next';
import { IoMdShare } from 'react-icons/io';
import { ShareType } from '../../utils/shareUrl';
import { shareContent } from './shareContent';

interface Props { type: ShareType; id: string; title: string; text?: string; className?: string; }

const ShareButton: React.FC<Props> = ({ type, id, title, text, className }) => {
  const { t } = useTranslation();

  const handleClick = () => {
    shareContent({
      type,
      id,
      title,
      text,
      nav: navigator,
      copiedMessage: t('linking.share.copied', 'Link copied to clipboard!'),
      copyFailedMessage: t('linking.share.copyFailed', 'Failed to copy link'),
      toast: (message, variant) =>
        variant === 'error' ? toast.error(message) : toast.success(message),
    }).catch(() => {
      // navigator.share() rejects (e.g. AbortError) when the user cancels the
      // native share sheet — nothing to report. Clipboard failures are
      // already surfaced via the toast callback inside shareContent.
    });
  };

  return (
    <button type="button" className={className} onClick={handleClick}>
      <IoMdShare className="me-1" aria-hidden="true" />
      {t('linking.share.label', 'Share')}
    </button>
  );
};

export default ShareButton;
