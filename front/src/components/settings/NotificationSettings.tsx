import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RootState } from "../../store";
import { useUpdateUserInfoMutation } from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Bell,
  MessageSquare,
  Heart,
  UserPlus,
  Hand,
  Mail,
  Volume2,
  Vibrate,
  Eye,
  Save,
  Trophy,
  BookOpen,
  Flame,
} from "lucide-react";

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

const NotificationSettings: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const user = userInfo?.user;
  const [updateUserInfo, { isLoading }] = useUpdateUserInfoMutation();

  const [settings, setSettings] = useState({
    enabled: user?.notificationSettings?.enabled ?? true,
    chatMessages: user?.notificationSettings?.chatMessages ?? true,
    moments: user?.notificationSettings?.moments ?? true,
    followerMoments: user?.notificationSettings?.followerMoments ?? true,
    friendRequests: user?.notificationSettings?.friendRequests ?? true,
    profileVisits: user?.notificationSettings?.profileVisits ?? true,
    marketing: user?.notificationSettings?.marketing ?? false,
    sound: user?.notificationSettings?.sound ?? true,
    vibration: user?.notificationSettings?.vibration ?? true,
    showPreview: user?.notificationSettings?.showPreview ?? true,
    achievementNotifications: user?.notificationSettings?.achievementNotifications ?? true,
    leaderboardNotifications: user?.notificationSettings?.leaderboardNotifications ?? true,
    learningReminders: user?.notificationSettings?.learningReminders ?? true,
    streakReminders: user?.notificationSettings?.streakReminders ?? true,
  });

  const [hasChanges, setHasChanges] = useState(false);

  useEffect(() => {
    if (user?.notificationSettings) {
      setSettings({
        enabled: user.notificationSettings.enabled ?? true,
        chatMessages: user.notificationSettings.chatMessages ?? true,
        moments: user.notificationSettings.moments ?? true,
        followerMoments: user.notificationSettings.followerMoments ?? true,
        friendRequests: user.notificationSettings.friendRequests ?? true,
        profileVisits: user.notificationSettings.profileVisits ?? true,
        marketing: user.notificationSettings.marketing ?? false,
        sound: user.notificationSettings.sound ?? true,
        vibration: user.notificationSettings.vibration ?? true,
        showPreview: user.notificationSettings.showPreview ?? true,
        achievementNotifications: user.notificationSettings.achievementNotifications ?? true,
        leaderboardNotifications: user.notificationSettings.leaderboardNotifications ?? true,
        learningReminders: user.notificationSettings.learningReminders ?? true,
        streakReminders: user.notificationSettings.streakReminders ?? true,
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
        notificationSettings: settings,
      }).unwrap();
      toast.success(t("settings.notifications.saveSuccess") || "Notification settings saved", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setHasChanges(false);
    } catch (error) {
      toast.error(t("settings.notifications.saveError") || "Failed to save settings", {
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
        {/* Master Toggle */}
        <div className="mb-6">
          <Toggle
            icon={<Bell className="w-5 h-5" />}
            label={t("settings.notifications.enableAll") || "Enable Notifications"}
            description={t("settings.notifications.enableAllDesc") || "Master switch for all notifications"}
            value={settings.enabled}
            onChange={handleToggle("enabled")}
          />
        </div>

        {/* Messages & Social */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.notifications.messagesSocial") || "Messages & Social"}
          </h3>

          <Toggle
            icon={<MessageSquare className="w-5 h-5" />}
            label={t("settings.notifications.chatMessages") || "Chat Messages"}
            description={t("settings.notifications.chatMessagesDesc") || "New message notifications"}
            value={settings.chatMessages}
            onChange={handleToggle("chatMessages")}
          />

          <Toggle
            icon={<UserPlus className="w-5 h-5" />}
            label={t("settings.notifications.friendRequests") || "Friend Requests"}
            description={t("settings.notifications.friendRequestsDesc") || "New follower notifications"}
            value={settings.friendRequests}
            onChange={handleToggle("friendRequests")}
          />

          <Toggle
            icon={<Hand className="w-5 h-5" />}
            label={t("settings.notifications.waves") || "Waves"}
            description={t("settings.notifications.wavesDesc") || "When someone waves at you"}
            value={settings.profileVisits}
            onChange={handleToggle("profileVisits")}
          />
        </div>

        {/* Content */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.notifications.content") || "Content"}
          </h3>

          <Toggle
            icon={<Heart className="w-5 h-5" />}
            label={t("settings.notifications.moments") || "Moments"}
            description={t("settings.notifications.momentsDesc") || "Likes and comments on your moments"}
            value={settings.moments}
            onChange={handleToggle("moments")}
          />

          <Toggle
            icon={<Eye className="w-5 h-5" />}
            label={t("settings.notifications.followerMoments") || "Follower Moments"}
            description={t("settings.notifications.followerMomentsDesc") || "New moments from people you follow"}
            value={settings.followerMoments}
            onChange={handleToggle("followerMoments")}
          />
        </div>

        {/* Learning */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.notifications.learning") || "Learning"}
          </h3>

          <Toggle
            icon={<BookOpen className="w-5 h-5" />}
            label={t("settings.notifications.learningReminders") || "Learning Reminders"}
            description={t("settings.notifications.learningRemindersDesc") || "Daily practice reminders"}
            value={settings.learningReminders}
            onChange={handleToggle("learningReminders")}
          />

          <Toggle
            icon={<Flame className="w-5 h-5" />}
            label={t("settings.notifications.streakReminders") || "Streak Reminders"}
            description={t("settings.notifications.streakRemindersDesc") || "Don't lose your streak!"}
            value={settings.streakReminders}
            onChange={handleToggle("streakReminders")}
          />

          <Toggle
            icon={<Trophy className="w-5 h-5" />}
            label={t("settings.notifications.achievements") || "Achievements"}
            description={t("settings.notifications.achievementsDesc") || "When you unlock achievements"}
            value={settings.achievementNotifications}
            onChange={handleToggle("achievementNotifications")}
          />
        </div>

        {/* Preferences */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.notifications.preferences") || "Preferences"}
          </h3>

          <Toggle
            icon={<Volume2 className="w-5 h-5" />}
            label={t("settings.notifications.sound") || "Sound"}
            description={t("settings.notifications.soundDesc") || "Play sound for notifications"}
            value={settings.sound}
            onChange={handleToggle("sound")}
          />

          <Toggle
            icon={<Vibrate className="w-5 h-5" />}
            label={t("settings.notifications.vibration") || "Vibration"}
            description={t("settings.notifications.vibrationDesc") || "Vibrate for notifications"}
            value={settings.vibration}
            onChange={handleToggle("vibration")}
          />

          <Toggle
            icon={<Eye className="w-5 h-5" />}
            label={t("settings.notifications.showPreview") || "Show Preview"}
            description={t("settings.notifications.showPreviewDesc") || "Show message content in notifications"}
            value={settings.showPreview}
            onChange={handleToggle("showPreview")}
          />
        </div>

        {/* Marketing */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
            {t("settings.notifications.other") || "Other"}
          </h3>

          <Toggle
            icon={<Mail className="w-5 h-5" />}
            label={t("settings.notifications.marketing") || "Marketing Emails"}
            description={t("settings.notifications.marketingDesc") || "Receive promotional content"}
            value={settings.marketing}
            onChange={handleToggle("marketing")}
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
      </div>
    </div>
  );
};

export default NotificationSettings;
