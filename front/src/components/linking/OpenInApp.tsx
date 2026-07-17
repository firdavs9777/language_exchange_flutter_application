import React from 'react';
import { useTranslation } from 'react-i18next';
import { ShareType } from '../../utils/shareUrl';
import { openInApp } from './openInAppAction';

interface Props {
  type: ShareType;
  id: string;
  className?: string;
  children?: React.ReactNode;
}

const OpenInApp: React.FC<Props> = ({ type, id, className, children }) => {
  const { t } = useTranslation();
  const handleClick = () => {
    openInApp({
      type,
      id,
      ua: navigator.userAgent,
      navigate: (url) => { window.location.href = url; },
      schedule: (fn, ms) => { window.setTimeout(fn, ms); },
      isVisible: () => document.visibilityState === 'visible',
    });
  };
  return (
    <button type="button" className={className} onClick={handleClick}>
      {children ?? t('linking.openInApp.label', 'Open in app')}
    </button>
  );
};

export default OpenInApp;
