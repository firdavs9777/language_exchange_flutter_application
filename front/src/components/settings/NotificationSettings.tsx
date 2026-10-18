import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetNotificationSettingsQuery,
  useUpdateNotificationSettingsMutation,
} from "../../store/slices/usersSlice";
import notify from "../../design/notify";
import {
  ArrowLeft,
  Bell,
  MessageSquare,
  Heart,
  UserPlus,
  Mail,
  Eye,
  Save,
  BookOpen,
  Flame,
  Gift,
  Megaphone,
  Moon,
  Users,
  Smartphone,
} from "lucide-react";

interface ToggleProps {
  label: string;
  description: string;
  value: boolean;
  onChange: (value: boolean) => void;
  icon: React.ReactNode;
  disabled?: boolean;
}

const Toggle: React.FC<ToggleProps> = ({ label, description, value, onChange, icon, disabled }) => (
  <div
    className={`flex items-center justify-between p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 mb-3 ${
      disabled ? "opacity-50" : ""
    }`}
  >
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
      type="button"
      role="switch"
      aria-checked={value}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!value)}
      className={`relative w-14 h-7 rounded-full transition-colors duration-200 shrink-0 ${
        value ? "bg-teal-500" : "bg-gray-300"
      } ${disabled ? "cursor-not-allowed" : ""}`}
    >
      <span
        className={`absolute top-1 w-5 h-5 bg-white rounded-full shadow-md transition-transform duration-200 ${
          value ? "translate-x-8" : "translate-x-1"
        }`}
      />
    </button>
  </div>
);

interface TimeRowProps {
  label: string;
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
}

const TimeRow: React.FC<TimeRowProps> = ({ label, value, onChange, disabled }) => (
  <label
    className={`flex items-center justify-between p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 mb-3 ${
      disabled ? "opacity-50" : ""
    }`}
  >
    <span className="font-medium text-gray-800">{label}</span>
    <input
      type="time"
      value={value}
      disabled={disabled}
      onChange={(e) => {
        if (e.target.value) onChange(e.target.value);
      }}
      className="px-3 py-1.5 rounded-lg border border-gray-200 bg-white text-gray-800 focus:outline-none focus:ring-2 focus:ring-teal-400"
    />
  </label>
);

/**
 * The switches this page offers. All of them are push notifications on the
 * user's phone -- the web app has no push of its own -- so the page says so.
 *
 * Left out on purpose: sound, vibration and allowCalls (device and calling
 * behaviour the app owns), dailyDropHour (the app's daily-drop picker), and
 * achievement/leaderboard/learning reminders, which PUT
 * /notifications/settings does not accept.
 */
interface NotificationToggles {
  enabled: boolean;
  chatMessages: boolean;
  friendRequests: boolean;
  profileVisits: boolean;
  moments: boolean;
  followerMoments: boolean;
  streakReminders: boolean;
  vocabularyReviewReminders: boolean;
  dailyDropReminders: boolean;
  showPreview: boolean;
  announcements: boolean;
  marketing: boolean;
}

interface QuietHoursForm {
  enabled: boolean;
  start: string;
  end: string;
}

/** Stored values with the backend's schema defaults (models/User.js) filled in. */
const readToggles = (stored: any): NotificationToggles => {
  const s = stored || {};
  return {
    enabled: s.enabled ?? true,
    chatMessages: s.chatMessages ?? true,
    friendRequests: s.friendRequests ?? true,
    profileVisits: s.profileVisits ?? true,
    moments: s.moments ?? true,
    followerMoments: s.followerMoments ?? true,
    streakReminders: s.streakReminders ?? true,
    vocabularyReviewReminders: s.vocabularyReviewReminders ?? true,
    dailyDropReminders: s.dailyDropReminders ?? true,
    showPreview: s.showPreview ?? true,
    announcements: s.announcements ?? true,
    marketing: s.marketing ?? true,
  };
};

const readQuietHours = (stored: any): QuietHoursForm => {
  const q = (stored && stored.quietHours) || {};
  return {
    enabled: q.enabled ?? false,
    start: q.start || "22:00",
    end: q.end || "08:00",
  };
};

/** The browser's IANA zone, so quiet hours are read in the user's own time. */
const browserTimezone = (): string | undefined => {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || undefined;
  } catch (e) {
    return undefined;
  }
};

