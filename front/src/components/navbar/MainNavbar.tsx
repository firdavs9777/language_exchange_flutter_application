import React, { useState, useEffect, useRef } from "react";
import {
  FaUsers,
  FaComment,
  FaGlobe,
  FaCaretDown,
  FaRegUser,
  FaBars,
  FaTimes,
  FaCog,
  FaSignOutAlt,
  FaHeart,
  FaUserFriends,
  FaBookOpen,
  FaChevronDown,
} from "react-icons/fa";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { logout } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import { NavLink } from "react-router-dom";

import { BASE_URL } from "../../constants";
import logo from "../../assets/logo.png";
import "./MainNavbar.scss";

const LANGUAGES = [
  { code: "en", flag: "🇺🇸", name: "English" },
  { code: "ko", flag: "🇰🇷", name: "한국어" },
  { code: "ja", flag: "🇯🇵", name: "日本語" },
  { code: "zh", flag: "🇨🇳", name: "中文" },
  { code: "zh_TW", flag: "🇹🇼", name: "繁體中文" },
  { code: "es", flag: "🇪🇸", name: "Español" },
  { code: "fr", flag: "🇫🇷", name: "Français" },
  { code: "de", flag: "🇩🇪", name: "Deutsch" },
  { code: "pt", flag: "🇧🇷", name: "Português" },
  { code: "it", flag: "🇮🇹", name: "Italiano" },
  { code: "ru", flag: "🇷🇺", name: "Русский" },
  { code: "ar", flag: "🇸🇦", name: "العربية" },
  { code: "hi", flag: "🇮🇳", name: "हिन्दी" },
  { code: "vi", flag: "🇻🇳", name: "Tiếng Việt" },
  { code: "th", flag: "🇹🇭", name: "ไทย" },
  { code: "tr", flag: "🇹🇷", name: "Türkçe" },
  { code: "id", flag: "🇮🇩", name: "Bahasa" },
  { code: "tl", flag: "🇵🇭", name: "Filipino" },
];

