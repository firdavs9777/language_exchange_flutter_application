import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RootState } from "../../store";
import { useUpdateUserInfoMutation } from "../../store/slices/usersSlice";
import { setCredentials } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Eye,
  EyeOff,
  Clock,
  MessageSquare,
  MapPin,
  Calendar,
  Save,
  BarChart3,
  Mail,
  Newspaper,
  ShieldCheck,
} from "lucide-react";
import { GA_MEASUREMENT_ID } from "../../analytics/ga";
import { useConsentChoice } from "../../analytics/useConsentChoice";
import notify from "../../design/notify";

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

/**
 * Analytics consent, in the one place a signed-in visitor looks for it. The
 * same decision the consent bar takes on a first visit, changeable here for
 * as long as the account exists -- and absent when no measurement id is
 * configured, because then nothing is being collected to withdraw.
 */
const AnalyticsRow: React.FC = () => {
  const { t } = useTranslation();
  const { state, accept, decline } = useConsentChoice();

  if (!GA_MEASUREMENT_ID) return null;

  const description =
    state === "granted"
      ? t("consent.manage.current_granted") || "Analytics cookies are on."
      : state === "denied"
      ? t("consent.manage.current_denied") || "Analytics cookies are off."
      : t("consent.manage.body") ||
        "Analytics cookies tell us which pages people find useful. Nothing else.";

  const change = (on: boolean) => {
    if (on) accept();
    else decline();
    notify.success(
      on
        ? t("consent.manage.current_granted") || "Analytics cookies are on."
        : t("consent.manage.current_denied") || "Analytics cookies are off."
    );
  };

  return (
    <div className="mb-6" data-testid="analytics-consent-row">
      <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
        {t("consent.manage.title") || "Privacy choices"}
      </h3>
      {/* The same switch as the rows above it. This one is not part of
          `settings` and is never sent to the server -- the decision lives in
          localStorage and takes effect on the spot -- so it stays outside the
          Save flow and says so by confirming immediately. */}
      <Toggle
        icon={<BarChart3 className="w-5 h-5" />}
        label={t("consent.manage.analyticsCookies") || "Analytics cookies"}
        description={description}
        value={state === "granted"}
        onChange={change}
      />
    </div>
  );
};

interface PrivacyToggles {
  showOnlineStatus: boolean;
  showCity: boolean;
  showCountryRegion: boolean;
  showAge: boolean;
  showZodiac: boolean;
  showGiftingLevel: boolean;
  birthdayNotification: boolean;
  anonymousProfileVisits: boolean;
  emailNotifications: boolean;
  weeklyDigest: boolean;
  securityAlerts: boolean;
}

/**
 * The stored privacySettings with the backend's defaults filled in
 * (models/User.js: everything on except anonymousProfileVisits).
 *
 * newMessageEmails and newFollowerEmails are left out on purpose -- the
 * backend stores them but never sends either email -- and so is
 * personalizedAds, which the web's own consent flow covers.
 */
const readSettings = (stored: any): PrivacyToggles => {
  const ps = stored || {};
  return {
    showOnlineStatus: ps.showOnlineStatus ?? true,
    showCity: ps.showCity ?? true,
    showCountryRegion: ps.showCountryRegion ?? true,
    showAge: ps.showAge ?? true,
    showZodiac: ps.showZodiac ?? true,
    showGiftingLevel: ps.showGiftingLevel ?? true,
    birthdayNotification: ps.birthdayNotification ?? true,
    anonymousProfileVisits: ps.anonymousProfileVisits ?? false,
    emailNotifications: ps.emailNotifications ?? true,
    weeklyDigest: ps.weeklyDigest ?? true,
    securityAlerts: ps.securityAlerts ?? true,
  };
};

