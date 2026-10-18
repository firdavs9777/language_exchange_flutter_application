import React, { useState, useEffect, useMemo, useRef } from "react";
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
  FaChevronDown,
  FaUserShield,
  FaFilm,
  FaCalendarAlt,
  FaMicrophone,
  FaDoorOpen,
} from "react-icons/fa";
import { useWebFlag } from "../../utils/webFlags";
import { useTranslation } from "react-i18next";
import { switchLanguage } from "../../utils/switchLanguage";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { logout, selectIsAdmin } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import { NavLink } from "react-router-dom";

import { BASE_URL } from "../../constants";
import logo from "../../assets/logo.png";
import { useGetConversationsQuery } from "../../store/slices/chatSlice";
import { useSocket } from "../chat/hooks/useSocket";
import { CONVERSATIONS_PAGE } from "../chat/lib/conversationMatch";
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
  const requestedLanguage = useRef<string | null>(null);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isLanguageDropdownOpen, setIsLanguageDropdownOpen] = useState(false);
  const [isUserDropdownOpen, setIsUserDropdownOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);

  const langDropdownRef = useRef<HTMLDivElement>(null);
  const userDropdownRef = useRef<HTMLDivElement>(null);

  const userInfo = useSelector((state: any) => state.auth.userInfo);
  // The console's only entry point. Role comes from the backend; the route
  // itself is guarded again by RequireAdmin, and the API by authorize('admin').
  const isAdmin = useSelector(selectIsAdmin);
  // Phase 4 rooms: dark until the owner turns the flags on.
  const voiceRoomsOn = useWebFlag("webVoiceRoomsEnabled");
  const languageRoomsOn = useWebFlag("webLanguageRoomsEnabled");
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t, i18n } = useTranslation();
  const reelsOn = useWebFlag("webReelsEnabled");
  const gatheringsOn = useWebFlag("webGatheringsEnabled");

  // `resolvedLanguage`, not `language`: since locales load on demand i18next is
  // no longer restricted to bare language codes, so `language` can be "ko-KR"
  // (from navigator) while the bundle actually in force is "ko". resolvedLanguage
  // is the entry in the resolution hierarchy that really has translations, which
  // is exactly the one this menu should tick.
  const activeLang = i18n.resolvedLanguage || i18n.language;
  const currentLang = LANGUAGES.find((l) => l.code === activeLang) || LANGUAGES[0];

  // Unread chat badge. Shares the same RTK Query cache key UsersList uses --
  // CONVERSATIONS_PAGE, the one literal every caller passes -- so there is no
  // duplicate request when the chat page is also mounted, and no second copy
  // of the list going stale on its own: this badge used to ask with its own
  // {page:1, limit:50} while the chat list asked with {page:1, limit:100}, two
  // cache entries that refetched independently. Refetches live off the same
  // socket events UsersList reacts to, so the badge stays correct even when
  // the chat page isn't open at all.
  const currentUserId = userInfo?.user?._id;
  const { data: conversationsData, refetch: refetchConversations } = useGetConversationsQuery(
    CONVERSATIONS_PAGE,
    { skip: !currentUserId }
  );
  const { socket } = useSocket();

  const unreadChatCount = useMemo(() => {
    const list = conversationsData?.data;
    if (!Array.isArray(list)) return 0;
    return list.reduce((sum: number, c: any) => sum + (c?.unreadCount || 0), 0);
  }, [conversationsData]);

  useEffect(() => {
    if (!socket || !currentUserId) return;
    const handleConversationsChanged = () => refetchConversations();
    socket.on("newMessage", handleConversationsChanged);
    socket.on("newVoiceMessage", handleConversationsChanged);
    socket.on("newVideoMessage", handleConversationsChanged);
    socket.on("messagesRead", handleConversationsChanged);
    // A message WE sent changes the list too -- new last message, new row
    // order, and a brand-new row for a first message. The server addresses it
    // to every device on the account.
    socket.on("messageSent", handleConversationsChanged);
    return () => {
      socket.off("newMessage", handleConversationsChanged);
      socket.off("newVoiceMessage", handleConversationsChanged);
      socket.off("newVideoMessage", handleConversationsChanged);
      socket.off("messagesRead", handleConversationsChanged);
      socket.off("messageSent", handleConversationsChanged);
    };
  }, [socket, currentUserId, refetchConversations]);

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
    requestedLanguage.current = lng;
    // Locales are chunks now, so two clicks inside one load window settle in
    // *network* order and i18next has no staleness guard: the slower-arriving
    // language wins and the menu disagrees with the page. Re-apply whatever was
    // asked for last once a switch settles. Bounded: the re-apply's own callback
    // finds the two in agreement and stops.
    void switchLanguage(i18n, lng).then(() => {
      const wanted = requestedLanguage.current;
      if (wanted && wanted !== i18n.language) void switchLanguage(i18n, wanted);
    });
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
                  <span className="navbar-icon-wrap">
                    <FaComment />
                    {unreadChatCount > 0 && (
                      <span className="navbar-unread-badge" data-testid="chat-unread-badge">
                        {unreadChatCount > 99 ? "99+" : unreadChatCount}
                      </span>
                    )}
                  </span>
                  <span>{t("chat")}</span>
                </NavLink>

                <NavLink
                  to="/moments"
                  className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                >
                  <FaGlobe />
                  <span>{t("moments")}</span>
                </NavLink>
                {voiceRoomsOn && (
                  <NavLink
                    to="/voice-rooms"
                    data-testid="nav-voice-rooms"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaMicrophone />
                    <span>{t("nav.voiceRooms") || "Voice rooms"}</span>
                  </NavLink>
                )}
                {languageRoomsOn && (
                  <NavLink
                    to="/rooms"
                    data-testid="nav-language-rooms"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaDoorOpen />
                    <span>{t("nav.languageRooms") || "Language rooms"}</span>
                  </NavLink>
                )}

                {reelsOn && (
                  <NavLink
                    to="/reels"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaFilm />
                    <span>{t("reels.nav") || "Reels"}</span>
                  </NavLink>
                )}
                {gatheringsOn && (
                  <NavLink
                    to="/gatherings"
                    data-testid="nav-gatherings"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaCalendarAlt />
                    <span>{t("gatherings.nav") || "Gatherings"}</span>
                  </NavLink>
                )}

                {isAdmin && (
                  <NavLink
                    to="/admin"
                    className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}
                  >
                    <FaUserShield />
                    <span>{t("admin.nav.admin") || "Admin"}</span>
                  </NavLink>
                )}
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
                        className={`lang-option ${activeLang === lang.code ? "active" : ""}`}
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
                    <span className="navbar-icon-wrap">
                      <FaComment />
                      {unreadChatCount > 0 && (
                        <span className="navbar-unread-badge" data-testid="chat-unread-badge-mobile">
                          {unreadChatCount > 99 ? "99+" : unreadChatCount}
                        </span>
                      )}
                    </span>{" "}
                    {t("chat")}
                  </NavLink>
                  <NavLink to="/moments" className="mobile-nav-link" onClick={closeMobileMenu}>
                    <FaGlobe /> {t("moments")}
                  </NavLink>
                  {reelsOn && (
                    <NavLink to="/reels" className="mobile-nav-link" onClick={closeMobileMenu}>
                      <FaFilm /> {t("reels.nav") || "Reels"}
                    </NavLink>
                  )}
                  {gatheringsOn && (
                    <NavLink to="/gatherings" data-testid="nav-gatherings-mobile" className="mobile-nav-link" onClick={closeMobileMenu}>
                      <FaCalendarAlt /> {t("gatherings.nav") || "Gatherings"}
                    </NavLink>
                  )}
                  {voiceRoomsOn && (
                    <NavLink to="/voice-rooms" className="mobile-nav-link" data-testid="nav-voice-rooms-mobile" onClick={closeMobileMenu}>
                      <FaMicrophone /> {t("nav.voiceRooms") || "Voice rooms"}
                    </NavLink>
                  )}
                  {languageRoomsOn && (
                    <NavLink to="/rooms" className="mobile-nav-link" data-testid="nav-language-rooms-mobile" onClick={closeMobileMenu}>
                      <FaDoorOpen /> {t("nav.languageRooms") || "Language rooms"}
                    </NavLink>
                  )}
                  {isAdmin && (
                    <NavLink to="/admin" className="mobile-nav-link" onClick={closeMobileMenu}>
                      <FaUserShield /> {t("admin.nav.admin") || "Admin"}
                    </NavLink>
                  )}
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
                    className={`mobile-lang-btn ${activeLang === lang.code ? "active" : ""}`}
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
