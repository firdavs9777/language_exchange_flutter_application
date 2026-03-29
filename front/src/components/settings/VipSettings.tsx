import React from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RootState } from "../../store";
import { useGetVipStatusQuery } from "../../store/slices/usersSlice";
import {
  ArrowLeft,
  Crown,
  Check,
  X,
  MessageSquare,
  Eye,
  Search,
  Ban,
  Headphones,
  Award,
  Sparkles,
  Zap,
} from "lucide-react";

interface FeatureItemProps {
  icon: React.ReactNode;
  label: string;
  included: boolean;
}

const FeatureItem: React.FC<FeatureItemProps> = ({ icon, label, included }) => (
  <div className="flex items-center gap-3 py-3">
    <div className={`p-2 rounded-lg ${included ? "bg-teal-100 text-teal-600" : "bg-gray-100 text-gray-400"}`}>
      {icon}
    </div>
    <span className={`flex-1 ${included ? "text-gray-800" : "text-gray-400"}`}>{label}</span>
    {included ? (
      <Check className="w-5 h-5 text-teal-500" />
    ) : (
      <X className="w-5 h-5 text-gray-300" />
    )}
  </div>
);

const VipSettings: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const user = userInfo?.user;
  const userId = user?._id;

  const { data: vipData, isLoading } = useGetVipStatusQuery(userId || "", {
    skip: !userId,
  });

  const isVip = user?.userMode === "vip" || vipData?.data?.isActive;

  const freeFeatures = [
    { icon: <MessageSquare className="w-5 h-5" />, label: t("vip.features.limitedMessages") || "Limited messages per day", included: true },
    { icon: <Eye className="w-5 h-5" />, label: t("vip.features.basicProfile") || "Basic profile", included: true },
    { icon: <Search className="w-5 h-5" />, label: t("vip.features.basicSearch") || "Basic search", included: true },
  ];

  const vipFeatures = [
    { icon: <MessageSquare className="w-5 h-5" />, label: t("vip.features.unlimitedMessages") || "Unlimited messages", included: true },
    { icon: <Eye className="w-5 h-5" />, label: t("vip.features.seeProfileVisitors") || "See who visited your profile", included: true },
    { icon: <Search className="w-5 h-5" />, label: t("vip.features.advancedFilters") || "Advanced search filters", included: true },
    { icon: <Ban className="w-5 h-5" />, label: t("vip.features.noAds") || "Ad-free experience", included: true },
    { icon: <Headphones className="w-5 h-5" />, label: t("vip.features.prioritySupport") || "Priority support", included: true },
    { icon: <Award className="w-5 h-5" />, label: t("vip.features.exclusiveBadge") || "Exclusive VIP badge", included: true },
    { icon: <Sparkles className="w-5 h-5" />, label: t("vip.features.translationFeature") || "Message translation", included: true },
  ];

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-yellow-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-teal-500 border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-indigo-900 to-teal-900">
      {/* Header */}
      <div className="p-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors text-white"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-white">
              {t("vip.title") || "VIP Membership"}
            </h1>
            <p className="text-purple-200 text-sm">
              {t("vip.subtitle") || "Unlock premium features"}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 pb-8 max-w-2xl mx-auto">
        {/* Current Status Card */}
        <div className={`rounded-2xl p-6 mb-6 ${
          isVip
            ? "bg-gradient-to-r from-yellow-400 to-orange-500"
            : "bg-white/10 backdrop-blur-xl border border-white/20"
        }`}>
          <div className="flex items-center gap-4">
            <div className={`p-4 rounded-full ${isVip ? "bg-white/20" : "bg-white/10"}`}>
              <Crown className={`w-8 h-8 ${isVip ? "text-white" : "text-yellow-400"}`} />
            </div>
            <div>
              <h2 className={`text-xl font-bold ${isVip ? "text-white" : "text-white"}`}>
                {isVip
                  ? t("vip.status.active") || "VIP Active"
                  : t("vip.status.free") || "Free Plan"}
              </h2>
              <p className={`text-sm ${isVip ? "text-white/80" : "text-white/60"}`}>
                {isVip
                  ? t("vip.status.activeDesc") || "Enjoying all premium features"
                  : t("vip.status.freeDesc") || "Upgrade to unlock more features"}
              </p>
            </div>
          </div>

          {isVip && vipData?.data?.endDate && (
            <div className="mt-4 pt-4 border-t border-white/20">
              <p className="text-white/80 text-sm">
                {t("vip.expiresOn") || "Expires on"}: {new Date(vipData.data.endDate).toLocaleDateString()}
              </p>
            </div>
          )}
        </div>

        {/* Plans Comparison */}
        <div className="grid gap-4 md:grid-cols-2">
          {/* Free Plan */}
          <div className="bg-white/10 backdrop-blur-xl rounded-2xl p-6 border border-white/20">
            <div className="flex items-center gap-2 mb-4">
              <Zap className="w-6 h-6 text-gray-400" />
              <h3 className="text-lg font-bold text-white">{t("vip.plans.free") || "Free"}</h3>
            </div>
            <p className="text-3xl font-bold text-white mb-4">$0</p>
            <div className="border-t border-white/10 pt-4">
              {freeFeatures.map((feature, index) => (
                <FeatureItem key={index} {...feature} />
              ))}
            </div>
          </div>

          {/* VIP Plan */}
          <div className="bg-gradient-to-br from-yellow-400/20 to-orange-500/20 backdrop-blur-xl rounded-2xl p-6 border-2 border-yellow-400/50 relative overflow-hidden">
            <div className="absolute top-0 right-0 bg-yellow-400 text-black text-xs font-bold px-3 py-1 rounded-bl-lg">
              {t("vip.popular") || "POPULAR"}
            </div>
            <div className="flex items-center gap-2 mb-4">
              <Crown className="w-6 h-6 text-yellow-400" />
              <h3 className="text-lg font-bold text-white">{t("vip.plans.vip") || "VIP"}</h3>
            </div>
            <p className="text-3xl font-bold text-white mb-1">
              $9.99
              <span className="text-sm font-normal text-white/60">/{t("vip.perMonth") || "month"}</span>
            </p>
            <p className="text-yellow-400 text-sm mb-4">{t("vip.saveAnnually") || "Save 20% with annual plan"}</p>
            <div className="border-t border-white/10 pt-4">
              {vipFeatures.map((feature, index) => (
                <FeatureItem key={index} {...feature} />
              ))}
            </div>
          </div>
        </div>

        {/* Upgrade Notice - Web users must use app */}
        {!isVip && (
          <div className="mt-6 bg-white/10 backdrop-blur-xl rounded-2xl p-6 border border-white/20">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-3 bg-yellow-400/20 rounded-full">
                <Crown className="w-6 h-6 text-yellow-400" />
              </div>
              <div>
                <h3 className="text-white font-semibold">
                  {t("vip.upgradeInApp") || "Upgrade via Mobile App"}
                </h3>
                <p className="text-white/60 text-sm">
                  {t("vip.upgradeInAppDesc") || "VIP subscriptions can only be purchased through our mobile app"}
                </p>
              </div>
            </div>
            <div className="flex gap-3">
              <a
                href="https://apps.apple.com/app/bananatalk"
                target="_blank"
                rel="noopener noreferrer"
                className="flex-1 bg-black text-white py-3 rounded-xl font-medium text-center hover:bg-gray-900 transition-colors flex items-center justify-center gap-2"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                </svg>
                App Store
              </a>
              <a
                href="https://play.google.com/store/apps/details?id=com.bananatalk"
                target="_blank"
                rel="noopener noreferrer"
                className="flex-1 bg-black text-white py-3 rounded-xl font-medium text-center hover:bg-gray-900 transition-colors flex items-center justify-center gap-2"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z"/>
                </svg>
                Play Store
              </a>
            </div>
          </div>
        )}

        {/* VIP Status Info */}
        {isVip && (
          <div className="mt-6 bg-white/10 backdrop-blur-xl rounded-2xl p-6 border border-white/20">
            <p className="text-white/80 text-sm text-center">
              {t("vip.manageInApp") || "To manage your subscription, please use the BananaTalk mobile app."}
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default VipSettings;