const NotificationSettings: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { data, isLoading: isFetching, isError, refetch } = useGetNotificationSettingsQuery(undefined);
  const [updateNotificationSettings, { isLoading }] = useUpdateNotificationSettingsMutation();

  const baseline = readToggles(data);
  const baselineQuiet = readQuietHours(data);
  const [settings, setSettings] = useState<NotificationToggles>(baseline);
  const [quiet, setQuiet] = useState<QuietHoursForm>(baselineQuiet);

  useEffect(() => {
    if (data) {
      setSettings(readToggles(data));
      setQuiet(readQuietHours(data));
    }
  }, [data]);

  // Only what moved since the last load goes to the server; the backend
  // merges per key, so untouched settings keep their stored value.
  const changedKeys = (Object.keys(settings) as Array<keyof NotificationToggles>).filter(
    (key) => settings[key] !== baseline[key]
  );
  const changedQuiet = (Object.keys(quiet) as Array<keyof QuietHoursForm>).filter(
    (key) => quiet[key] !== baselineQuiet[key]
  );
  const hasChanges = changedKeys.length > 0 || changedQuiet.length > 0;

  const handleToggle = (key: keyof NotificationToggles) => (value: boolean) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
  };

  const handleQuiet = (key: keyof QuietHoursForm) => (value: any) => {
    setQuiet((prev) => ({ ...prev, [key]: value }));
  };

  const handleSave = async () => {
    const changes: any = {};
    changedKeys.forEach((key) => {
      changes[key] = settings[key];
    });
    if (changedQuiet.length > 0) {
      const quietChanges: any = {};
      changedQuiet.forEach((key) => {
        quietChanges[key] = quiet[key];
      });
      const timezone = browserTimezone();
      if (timezone) quietChanges.timezone = timezone;
      changes.quietHours = quietChanges;
    }
    try {
      await updateNotificationSettings(changes).unwrap();
      notify.success(t("settings.notifications.saveSuccess") || "Notification settings saved");
    } catch (error) {
      notify.error(t("settings.notifications.saveError") || "Failed to save");
    }
  };

  const off = !settings.enabled;

  const sectionTitle = (text: string) => (
    <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">{text}</h3>
  );

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
              {t("settings.notifications.title") || "Notification Settings"}
            </h1>
            <p className="text-teal-100 text-sm">
              {t("settings.notifications.subtitle") || "Manage your notification preferences"}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {isFetching ? (
          <p className="text-center text-gray-500 py-12">
            {t("settings.notifications.loading") || "Loading..."}
          </p>
        ) : isError ? (
          <div className="text-center py-12">
            <p className="text-gray-600 mb-4">
              {t("settings.notifications.loadError") || "Error loading settings"}
            </p>
            <button
              onClick={() => refetch()}
              className="px-5 py-2 rounded-xl bg-teal-500 text-white font-semibold hover:bg-teal-600 transition-colors"
            >
              {t("settings.notifications.retry") || "Retry"}
            </button>
          </div>
        ) : (
          <>
            {/* What these switches control */}
            <div className="flex items-start gap-3 p-4 mb-6 rounded-xl bg-teal-50 border border-teal-100 text-sm text-teal-800">
              <Smartphone className="w-5 h-5 shrink-0 mt-0.5" />
              <p>
                {t("settings.notifications.pushNote") ||
                  "These settings control push notifications from the BananaTalk app on your phone."}
              </p>
            </div>

            {/* Master Toggle */}
            <div className="mb-6">
              <Toggle
                icon={<Bell className="w-5 h-5" />}
                label={t("settings.notifications.enableAll") || "Push Notifications"}
                description={
                  t("settings.notifications.enableAllDesc") || "Turn all notifications on or off"
                }
                value={settings.enabled}
                onChange={handleToggle("enabled")}
              />
            </div>

            {/* Notification types -- the same list, in the same order, as the app */}
            <div className="mb-6">
              {sectionTitle(t("settings.notifications.notificationTypes") || "Notification Types")}

              <Toggle
                icon={<MessageSquare className="w-5 h-5" />}
                label={t("settings.notifications.chatMessages") || "Chat Messages"}
                description={
                  t("settings.notifications.chatMessagesDesc") ||
                  "Get notified when you receive messages"
                }
                value={settings.chatMessages}
                onChange={handleToggle("chatMessages")}
                disabled={off}
              />

              <Toggle
                icon={<Heart className="w-5 h-5" />}
                label={t("settings.notifications.moments") || "Moments"}
                description={
                  t("settings.notifications.momentsDesc") || "Likes and comments on your moments"
                }
                value={settings.moments}
                onChange={handleToggle("moments")}
                disabled={off}
              />

              <Toggle
                icon={<Users className="w-5 h-5" />}
                label={t("settings.notifications.followerMoments") || "Follower Moments"}
                description={
                  t("settings.notifications.followerMomentsDesc") ||
                  "When people you follow post new moments"
                }
                value={settings.followerMoments}
                onChange={handleToggle("followerMoments")}
                disabled={off}
              />

              <Toggle
                icon={<UserPlus className="w-5 h-5" />}
                label={t("settings.notifications.friendRequests") || "New Followers"}
                description={
                  t("settings.notifications.friendRequestsDesc") || "When someone follows you"
                }
                value={settings.friendRequests}
                onChange={handleToggle("friendRequests")}
                disabled={off}
              />

              <Toggle
                icon={<Eye className="w-5 h-5" />}
                label={t("settings.notifications.profileVisits") || "Profile Visits"}
                description={
                  t("settings.notifications.profileVisitsDesc") ||
                  "When someone views your profile (VIP)"
                }
                value={settings.profileVisits}
                onChange={handleToggle("profileVisits")}
                disabled={off}
              />

              <Toggle
                icon={<Megaphone className="w-5 h-5" />}
                label={t("settings.notifications.announcements") || "Announcements"}
                description={
                  t("settings.notifications.announcementsDesc") ||
                  "News and updates from the BananaTalk team"
                }
                value={settings.announcements}
                onChange={handleToggle("announcements")}
                disabled={off}
              />

              <Toggle
                icon={<Mail className="w-5 h-5" />}
                label={t("settings.notifications.marketing") || "Marketing"}
                description={
                  t("settings.notifications.marketingDesc") || "Updates and promotional messages"
                }
                value={settings.marketing}
                onChange={handleToggle("marketing")}
                disabled={off}
              />
            </div>

            {/* Learning */}
            <div className="mb-6">
              {sectionTitle(t("settings.notifications.learning") || "Learning")}

              <Toggle
                icon={<Flame className="w-5 h-5" />}
                label={t("settings.notifications.streakReminders") || "Streak Reminders"}
                description={
                  t("settings.notifications.streakRemindersDesc") ||
                  "A reminder before your streak runs out"
                }
                value={settings.streakReminders}
                onChange={handleToggle("streakReminders")}
                disabled={off}
              />

              <Toggle
                icon={<BookOpen className="w-5 h-5" />}
                label={
                  t("settings.notifications.vocabularyReviewReminders") || "Vocabulary Review"
                }
                description={
                  t("settings.notifications.vocabularyReviewRemindersDesc") ||
                  "When words are due for review"
                }
                value={settings.vocabularyReviewReminders}
                onChange={handleToggle("vocabularyReviewReminders")}
                disabled={off}
              />

              <Toggle
                icon={<Gift className="w-5 h-5" />}
                label={t("settings.notifications.dailyDropReminders") || "Daily Lesson"}
                description={
                  t("settings.notifications.dailyDropRemindersDesc") ||
                  "When today's short vocabulary or grammar lesson is ready"
                }
                value={settings.dailyDropReminders}
                onChange={handleToggle("dailyDropReminders")}
                disabled={off}
              />
            </div>

            {/* Quiet Hours */}
            <div className="mb-6">
              {sectionTitle(t("settings.notifications.quietHours") || "Quiet Hours")}

              <Toggle
                icon={<Moon className="w-5 h-5" />}
                label={t("settings.notifications.quietHoursEnable") || "Enable Quiet Hours"}
                description={
                  t("settings.notifications.quietHoursDesc") ||
                  "Pause non-urgent notifications during a time window"
                }
                value={quiet.enabled}
                onChange={handleQuiet("enabled")}
                disabled={off}
              />

              {quiet.enabled && (
                <>
                  <TimeRow
                    label={t("settings.notifications.quietHoursStart") || "Start time"}
                    value={quiet.start}
                    onChange={handleQuiet("start")}
                    disabled={off}
                  />
                  <TimeRow
                    label={t("settings.notifications.quietHoursEnd") || "End time"}
                    value={quiet.end}
                    onChange={handleQuiet("end")}
                    disabled={off}
                  />
                </>
              )}
            </div>

            {/* Preferences */}
            <div className="mb-6">
              {sectionTitle(t("settings.notifications.preferences") || "Notification Preferences")}

              <Toggle
                icon={<Eye className="w-5 h-5" />}
                label={t("settings.notifications.showPreview") || "Show Preview"}
                description={
                  t("settings.notifications.showPreviewDesc") ||
                  "Show message preview in notifications"
                }
                value={settings.showPreview}
                onChange={handleToggle("showPreview")}
                disabled={off}
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
                  ? t("settings.notifications.saving") || "Saving..."
                  : t("settings.notifications.saveChanges") || "Save Changes"}
              </button>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default NotificationSettings;
