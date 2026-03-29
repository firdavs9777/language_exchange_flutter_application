import React from "react";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RootState } from "../../store";
import { logout } from "../../store/slices/authSlice";
import { useLogoutUserMutation } from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import {
  User,
  Shield,
  Bell,
  Crown,
  Globe,
  HelpCircle,
  LogOut,
  ChevronRight,
  Lock,
  UserX,
  Users,
  Mail,
  MessageSquare,
} from "lucide-react";

interface SettingsItemProps {
  icon: React.ReactNode;
  label: string;
  description?: string;
  onClick: () => void;
  danger?: boolean;
}

const SettingsItem: React.FC<SettingsItemProps> = ({
  icon,
  label,
  description,
  onClick,
  danger = false,
}) => (
  <button
    onClick={onClick}
    className={`w-full flex items-center justify-between p-4 rounded-xl transition-all duration-200 ${
      danger
        ? "bg-red-50 hover:bg-red-100 text-red-600"
        : "bg-white/60 hover:bg-white/80 text-gray-800"
    } backdrop-blur-sm border border-white/30 mb-2`}
  >
    <div className="flex items-center gap-4">
      <div
        className={`p-2 rounded-lg ${
          danger ? "bg-red-100" : "bg-gradient-to-br from-teal-400 to-teal-600"
        }`}
      >
        <span className={danger ? "text-red-500" : "text-white"}>{icon}</span>
      </div>
      <div className="text-left">
        <p className="font-medium">{label}</p>
        {description && (
          <p className="text-sm text-gray-500">{description}</p>
        )}
      </div>
    </div>
    <ChevronRight className="w-5 h-5 text-gray-400" />
  </button>
);

interface SettingsSectionProps {
  title: string;
  children: React.ReactNode;
}

const SettingsSection: React.FC<SettingsSectionProps> = ({ title, children }) => (
  <div className="mb-6">
    <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3 px-1">
      {title}
    </h3>
    {children}
  </div>
);