const PrivacySettings: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const user = userInfo?.user;
  const [updateUserInfo, { isLoading }] = useUpdateUserInfoMutation();

  const baseline = readSettings(user?.privacySettings);
  const [settings, setSettings] = useState<PrivacyToggles>(baseline);

  useEffect(() => {
    if (user?.privacySettings) {
      setSettings(readSettings(user.privacySettings));
    }
  }, [user]);

  // Only what moved since the last save goes to the server; the backend merges
  // privacySettings key by key, so the untouched ones keep their stored value.
  const changedKeys = (Object.keys(settings) as Array<keyof PrivacyToggles>).filter(
    (key) => settings[key] !== baseline[key]
  );
  const hasChanges = changedKeys.length > 0;

  const handleToggle = (key: keyof PrivacyToggles) => (value: boolean) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
  };

  const handleSave = async () => {
    try {
      const changes: Partial<PrivacyToggles> = {};
      changedKeys.forEach((key) => {
        changes[key] = settings[key];
      });
      const result: any = await updateUserInfo({
        privacySettings: changes,
      }).unwrap();
      // The page reads its initial values from the stored session, so the
      // session has to learn what was saved -- otherwise reopening the page
      // shows the old switches until the next sign-in. Only privacySettings
      // moves: the token, refresh token and every other user field stay as
      // they are (setCredentials also writes the result to localStorage).
      // The server's merged object wins where it came back.
      if (userInfo && user) {
        dispatch(
          setCredentials({
            ...userInfo,
            user: {
              ...user,
              privacySettings: {
                ...(user.privacySettings || {}),
                ...changes,
                ...((result && result.user && result.user.privacySettings) || {}),
              },
            },
          })
        );
      }
      toast.success(t("settings.privacy.saveSuccess") || "Privacy settings saved", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
    } catch (error) {
      toast.error(t("settings.privacy.saveError") || "Failed to save", {
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
            description={t("settings.privacy.showOnlineStatusDesc") || "Let others see when you are online"}
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
            description={t("settings.privacy.showZodiacDesc") || "Display your zodiac sign on your profile"}
            value={settings.showZodiac}
            onChange={handleToggle("showZodiac")}
          />

          <Toggle
            icon={<Calendar className="w-5 h-5" />}
            label={t("settings.privacy.birthdayNotification") || "Birthday Notifications"}
            description={t("settings.privacy.birthdayNotificationDesc") || "Receive notifications on your birthday"}
            value={settings.birthdayNotification}
            onChange={handleToggle("birthdayNotification")}
          />
        </div>

        {/* Other Settings */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.privacy.otherSettings") || "Other Settings"}
          </h3>

          <Toggle
            icon={<MessageSquare className="w-5 h-5" />}
            label={t("settings.privacy.showGiftingLevel") || "Show Gifting Level"}
            description={t("settings.privacy.showGiftingLevelDesc") || "Display your gifting level badge"}
            value={settings.showGiftingLevel}
            onChange={handleToggle("showGiftingLevel")}
          />
        </div>

        {/* Profile Visits */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.privacy.profileVisits") || "Profile Visits"}
          </h3>

          <Toggle
            icon={<EyeOff className="w-5 h-5" />}
            label={t("settings.privacy.anonymousProfileVisits") || "Visit profiles anonymously"}
            description={
              t("settings.privacy.anonymousProfileVisitsDesc") ||
              "Your name won't appear in the visited user's recent visitors list."
            }
            value={settings.anonymousProfileVisits}
            onChange={handleToggle("anonymousProfileVisits")}
          />
        </div>

        {/* Email */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.privacy.email") || "Email"}
          </h3>

          <Toggle
            icon={<Mail className="w-5 h-5" />}
            label={t("settings.privacy.emailNotifications") || "Email Notifications"}
            description={
              t("settings.privacy.emailNotificationsDesc") || "Receive email notifications from BananaTalk"
            }
            value={settings.emailNotifications}
            onChange={handleToggle("emailNotifications")}
          />

          {/* The weekly summary is only sent while the switch above is on
              (jobs/weeklyDigestJob.js checks both), so it hides with it. */}
          {settings.emailNotifications && (
            <Toggle
              icon={<Newspaper className="w-5 h-5" />}
              label={t("settings.privacy.weeklyDigest") || "Weekly Summary"}
              description={t("settings.privacy.weeklyDigestDesc") || "Activity recap every Sunday"}
              value={settings.weeklyDigest}
              onChange={handleToggle("weeklyDigest")}
            />
          )}

          {/* Security alerts do not depend on the switch above -- the backend
              checks securityAlerts alone -- so this row always shows. */}
          <Toggle
            icon={<ShieldCheck className="w-5 h-5" />}
            label={t("settings.privacy.securityAlerts") || "Security Alerts"}
            description={
              t("settings.privacy.securityAlertsDesc") ||
              "Password & login alerts. We recommend keeping these on."
            }
            value={settings.securityAlerts}
            onChange={handleToggle("securityAlerts")}
          />
        </div>

        <AnalyticsRow />

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
