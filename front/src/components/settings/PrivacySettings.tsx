import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RootState } from "../../store";
import { useUpdateUserInfoMutation } from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import { ArrowLeft, Eye, Clock, MessageSquare, MapPin, Calendar, Save } from "lucide-react";

interface ToggleProps {
  label: string;
  description: string;
  value: boolean;
  onChange: (value: boolean) => void;
  icon: React.ReactNode;
}

const Toggle: React.FC<ToggleProps> = ({ label, description, value, onChange, icon }) => (
  <div className="flex items-center justify-between p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 mb-3">
    <div className="flex items-center gap-4">
      <div className="p-2 rounded-lg bg-gradient-to-br from-teal-400 to-teal-600">
        <span className="text-white">{icon}</span>
      </div>
      <div>
        <p className="font-medium text-gray-800">{label}</p>
        <p className="text-sm text-gray-500">{description}</p>
      </div>
    </div>
    <button
      onClick={() => onChange(!value)}
      className={`relative w-14 h-7 rounded-full transition-colors duration-200 ${
        value ? "bg-teal-500" : "bg-gray-300"
      }`}
    >
      <span
        className={`absolute top-1 w-5 h-5 bg-white rounded-full shadow-md transition-transform duration-200 ${
          value ? "translate-x-8" : "translate-x-1"
        }`}
      />
    </button>
  </div>
);

const PrivacySettings: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const user = userInfo?.user;
  const [updateUserInfo, { isLoading }] = useUpdateUserInfoMutation();

  const [settings, setSettings] = useState({
    showOnlineStatus: user?.privacySettings?.showOnlineStatus ?? true,
    showCity: user?.privacySettings?.showCity ?? true,
    showCountryRegion: user?.privacySettings?.showCountryRegion ?? true,
    showAge: user?.privacySettings?.showAge ?? true,
    showZodiac: user?.privacySettings?.showZodiac ?? true,
    showGiftingLevel: user?.privacySettings?.showGiftingLevel ?? true,
    birthdayNotification: user?.privacySettings?.birthdayNotification ?? true,
  });

  const [hasChanges, setHasChanges] = useState(false);

  useEffect(() => {
    if (user?.privacySettings) {
      setSettings({
        showOnlineStatus: user.privacySettings.showOnlineStatus ?? true,
        showCity: user.privacySettings.showCity ?? true,
        showCountryRegion: user.privacySettings.showCountryRegion ?? true,
        showAge: user.privacySettings.showAge ?? true,
        showZodiac: user.privacySettings.showZodiac ?? true,
        showGiftingLevel: user.privacySettings.showGiftingLevel ?? true,
        birthdayNotification: user.privacySettings.birthdayNotification ?? true,
      });
    }
  }, [user]);

  const handleToggle = (key: keyof typeof settings) => (value: boolean) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
    setHasChanges(true);
  };

  const handleSave = async () => {
    try {
      await updateUserInfo({
        privacySettings: settings,
      }).unwrap();
      toast.success(t("settings.privacy.saveSuccess") || "Privacy settings saved", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setHasChanges(false);
    } catch (error) {
      toast.error(t("settings.privacy.saveError") || "Failed to save settings", {
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
              {t("settings.privacy.title") || "Privacy Settings"}
            </h1>
            <p className="text-teal-100 text-sm">
              {t("settings.privacy.subtitle") || "Control who can see your information"}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {/* Profile Visibility */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.privacy.profileVisibility") || "Profile Visibility"}
          </h3>

          <Toggle
            icon={<Eye className="w-5 h-5" />}
            label={t("settings.privacy.showOnlineStatus") || "Show Online Status"}
            description={t("settings.privacy.showOnlineStatusDesc") || "Let others see when you're online"}
            value={settings.showOnlineStatus}
            onChange={handleToggle("showOnlineStatus")}
          />

          <Toggle
            icon={<MapPin className="w-5 h-5" />}
            label={t("settings.privacy.showCity") || "Show City"}
            description={t("settings.privacy.showCityDesc") || "Display your city on your profile"}
            value={settings.showCity}
            onChange={handleToggle("showCity")}
          />

          <Toggle
            icon={<MapPin className="w-5 h-5" />}
            label={t("settings.privacy.showCountry") || "Show Country/Region"}
            description={t("settings.privacy.showCountryDesc") || "Display your country on your profile"}
            value={settings.showCountryRegion}
            onChange={handleToggle("showCountryRegion")}
          />
        </div>

        {/* Personal Info */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.privacy.personalInfo") || "Personal Information"}
          </h3>

          <Toggle
            icon={<Calendar className="w-5 h-5" />}
            label={t("settings.privacy.showAge") || "Show Age"}
            description={t("settings.privacy.showAgeDesc") || "Display your age on your profile"}
            value={settings.showAge}
            onChange={handleToggle("showAge")}
          />

          <Toggle
            icon={<Clock className="w-5 h-5" />}
            label={t("settings.privacy.showZodiac") || "Show Zodiac Sign"}
            description={t("settings.privacy.showZodiacDesc") || "Display your zodiac sign"}
            value={settings.showZodiac}
            onChange={handleToggle("showZodiac")}
          />

          <Toggle
            icon={<Calendar className="w-5 h-5" />}
            label={t("settings.privacy.birthdayNotification") || "Birthday Notifications"}
            description={t("settings.privacy.birthdayNotificationDesc") || "Allow others to be notified on your birthday"}
            value={settings.birthdayNotification}
            onChange={handleToggle("birthdayNotification")}
          />
        </div>

        {/* Communication */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.privacy.communication") || "Communication"}
          </h3>

          <Toggle
            icon={<MessageSquare className="w-5 h-5" />}
            label={t("settings.privacy.showGiftingLevel") || "Show Gifting Level"}
            description={t("settings.privacy.showGiftingLevelDesc") || "Display your gifting level badge"}
            value={settings.showGiftingLevel}
            onChange={handleToggle("showGiftingLevel")}
          />
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
              ? t("settings.privacy.saving") || "Saving..."
              : t("settings.privacy.saveChanges") || "Save Changes"}
          </button>
        )}
      </div>
    </div>
  );
};

export default PrivacySettings;