const MainNavbar = () => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isLanguageDropdownOpen, setIsLanguageDropdownOpen] = useState(false);
  const [isUserDropdownOpen, setIsUserDropdownOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);

  const langDropdownRef = useRef<HTMLDivElement>(null);
  const userDropdownRef = useRef<HTMLDivElement>(null);

  const userInfo = useSelector((state: any) => state.auth.userInfo);
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t, i18n } = useTranslation();

  const currentLang = LANGUAGES.find((l) => l.code === i18n.language) || LANGUAGES[0];

  // Scroll effect
  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 10);
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  // Close dropdowns on outside click
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (langDropdownRef.current && !langDropdownRef.current.contains(e.target as Node)) {
        setIsLanguageDropdownOpen(false);
      }
      if (userDropdownRef.current && !userDropdownRef.current.contains(e.target as Node)) {
        setIsUserDropdownOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  // Lock body scroll when mobile menu is open
  useEffect(() => {
    document.body.style.overflow = isMobileMenuOpen ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [isMobileMenuOpen]);

  const changeLanguage = (lng: string) => {
    const lang = LANGUAGES.find((l) => l.code === lng);
    i18n.changeLanguage(lng);
    localStorage.setItem("preferredLanguage", lng);
    setIsLanguageDropdownOpen(false);
    toast.info(`${lang?.flag} ${lang?.name}`, {
      autoClose: 2000,
      hideProgressBar: true,
      theme: "dark",
      transition: Bounce,
    });
  };

  const logoutHandler = async () => {
    try {
      dispatch(logout());
      navigate("/login");
      setIsUserDropdownOpen(false);
      setIsMobileMenuOpen(false);
      toast.success(t("logout") + " ✓", {
        autoClose: 2000,
        hideProgressBar: true,
        theme: "dark",
        transition: Bounce,
      });
    } catch (error: any) {
      alert(error.message);
    }
  };

  const closeMobileMenu = () => setIsMobileMenuOpen(false);

  const getUserImage = () => {
    if (Array.isArray(userInfo?.user?.imageUrls) && userInfo.user.imageUrls[0]?.startsWith("http")) {
      return userInfo.user.imageUrls[0];
    }
    if (Array.isArray(userInfo?.user?.images) && userInfo.user.images[0]) {
      return userInfo.user.images[0].startsWith("http")
        ? userInfo.user.images[0]
        : `${BASE_URL}/uploads/${userInfo.user.images[0]}`;
    }
    return "/default-avatar.png";
  };

  return (
    <>
      <header className={`main-navbar ${isScrolled ? "scrolled" : ""}`}>
        <nav className="navbar-inner">
          {/* Logo */}
          <NavLink to="/" className="navbar-logo" onClick={closeMobileMenu}>
            <img src={logo} alt="BananaTalk" />
            <div className="navbar-logo-text">
              <span className="logo-name">BananaTalk</span>
              <span className="logo-tagline">{t("home.hero.subtitle") ? "Language Exchange" : "Language Exchange"}</span>
            </div>
          </NavLink>

          {/* Desktop Navigation */}
          <div className="navbar-links">
            <NavLink
              to="/communities"
              className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
            >
              <FaUsers />
              <span>{t("community")}</span>
            </NavLink>

            {userInfo && (
              <>
                <NavLink
                  to="/chat"
                  className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                >
                  <FaComment />
                  <span>{t("chat")}</span>
                </NavLink>

                <NavLink
                  to="/moments"
                  className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                >
                  <FaGlobe />
                  <span>{t("moments")}</span>
                </NavLink>

                <NavLink
                  to="/learn"
                  className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                >
                  <FaBookOpen />
                  <span>{t("learning.title") || "Learn"}</span>
                </NavLink>
              </>
            )}
          </div>

          {/* Right side actions */}
          <div className="navbar-actions">
            {/* Language Dropdown */}
            <div className="dropdown-wrapper" ref={langDropdownRef}>
              <button
                className="lang-btn"
                onClick={() => {
                  setIsLanguageDropdownOpen(!isLanguageDropdownOpen);
                  setIsUserDropdownOpen(false);
                }}
              >
                <span className="lang-flag">{currentLang.flag}</span>
                <span className="lang-label">{currentLang.name}</span>
                <FaChevronDown className={`chevron ${isLanguageDropdownOpen ? "open" : ""}`} />
              </button>

              {isLanguageDropdownOpen && (
                <div className="dropdown-panel lang-dropdown">
                  <div className="dropdown-header">{t("language") || "Language"}</div>
                  <div className="lang-grid">
                    {LANGUAGES.map((lang) => (
                      <button
                        key={lang.code}
                        onClick={() => changeLanguage(lang.code)}
                        className={`lang-option ${i18n.language === lang.code ? "active" : ""}`}
                      >
                        <span className="lang-option-flag">{lang.flag}</span>
                        <span className="lang-option-name">{lang.name}</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* User Menu */}
            {userInfo ? (
              <div className="dropdown-wrapper" ref={userDropdownRef}>
                <button
                  className="user-btn"
                  onClick={() => {
                    setIsUserDropdownOpen(!isUserDropdownOpen);
                    setIsLanguageDropdownOpen(false);
                  }}
                >
                  <img src={getUserImage()} alt="" className="user-avatar" />
                  <span className="user-name">{userInfo.user?.name}</span>
                  <FaChevronDown className={`chevron ${isUserDropdownOpen ? "open" : ""}`} />
                </button>

                {isUserDropdownOpen && (
                  <div className="dropdown-panel user-dropdown">
                    <div className="dropdown-user-header">
                      <img src={getUserImage()} alt="" />
                      <div>
                        <div className="dropdown-user-name">{userInfo.user?.name}</div>
                        <div className="dropdown-user-email">{userInfo.user?.email}</div>
                      </div>
                    </div>
                    <div className="dropdown-divider" />
                    <NavLink to="/profile" className="dropdown-item" onClick={() => setIsUserDropdownOpen(false)}>
                      <FaRegUser /> {t("profile.title")}
                    </NavLink>
                    <NavLink to="/followersList" className="dropdown-item" onClick={() => setIsUserDropdownOpen(false)}>
                      <FaHeart /> {t("followers")}
                    </NavLink>
                    <NavLink to="/followingsList" className="dropdown-item" onClick={() => setIsUserDropdownOpen(false)}>
                      <FaUserFriends /> {t("followings")}
                    </NavLink>
                    <NavLink to="/my-moments" className="dropdown-item" onClick={() => setIsUserDropdownOpen(false)}>
                      <FaGlobe /> {t("my_moments")}
                    </NavLink>
                    <NavLink to="/settings" className="dropdown-item" onClick={() => setIsUserDropdownOpen(false)}>
                      <FaCog /> {t("settings.title") || "Settings"}
                    </NavLink>
                    <div className="dropdown-divider" />
                    <button onClick={logoutHandler} className="dropdown-item logout-item">
                      <FaSignOutAlt /> {t("logout")}
                    </button>
                  </div>
                )}
              </div>
            ) : (
              <NavLink to="/login" className="login-btn">
                <FaRegUser />
                <span>{t("sign_in")}</span>
              </NavLink>
            )}

            {/* Mobile hamburger */}
            <button
              className="mobile-toggle"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              aria-label="Menu"
            >
              {isMobileMenuOpen ? <FaTimes /> : <FaBars />}
            </button>
          </div>
        </nav>
      </header>

      {/* Mobile Menu Overlay */}
      {isMobileMenuOpen && (
        <div className="mobile-overlay" onClick={closeMobileMenu}>
          <div className="mobile-menu" onClick={(e) => e.stopPropagation()}>
            {/* Mobile Header */}
            <div className="mobile-menu-header">
              <NavLink to="/" className="navbar-logo" onClick={closeMobileMenu}>
                <img src={logo} alt="BananaTalk" />
                <span className="logo-name">BananaTalk</span>
              </NavLink>
              <button className="mobile-close" onClick={closeMobileMenu}>
                <FaTimes />
              </button>
            </div>

            {/* Mobile User Info */}
            {userInfo && (
              <div className="mobile-user-card">
                <img src={getUserImage()} alt="" />
                <div>
                  <div className="mobile-user-name">{userInfo.user?.name}</div>
                  <div className="mobile-user-email">{userInfo.user?.email}</div>
                </div>
              </div>
            )}

            {/* Mobile Nav Links */}
            <div className="mobile-nav-section">
              <NavLink to="/communities" className="mobile-nav-link" onClick={closeMobileMenu}>
                <FaUsers /> {t("community")}
              </NavLink>
              {userInfo && (
                <>
                  <NavLink to="/chat" className="mobile-nav-link" onClick={closeMobileMenu}>
                    <FaComment /> {t("chat")}
                  </NavLink>
                  <NavLink to="/moments" className="mobile-nav-link" onClick={closeMobileMenu}>
                    <FaGlobe /> {t("moments")}
                  </NavLink>
                  <NavLink to="/learn" className="mobile-nav-link" onClick={closeMobileMenu}>
                    <FaBookOpen /> {t("learning.title") || "Learn"}
                  </NavLink>
                </>
              )}
            </div>

            {/* Mobile User Links */}
            {userInfo && (
              <div className="mobile-nav-section">
                <div className="mobile-section-title">{t("profile.title")}</div>
                <NavLink to="/profile" className="mobile-nav-link" onClick={closeMobileMenu}>
                  <FaRegUser /> {t("profile.title")}
                </NavLink>
                <NavLink to="/followersList" className="mobile-nav-link" onClick={closeMobileMenu}>
                  <FaHeart /> {t("followers")}
                </NavLink>
                <NavLink to="/followingsList" className="mobile-nav-link" onClick={closeMobileMenu}>
                  <FaUserFriends /> {t("followings")}
                </NavLink>
                <NavLink to="/my-moments" className="mobile-nav-link" onClick={closeMobileMenu}>
                  <FaGlobe /> {t("my_moments")}
                </NavLink>
                <NavLink to="/settings" className="mobile-nav-link" onClick={closeMobileMenu}>
                  <FaCog /> {t("settings.title") || "Settings"}
                </NavLink>
              </div>
            )}

            {/* Mobile Language Selection */}
            <div className="mobile-nav-section">
              <div className="mobile-section-title">{t("language") || "Language"}</div>
              <div className="mobile-lang-grid">
                {LANGUAGES.map((lang) => (
                  <button
                    key={lang.code}
                    onClick={() => {
                      changeLanguage(lang.code);
                      closeMobileMenu();
                    }}
                    className={`mobile-lang-btn ${i18n.language === lang.code ? "active" : ""}`}
                  >
                    <span>{lang.flag}</span>
                    <span>{lang.name}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Mobile Footer Actions */}
            <div className="mobile-footer-actions">
              {userInfo ? (
                <button onClick={logoutHandler} className="mobile-logout-btn">
                  <FaSignOutAlt /> {t("logout")}
                </button>
              ) : (
                <NavLink to="/login" className="mobile-login-btn" onClick={closeMobileMenu}>
                  <FaRegUser /> {t("sign_in")}
                </NavLink>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default MainNavbar;
