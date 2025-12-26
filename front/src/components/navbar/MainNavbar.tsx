import React, { useState } from "react";
import {
  FaUser,
  FaUsers,
  FaComment,
  FaGlobe,
  FaCaretDown,
  FaRegUser,
  FaLanguage,
  FaBars,
  FaTimes,
} from "react-icons/fa";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { useDispatch } from "react-redux";
import { useSelector } from "react-redux";
import { logout } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import { NavLink } from "react-router-dom";

import logo from "../../assets/logo.png";

const MainNavbar = () => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isLanguageDropdownOpen, setIsLanguageDropdownOpen] = useState(false);
  const [isUserDropdownOpen, setIsUserDropdownOpen] = useState(false);

  const userInfo = useSelector((state: any) => state.auth.userInfo);
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t, i18n } = useTranslation();

  const changeLanguage = (lng: string) => {
    i18n.changeLanguage(lng);
    localStorage.setItem("preferredLanguage", lng);
    setIsLanguageDropdownOpen(false);
    toast.info(`Language changed to ${lng === "en" ? "English" : "한국어"}`, {
      autoClose: 3000,
      hideProgressBar: false,
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
      toast.success("User successfully logged out!", {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    } catch (error: any) {
      alert(error.message);
    }
  };

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  const closeMobileMenu = () => {
    setIsMobileMenuOpen(false);
  };

  interface NavLinkComponentProps {
    to: string;
    children: React.ReactNode;
    onClick?: () => void;
  }

  const NavLinkComponent: React.FC<NavLinkComponentProps> = ({
    to,
    children,
    onClick,
  }) => (
    <NavLink
      to={to}
      onClick={onClick}
      className={({ isActive }) =>
        `flex items-center px-4 py-2 mx-1 font-medium transition-all duration-300 rounded-lg relative group ${
          isActive
            ? "text-yellow-400 font-bold bg-gradient-to-r from-yellow-400/20 to-yellow-500/20 border border-yellow-400/30 shadow-lg shadow-yellow-400/20 scale-105"
            : "text-white hover:text-yellow-400 hover:bg-gray-800/50 hover:scale-105"
        }`
      }
    >
      <span className="relative z-10 flex items-center">{children}</span>
    </NavLink>
  );

  const CustomNavLink: React.FC<NavLinkComponentProps> = ({
    to,
    children,
    onClick,
  }) => {
    return (
      <NavLink to={to} onClick={onClick}>
        {({ isActive }) => (
          <div
            className={`flex items-center px-4 py-2 mx-1 font-medium transition-all duration-300 rounded-lg relative group ${
              isActive
                ? "text-yellow-400 font-bold bg-gradient-to-r from-yellow-400/20 to-yellow-500/20 border border-yellow-400/30 shadow-lg shadow-yellow-400/20 scale-105"
                : "text-white hover:text-yellow-400 hover:bg-gray-800/50 hover:scale-105"
            }`}
          >
            {children}

            <span
              className={`absolute bottom-1 left-1/2 h-0.5 bg-gradient-to-r from-yellow-300 to-yellow-500 transition-all duration-300 ${
                isActive
                  ? "w-4/5 -translate-x-1/2 shadow-sm shadow-yellow-400/50"
                  : "w-0 group-hover:w-2/3 group-hover:-translate-x-1/2"
              }`}
            ></span>

            {/* Active state glow effect */}
            {isActive && (
              <span className="absolute inset-0 rounded-lg bg-gradient-to-r from-yellow-400/10 to-yellow-500/10 blur-sm"></span>
            )}
          </div>
        )}
      </NavLink>
    );
  };

  return (
    <header className="bg-gradient-to-r from-slate-700 via-gray-700 to-slate-700 shadow-2xl sticky top-0 z-50 backdrop-blur-sm">
      <nav className="container mx-auto px-4">
        <div className="flex items-center justify-between h-20">
          {/* Logo */}
          <div className="flex-shrink-0">
            <a href="/" className="flex items-center">
              <img
                src={logo}
                alt="BananaTalk"
                className="h-16 w-auto hover:scale-105 transition-transform duration-300"
              />
            </a>
          </div>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-2">
            <CustomNavLink to="/communities">
              <FaUsers size={20} className="mr-2" />
              {t("community")}
            </CustomNavLink>

            {userInfo && (
              <>
                <CustomNavLink to="/chat">
                  <FaComment size={20} className="mr-2" />
                  {t("chat")}
                </CustomNavLink>

                <CustomNavLink to="/moments">
                  <FaGlobe size={20} className="mr-2" />
                  {t("moments")}
                </CustomNavLink>
              </>
            )}
            <div className="relative">
              <button
                onClick={() =>
                  setIsLanguageDropdownOpen(!isLanguageDropdownOpen)
                }
                className="flex items-center px-4 py-2 mx-1 text-white font-medium transition-all duration-300 rounded-lg hover:text-yellow-400 hover:bg-gray-600/50"
              >
                <FaLanguage size={20} className="mr-2" />
                <span className="hidden lg:inline">
                  {i18n.language === "en" ? t("english") : t("korean")}
                </span>
                <FaCaretDown size={16} className="ml-1" />
              </button>

              {isLanguageDropdownOpen && (
                <div className="absolute right-0 mt-2 w-48 bg-gray-600 rounded-lg shadow-xl border border-gray-500 overflow-hidden z-50">
                  <button
                    onClick={() => changeLanguage("en")}
                    className={`w-full text-left px-4 py-3 flex items-center ${
                      i18n.language === "en"
                        ? "text-yellow-400 font-bold bg-gradient-to-r from-yellow-400/20 to-yellow-500/20 border border-yellow-400/30 shadow-lg shadow-yellow-400/20 scale-105"
                        : " text-white hover:bg-gray-500 transition-colors duration-200"
                    }`}
                  >
                    🇺🇸 <span className="ml-2">{t("english")}</span>
                  </button>
                  <button
                    onClick={() => changeLanguage("ko")}
                    className={`w-full text-left px-4 py-3  hover:bg-gray-500 transition-colors duration-200 flex items-center ${
                      i18n.language === "ko"
                        ? "text-yellow-400 font-bold bg-gradient-to-r from-yellow-400/20 to-yellow-500/20 border border-yellow-400/30 shadow-lg shadow-yellow-400/20 scale-105"
                        : "text-white"
                    }`}
                  >
                    🇰🇷 <span className="ml-2">{t("korean")}</span>
                  </button>
                </div>
              )}
            </div>

            {/* User Menu / Login */}
            {userInfo ? (
              <div className="relative">
                <button
                  onClick={() => setIsUserDropdownOpen(!isUserDropdownOpen)}
                  className="flex items-center px-3 py-2 text-white font-medium transition-all duration-300 rounded-lg hover:bg-gray-600/50 max-w-[140px]"
                >
                  <img
                    src={
                      Array.isArray(userInfo?.user?.imageUrls) &&
                      userInfo.user.imageUrls[0]?.startsWith("http")
                        ? userInfo.user.imageUrls[0]
                        : Array.isArray(userInfo?.user?.images) &&
                          userInfo.user.images[0]
                        ? userInfo.user.images[0].startsWith("http")
                          ? userInfo.user.images[0]
                          : `http://localhost:5003/uploads/${userInfo.user.images[0]}`
                        : "/default-avatar.png"
                    }
                    alt="Profile"
                    className="w-8 h-8 rounded-full object-cover mr-2 ring-2 ring-gray-600 hover:ring-yellow-400 transition-all duration-300"
                  />
                  <span className="truncate text-sm">
                    {userInfo.user?.name}
                  </span>
                  <FaCaretDown size={16} className="ml-1 flex-shrink-0" />
                </button>

                {isUserDropdownOpen && (
                  <div className="absolute right-0 mt-2 w-56 bg-gray-600 rounded-lg shadow-xl border border-gray-500 overflow-hidden z-50">
                    <CustomNavLink
                      to="/profile"
                      onClick={() => setIsUserDropdownOpen(false)}
                    >
                      <FaRegUser className="inline mr-3" />
                      {t("profile.title")}
                    </CustomNavLink>
                    <CustomNavLink
                      onClick={() => setIsUserDropdownOpen(false)}
                      to="/followersList"
                    >
                      <FaUsers className="inline mr-3" />
                      {t("followers")}
                    </CustomNavLink>

                    <CustomNavLink
                      to="/followingsList"
                      onClick={() => setIsUserDropdownOpen(false)}
                    >
                      <FaUsers className="inline mr-3" />
                      {t("followings")}
                    </CustomNavLink>
                    <CustomNavLink
                      to="/my-moments"
                      onClick={() => setIsUserDropdownOpen(false)}
                    >
                      <FaGlobe className="inline mr-3" />
                      {t("my_moments")}
                    </CustomNavLink>

                    <button
                      onClick={logoutHandler}
                      className="w-full text-left px-4 py-3 text-white hover:bg-gray-700 transition-colors duration-200"
                    >
                      <FaUser className="inline mr-3" />
                      {t("logout")}
                    </button>
                  </div>
                )}
              </div>
            ) : (
              <CustomNavLink to="/login">
                <FaRegUser size={18} className="mr-2" />
                {t("sign_in")}
              </CustomNavLink>
            )}
          </div>

          {/* Mobile menu button */}
          <div className="md:hidden">
            <button
              onClick={toggleMobileMenu}
              className="text-white hover:text-yellow-400 transition-colors duration-300 p-2"
            >
              {isMobileMenuOpen ? <FaTimes size={24} /> : <FaBars size={24} />}
            </button>
          </div>
        </div>

        {isMobileMenuOpen && (
          <div className="md:hidden bg-gray-800/95 backdrop-blur-sm rounded-lg mt-2 mb-4 shadow-xl border border-gray-700">
            <div className="px-4 py-4 space-y-2">
              <CustomNavLink to="/communities" onClick={closeMobileMenu}>
                <FaUsers size={20} className="mr-3" />
                {t("community")}
              </CustomNavLink>

              {userInfo && (
                <>
                  <CustomNavLink to="/chat" onClick={closeMobileMenu}>
                    <FaComment size={20} className="mr-3" />
                    {t("chat")}
                  </CustomNavLink>

                  <CustomNavLink to="/moments" onClick={closeMobileMenu}>
                    <FaGlobe size={20} className="mr-3" />
                    {t("moments")}
                  </CustomNavLink>
                </>
              )}

              {/* Mobile Language Selection */}
              <div className="border-t border-gray-700 pt-2 mt-2">
                <p className="text-gray-300 text-sm px-4 py-2 font-medium">
                  {t("language")}
                </p>
                <button
                  onClick={() => changeLanguage("en")}
                  className={`w-full text-left px-4 py-2 text-white hover:bg-gray-700 rounded transition-colors duration-200 flex items-center ${
                    i18n.language === "en" ? "bg-gray-700 text-yellow-400" : ""
                  }`}
                >
                  🇺🇸 <span className="ml-2">{t("english")}</span>
                </button>
                <button
                  onClick={() => changeLanguage("ko")}
                  className={`w-full text-left px-4 py-2 text-white hover:bg-gray-700 rounded transition-colors duration-200 flex items-center ${
                    i18n.language === "ko" ? "bg-gray-700 text-[]" : ""
                  }`}
                >
                  🇰🇷 <span className="ml-2">{t("korean")}</span>
                </button>
              </div>

              {/* Mobile User Menu */}
              {userInfo ? (
                <div className="border-t border-gray-700 pt-2 mt-2">
                  <div className="flex items-center px-4 py-2 mb-2">
                    <img
                      src={
                        Array.isArray(userInfo?.user?.imageUrls) &&
                        userInfo.user.imageUrls[0]?.startsWith("http")
                          ? userInfo.user.imageUrls[0]
                          : Array.isArray(userInfo?.user?.images) &&
                            userInfo.user.images[0]
                          ? userInfo.user.images[0].startsWith("http")
                            ? userInfo.user.images[0]
                            : `http://localhost:5003/uploads/${userInfo.user.images[0]}`
                          : "/default-avatar.png"
                      }
                      alt="Profile"
                      className="w-10 h-10 rounded-full object-cover mr-3 ring-2 ring-gray-600"
                    />
                    <span className="text-white font-medium">
                      {userInfo.user?.name}
                    </span>
                  </div>

                  <CustomNavLink to="/profile" onClick={closeMobileMenu}>
                    <FaRegUser className="inline mr-3" />
                    {t("profile.title")}
                  </CustomNavLink>
                  <CustomNavLink to="/followersList" onClick={closeMobileMenu}>
                    <FaUsers className="inline mr-3" />
                    {t("followers")}
                  </CustomNavLink>
                  <CustomNavLink to="/followingsList" onClick={closeMobileMenu}>
                    <FaUsers className="inline mr-3" />
                    {t("followings")}
                  </CustomNavLink>
                  <CustomNavLink to="/my-moments" onClick={closeMobileMenu}>
                    <FaGlobe className="inline mr-3" />
                    {t("my_moments")}
                  </CustomNavLink>
                  <button
                    onClick={logoutHandler}
                    className="w-full text-left px-4 py-2 text-white hover:bg-gray-700 rounded transition-colors duration-200 mt-2 border-t border-gray-700 pt-2"
                  >
                    <FaUser className="inline mr-3" />
                    {t("logout")}
                  </button>
                </div>
              ) : (
                <div className="border-t border-gray-700 pt-2 mt-2">
                  <a
                    href="/login"
                    onClick={closeMobileMenu}
                    className="block px-4 py-2 text-white hover:bg-gray-700 rounded transition-colors duration-200"
                  >
                    <FaRegUser className="inline mr-3" />
                    {t("sign_in")}
                  </a>
                </div>
              )}
            </div>
          </div>
        )}
      </nav>
    </header>
  );
};

export default MainNavbar;
