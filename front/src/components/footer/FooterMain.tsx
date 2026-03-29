import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import "./FooterMain.scss";

const APP_STORE_URL = "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";
const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.bananatalk.app";

const FooterMain: React.FC = () => {
  const { t } = useTranslation();

  return (
    <footer className="footer-modern">
      <div className="footer-container">
        {/* Top Section */}
        <div className="footer-top">
          {/* Brand */}
          <div className="footer-brand">
            <Link to="/" className="footer-logo">
              <span className="footer-logo-icon">B</span>
              <span className="footer-logo-text">BananaTalk</span>
            </Link>
            <p className="footer-tagline">
              {t("footer.aboutDescription")}
            </p>
            <div className="footer-social">
              <a href="https://instagram.com" target="_blank" rel="noopener noreferrer" aria-label="Instagram">
                <i className="bi bi-instagram"></i>
              </a>
              <a href="https://twitter.com" target="_blank" rel="noopener noreferrer" aria-label="Twitter">
                <i className="bi bi-twitter-x"></i>
              </a>
              <a href="https://facebook.com" target="_blank" rel="noopener noreferrer" aria-label="Facebook">
                <i className="bi bi-facebook"></i>
              </a>
              <a href="https://linkedin.com" target="_blank" rel="noopener noreferrer" aria-label="LinkedIn">
                <i className="bi bi-linkedin"></i>
              </a>
              <a href="https://youtube.com" target="_blank" rel="noopener noreferrer" aria-label="YouTube">
                <i className="bi bi-youtube"></i>
              </a>
            </div>
          </div>

          {/* Links */}
          <div className="footer-links-grid">
            <div className="footer-link-group">
              <h4 className="footer-link-title">{t("footer.quickLinks")}</h4>
              <ul>
                <li><Link to="/">{t("footer.links.home")}</Link></li>
                <li><Link to="/communities">{t("footer.links.about")}</Link></li>
                <li><Link to="/pricing">{t("footer.links.pricing")}</Link></li>
                <li><Link to="/contact">{t("footer.links.contact")}</Link></li>
              </ul>
            </div>

            <div className="footer-link-group">
              <h4 className="footer-link-title">{t("footer.contactInfo")}</h4>
              <ul className="footer-contact">
                <li>
                  <i className="bi bi-envelope"></i>
                  <span>bananatalkmain@gmail.com</span>
                </li>
                <li>
                  <i className="bi bi-geo-alt"></i>
                  <span>{t("footer.address")}</span>
                </li>
              </ul>
            </div>

            <div className="footer-link-group">
              <h4 className="footer-link-title">{t("home.download.badge")}</h4>
              <div className="footer-app-links">
                <a href={APP_STORE_URL} target="_blank" rel="noopener noreferrer" className="footer-store-btn">
                  <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                  </svg>
                  App Store
                </a>
                <a href={PLAY_STORE_URL} target="_blank" rel="noopener noreferrer" className="footer-store-btn">
                  <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor">
                    <path d="M3.18 23.77c-.35-.17-.57-.5-.6-.87L2.55 1.14c-.03-.37.14-.73.45-.93l9.55 11.25L3.18 23.77zm1.39.27l9.12-10.75 2.77 3.27-11.14 7.22c-.23.15-.49.23-.75.26zm12.88-8.44l-2.73-3.22 2.73-3.22 3.11 2.01c.72.47.72 1.23 0 1.69l-3.11 2.74zM4.57.03l11.14 7.22-2.77 3.27L3.81.77C4.04.35 4.3.14 4.57.03z"/>
                  </svg>
                  Google Play
                </a>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom */}
        <div className="footer-bottom">
          <p className="footer-copyright">
            &copy; {new Date().getFullYear()} BananaTalk. {t("footer.allRightsReserved")}
          </p>
          <div className="footer-legal">
            <Link to="/privacy-policy">Privacy Policy</Link>
            <Link to="/terms">Terms of Service</Link>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default FooterMain;
