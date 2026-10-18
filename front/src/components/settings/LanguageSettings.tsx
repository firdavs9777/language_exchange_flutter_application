import React, { useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { switchLanguage } from "../../utils/switchLanguage";
import { RootState } from "../../store";
import { useUpdateUserInfoMutation } from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import { ArrowLeft, Globe, BookOpen, Check, Save } from "lucide-react";

const LANGUAGES = [
  { code: "English", name: "English", flag: "🇺🇸" },
  { code: "Korean", name: "한국어", flag: "🇰🇷" },
  { code: "Japanese", name: "日本語", flag: "🇯🇵" },
  { code: "Chinese", name: "中文", flag: "🇨🇳" },
  { code: "Spanish", name: "Español", flag: "🇪🇸" },
  { code: "French", name: "Français", flag: "🇫🇷" },
  { code: "German", name: "Deutsch", flag: "🇩🇪" },
  { code: "Portuguese", name: "Português", flag: "🇧🇷" },
  { code: "Russian", name: "Русский", flag: "🇷🇺" },
  { code: "Italian", name: "Italiano", flag: "🇮🇹" },
  { code: "Vietnamese", name: "Tiếng Việt", flag: "🇻🇳" },
  { code: "Thai", name: "ไทย", flag: "🇹🇭" },
  { code: "Arabic", name: "العربية", flag: "🇸🇦" },
  { code: "Hindi", name: "हिन्दी", flag: "🇮🇳" },
  { code: "Indonesian", name: "Bahasa Indonesia", flag: "🇮🇩" },
];

const APP_LANGUAGES = [
  { code: "en", name: "English", flag: "🇺🇸" },
  { code: "ko", name: "한국어", flag: "🇰🇷" },
  { code: "zh", name: "中文", flag: "🇨🇳" },
];

interface LanguageButtonProps {
  language: { code: string; name: string; flag: string };
  selected: boolean;
  onClick: () => void;
}

const LanguageButton: React.FC<LanguageButtonProps> = ({ language, selected, onClick }) => (
  <button
    onClick={onClick}
    className={`flex items-center gap-3 p-4 rounded-xl transition-all duration-200 w-full ${
      selected
        ? "bg-gradient-to-r from-teal-500 to-teal-600 text-white shadow-lg"
        : "bg-white/60 backdrop-blur-sm border border-white/30 text-gray-800 hover:bg-white/80"
    }`}
  >
    <span className="text-2xl">{language.flag}</span>
    <span className="flex-1 text-left font-medium">{language.name}</span>
    {selected && <Check className="w-5 h-5" />}
  </button>
);

const LanguageSettings: React.FC = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const user = userInfo?.user;
  const [updateUserInfo, { isLoading }] = useUpdateUserInfoMutation();

  // resolvedLanguage, not language: with locales loaded on demand i18next may
  // hold a region code ("ko-KR") whose active bundle is the base language.
  const [appLanguage, setAppLanguage] = useState(i18n.resolvedLanguage || i18n.language);
  const requestedLanguage = useRef<string | null>(null);
  const [nativeLanguage, setNativeLanguage] = useState(user?.native_language || "English");
  const [learningLanguage, setLearningLanguage] = useState(user?.language_to_learn || "Korean");
  const [hasChanges, setHasChanges] = useState(false);

  const handleAppLanguageChange = (code: string) => {
    setAppLanguage(code);
    requestedLanguage.current = code;
    // The bundle is a chunk now, so two taps inside one load window settle in
    // network order and i18next keeps whichever *arrived* last, not whichever
    // was *asked for* last. Re-apply the last request once a switch settles;
    // the re-apply's own callback finds them in agreement and stops.
    void switchLanguage(i18n, code).then(() => {
      const wanted = requestedLanguage.current;
      if (wanted && wanted !== i18n.language) void switchLanguage(i18n, wanted);
    });
    localStorage.setItem("i18nextLng", code);
  };

  const handleNativeLanguageChange = (code: string) => {
    setNativeLanguage(code);
    setHasChanges(true);
  };

  const handleLearningLanguageChange = (code: string) => {
    setLearningLanguage(code);
    setHasChanges(true);
  };

  const handleSave = async () => {
    try {
      await updateUserInfo({
        native_language: nativeLanguage,
        language_to_learn: learningLanguage,
      }).unwrap();
      toast.success(t("settings.language.saveSuccess") || "Language settings saved", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setHasChanges(false);
    } catch (error) {
      toast.error(t("settings.language.saveError") || "Failed to save settings", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-yellow-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-500 to-teal-600 text-white p-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold">
              {t("settings.language.title") || "Language Settings"}
            </h1>
            <p className="text-teal-100 text-sm">
              {t("settings.language.subtitle") || "Choose your languages"}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {/* App Language */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 rounded-lg bg-gradient-to-br from-teal-400 to-teal-600">
              <Globe className="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-800">
                {t("settings.language.appLanguage") || "App Language"}
              </h3>
              <p className="text-sm text-gray-500">
                {t("settings.language.appLanguageDesc") || "Language for the app interface"}
              </p>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {APP_LANGUAGES.map((lang) => (
              <LanguageButton
                key={lang.code}
                language={lang}
                selected={appLanguage === lang.code}
                onClick={() => handleAppLanguageChange(lang.code)}
              />
            ))}
          </div>
        </div>

        {/* Native Language */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 rounded-lg bg-gradient-to-br from-blue-400 to-blue-600">
              <Globe className="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-800">
                {t("settings.language.nativeLanguage") || "Native Language"}
              </h3>
              <p className="text-sm text-gray-500">
                {t("settings.language.nativeLanguageDesc") || "Your mother tongue"}
              </p>
            </div>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 max-h-64 overflow-y-auto">
            {LANGUAGES.map((lang) => (
              <LanguageButton
                key={lang.code}
                language={lang}
                selected={nativeLanguage === lang.code}
                onClick={() => handleNativeLanguageChange(lang.code)}
              />
            ))}
          </div>
        </div>

        {/* Learning Language */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 rounded-lg bg-gradient-to-br from-purple-400 to-purple-600">
              <BookOpen className="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-800">
                {t("settings.language.learningLanguage") || "Learning Language"}
              </h3>
              <p className="text-sm text-gray-500">
                {t("settings.language.learningLanguageDesc") || "The language you want to learn"}
              </p>
            </div>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 max-h-64 overflow-y-auto">
            {LANGUAGES.filter((l) => l.code !== nativeLanguage).map((lang) => (
              <LanguageButton
                key={lang.code}
                language={lang}
                selected={learningLanguage === lang.code}
                onClick={() => handleLearningLanguageChange(lang.code)}
              />
            ))}
          </div>
        </div>

        {/* Save Button */}
        {hasChanges && (
          <button
            onClick={handleSave}
            disabled={isLoading}
            className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-teal-500 to-teal-600 text-white py-4 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200 disabled:opacity-50"
          >
            <Save className="w-5 h-5" />
            {isLoading
              ? t("settings.language.saving") || "Saving..."
              : t("settings.language.saveChanges") || "Save Changes"}
          </button>
        )}
      </div>
    </div>
  );
};

export default LanguageSettings;
