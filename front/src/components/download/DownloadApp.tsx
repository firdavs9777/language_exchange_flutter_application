import React, { useEffect } from "react";
import { useTranslation } from "react-i18next";
import "./DownloadApp.scss";

const APP_STORE_URL = "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";
const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.bananatalk.app";

const DownloadApp: React.FC = () => {
  const { t } = useTranslation();

  useEffect(() => {
    const ua = navigator.userAgent.toLowerCase();
    if (/iphone|ipad|ipod/.test(ua)) {
      window.location.href = APP_STORE_URL;
    } else if (/android/.test(ua)) {
      window.location.href = PLAY_STORE_URL;
    }
  }, []);

  return (
    <div className="download-page">
      <div className="download-page-inner">
        <div className="download-page-icon">B</div>
        <h1 className="download-page-title">BananaTalk</h1>
        <p className="download-page-desc">
          {t("home.download.description")}
        </p>

        <div className="download-page-buttons">
          <a href={APP_STORE_URL} target="_blank" rel="noopener noreferrer" className="download-page-btn apple">
            <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
            </svg>
            <div>
              <span className="btn-label">Download on the</span>
              <span className="btn-store">App Store</span>
            </div>
          </a>
          <a href={PLAY_STORE_URL} target="_blank" rel="noopener noreferrer" className="download-page-btn google">
            <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
              <path d="M3.18 23.77c-.35-.17-.57-.5-.6-.87L2.55 1.14c-.03-.37.14-.73.45-.93l9.55 11.25L3.18 23.77zm1.39.27l9.12-10.75 2.77 3.27-11.14 7.22c-.23.15-.49.23-.75.26zm12.88-8.44l-2.73-3.22 2.73-3.22 3.11 2.01c.72.47.72 1.23 0 1.69l-3.11 2.74zM4.57.03l11.14 7.22-2.77 3.27L3.81.77C4.04.35 4.3.14 4.57.03z"/>
            </svg>
            <div>
              <span className="btn-label">Get it on</span>
              <span className="btn-store">Google Play</span>
            </div>
          </a>
        </div>

        <p className="download-page-hint">
          On mobile? You'll be redirected automatically.
        </p>
      </div>
    </div>
  );
};

export default DownloadApp;