const Settings: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const [logoutUser] = useLogoutUserMutation();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const user = userInfo?.user;

  const handleLogout = async () => {
    try {
      await logoutUser({}).unwrap();
      dispatch(logout({}));
      toast.success(t("settings.logoutSuccess") || "Logged out successfully", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      navigate("/login");
    } catch (error) {
      dispatch(logout({}));
      navigate("/login");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-yellow-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-500 to-teal-600 text-white p-6 pb-20">
        <h1 className="text-2xl font-bold">{t("settings.title") || "Settings"}</h1>
        <p className="text-teal-100 mt-1">
          {t("settings.subtitle") || "Manage your account and preferences"}
        </p>
      </div>

      {/* Content */}
      <div className="px-4 -mt-14 pb-8 max-w-2xl mx-auto">
        {/* Profile Card */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-xl border border-white/30 mb-6">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-teal-400 to-teal-600 flex items-center justify-center overflow-hidden">
              {user?.imageUrls?.[0] ? (
                <img
                  src={user.imageUrls[0]}
                  alt={user.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <User className="w-8 h-8 text-white" />
              )}
            </div>
            <div className="flex-1">
              <h2 className="text-lg font-semibold text-gray-800">
                {user?.name || "User"}
              </h2>
              <p className="text-sm text-gray-500">{user?.email}</p>
            </div>
            <button
              onClick={() => navigate("/profile/edit")}
              className="px-4 py-2 bg-teal-500 text-white rounded-lg text-sm font-medium hover:bg-teal-600 transition-colors"
            >
              {t("settings.editProfile") || "Edit"}
            </button>
          </div>
        </div>

        {/* Account Section */}
        <SettingsSection title={t("settings.sections.account") || "Account"}>
          <SettingsItem
            icon={<User className="w-5 h-5" />}
            label={t("settings.items.editProfile") || "Edit Profile"}
            description={t("settings.items.editProfileDesc") || "Update your personal information"}
            onClick={() => navigate("/profile/edit")}
          />
          <SettingsItem
            icon={<Lock className="w-5 h-5" />}
            label={t("settings.items.changePassword") || "Change Password"}
            description={t("settings.items.changePasswordDesc") || "Update your password"}
            onClick={() => navigate("/forgot-password")}
          />
          <SettingsItem
            icon={<Mail className="w-5 h-5" />}
            label={t("settings.items.emailSettings") || "Email Settings"}
            description={t("settings.items.emailSettingsDesc") || "Manage email preferences"}
            onClick={() => navigate("/settings/notifications")}
          />
        </SettingsSection>

        {/* Privacy Section */}
        <SettingsSection title={t("settings.sections.privacy") || "Privacy"}>
          <SettingsItem
            icon={<Shield className="w-5 h-5" />}
            label={t("settings.items.privacySettings") || "Privacy Settings"}
            description={t("settings.items.privacySettingsDesc") || "Control who can see your info"}
            onClick={() => navigate("/settings/privacy")}
          />
          <SettingsItem
            icon={<UserX className="w-5 h-5" />}
            label={t("settings.items.blockedUsers") || "Blocked Users"}
            description={t("settings.items.blockedUsersDesc") || "Manage blocked accounts"}
            onClick={() => navigate("/settings/blocked")}
          />
          <SettingsItem
            icon={<Users className="w-5 h-5" />}
            label={t("settings.items.closeFriends") || "Close Friends"}
            description={t("settings.items.closeFriendsDesc") || "Manage your close friends list"}
            onClick={() => navigate("/settings/close-friends")}
          />
        </SettingsSection>

        {/* Notifications Section */}
        <SettingsSection title={t("settings.sections.notifications") || "Notifications"}>
          <SettingsItem
            icon={<Bell className="w-5 h-5" />}
            label={t("settings.items.pushNotifications") || "Push Notifications"}
            description={t("settings.items.pushNotificationsDesc") || "Manage notification preferences"}
            onClick={() => navigate("/settings/notifications")}
          />
          <SettingsItem
            icon={<MessageSquare className="w-5 h-5" />}
            label={t("settings.items.chatSettings") || "Chat Settings"}
            description={t("settings.items.chatSettingsDesc") || "Message and chat preferences"}
            onClick={() => navigate("/settings/notifications")}
          />
        </SettingsSection>

        {/* VIP Section */}
        <SettingsSection title={t("settings.sections.vip") || "VIP"}>
          <SettingsItem
            icon={<Crown className="w-5 h-5" />}
            label={t("settings.items.manageSubscription") || "Manage Subscription"}
            description={
              user?.userMode === "vip"
                ? t("settings.items.vipActive") || "VIP Active"
                : t("settings.items.upgradeToPremium") || "Upgrade to premium"
            }
            onClick={() => navigate("/settings/vip")}
          />
        </SettingsSection>

        {/* Language Section */}
        <SettingsSection title={t("settings.sections.language") || "Language"}>
          <SettingsItem
            icon={<Globe className="w-5 h-5" />}
            label={t("settings.items.languageSettings") || "Language Settings"}
            description={t("settings.items.languageSettingsDesc") || "Change app and learning languages"}
            onClick={() => navigate("/settings/language")}
          />
        </SettingsSection>

        {/* Support Section */}
        <SettingsSection title={t("settings.sections.support") || "Support"}>
          <SettingsItem
            icon={<HelpCircle className="w-5 h-5" />}
            label={t("settings.items.helpCenter") || "Help Center"}
            description={t("settings.items.helpCenterDesc") || "Get help and support"}
            onClick={() => navigate("/support")}
          />
        </SettingsSection>

        {/* Logout */}
        <div className="mt-8">
          <SettingsItem
            icon={<LogOut className="w-5 h-5" />}
            label={t("settings.logout") || "Log Out"}
            onClick={handleLogout}
            danger
          />
        </div>

        {/* App Version */}
        <div className="text-center mt-8 text-gray-400 text-sm">
          <p>BananaTalk v1.0.0</p>
        </div>
      </div>
    </div>
  );
};

export default Settings;
