import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
// lucide, not bootstrap-icons: the footer renders on every prerendered
// marketing page, and the bootstrap-icons font/stylesheet is no longer part
// of the app at all. These seven glyphs are tree-shaken out of lucide, so
// they cost bytes instead of a webfont.
import {
  Instagram,
  Facebook,
  Linkedin,
  Youtube,
  Mail,
  MapPin,
} from "lucide-react";
import StoreLink from "../growth/StoreLink";
import { openConsentManager } from "../../analytics/consent";
import { GA_MEASUREMENT_ID } from "../../analytics/ga";
import "./FooterMain.scss";
import brandLogo from "../../assets/logo.png";

// lucide 0.511 has no X glyph -- its `Twitter` export is still the pre-2023
// bird, and the markup this footer replaced used `bi-twitter-x`. Rather than
// regress that one brand mark, the logo is inlined: 24 bytes of path data,
// sized and coloured exactly like the five lucide siblings (currentColor,
// 18px) so `.footer-social a`'s hover rule keeps working.
const XLogo: React.FC = () => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="currentColor"
    aria-hidden="true"
    focusable="false"
  >
    <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231 5.45-6.231Zm-1.161 17.52h1.833L7.084 4.126H5.117L17.083 19.77Z" />
  </svg>
);

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
              <img className="footer-logo-icon" src={brandLogo} alt="" aria-hidden />
              <span className="footer-logo-text">BananaTalk</span>
            </Link>
            <p className="footer-tagline">
              {t("footer.aboutDescription")}
            </p>
            <div className="footer-social">
              <a href="https://instagram.com" target="_blank" rel="noopener noreferrer" aria-label="Instagram">
                <Instagram size={18} aria-hidden="true" />
              </a>
              <a href="https://twitter.com" target="_blank" rel="noopener noreferrer" aria-label="X (formerly Twitter)">
                <XLogo />
              </a>
              <a href="https://facebook.com" target="_blank" rel="noopener noreferrer" aria-label="Facebook">
                <Facebook size={18} aria-hidden="true" />
              </a>
              <a href="https://linkedin.com" target="_blank" rel="noopener noreferrer" aria-label="LinkedIn">
                <Linkedin size={18} aria-hidden="true" />
              </a>
              <a href="https://youtube.com" target="_blank" rel="noopener noreferrer" aria-label="YouTube">
                <Youtube size={18} aria-hidden="true" />
              </a>
            </div>
          </div>

          {/* Links */}
          <div className="footer-links-grid">
            <div className="footer-link-group">
              <h4 className="footer-link-title">{t("footer.quickLinks")}</h4>
              <ul>
                <li><Link to="/">{t("footer.links.home")}</Link></li>
                <li><Link to="/communities">{t("footer.links.communities") || "Communities"}</Link></li>
                <li><Link to="/#pricing">{t("footer.links.pricing")}</Link></li>
                <li><Link to="/meet">{t("footer.links.meet") || "Meet people"}</Link></li>
                <li><Link to="/learn-korean">{t("footer.links.learnKorean") || "Learn Korean"}</Link></li>
                <li><Link to="/download">{t("footer.links.download") || "Download the app"}</Link></li>
                <li><Link to="/support">{t("footer.links.contact")}</Link></li>
              </ul>
            </div>

            <div className="footer-link-group">
              <h4 className="footer-link-title">{t("footer.contactInfo")}</h4>
              <ul className="footer-contact">
                <li>
                  <Mail size={16} aria-hidden="true" />
                  <span>bananatalkmain@gmail.com</span>
                </li>
                <li>
                  <MapPin size={16} aria-hidden="true" />
                  <span>{t("footer.address")}</span>
                </li>
              </ul>
            </div>

            <div className="footer-link-group">
              <h4 className="footer-link-title">{t("home.download.badge")}</h4>
              <div className="footer-app-links">
                <StoreLink store="ios" placement="footer" variant="badge" className="footer-store-btn" />
                <StoreLink store="android" placement="footer" variant="badge" className="footer-store-btn" />
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
            <Link to="/terms-of-use">Terms of Service</Link>
            {/* Only where analytics actually runs. With no measurement id
                nothing is collected, so a withdrawal control would be
                theatre -- and the footer stays exactly as it was. The id is
                a build-time value, identical on the server and in the
                browser, so this is safe on the prerendered pages. */}
            {GA_MEASUREMENT_ID ? (
              <button
                type="button"
                data-testid="footer-privacy-choices"
                className="footer-legal-button"
                onClick={openConsentManager}
              >
                {t("consent.manage.privacyChoices") || "Privacy choices"}
              </button>
            ) : null}
          </div>
        </div>
      </div>
    </footer>
  );
};

export default FooterMain;
