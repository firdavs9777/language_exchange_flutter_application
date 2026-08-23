import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetFollowersQuery,
  useGetFollowingsQuery,
  useGetUserProfileQuery,
  useGetProfileVisitorsQuery,
  useGetVipStatusQuery,
} from "../../store/slices/usersSlice";
import { useGetMyMomentsQuery } from "../../store/slices/momentsSlice";
import { MomentType } from "../moments/types";
import { FollowerInterface, UserProfileData } from "./ProfileTypes/types";

import ProfileHeader from "./parts/ProfileHeader";
import StatsRow from "./parts/StatsRow";
import ProfileTabs from "./parts/ProfileTabs";
import AboutCard from "./parts/AboutCard";
import LanguagesCard from "./parts/LanguagesCard";
import PersonalityCard from "./parts/PersonalityCard";
import TopicsCard from "./parts/TopicsCard";
import PhotoGrid from "./parts/PhotoGrid";
import MyMoments from "./MyMoments";
import AdUnit from "../ads/AdUnit";
import { AD_SLOTS } from "../ads/adsenseConfig";

interface Moment {
  count: number;
  success: string;
  data: MomentType[];
}

const PAGE_WRAPPER =
  "min-h-screen bg-gradient-to-br from-teal-50 via-white to-yellow-50 dark:from-gray-900 dark:via-gray-900 dark:to-gray-800";

const ProfileScreen: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const userId = useSelector((state: any) => state.auth.userInfo?.user?._id);
  const userMode = useSelector(
    (state: any) => state.auth.userInfo?.user?.userMode
  );

  // API Queries
  const { data, isLoading, error } = useGetUserProfileQuery({});
  const { data: followers } = useGetFollowersQuery({ userId });
  const { data: followings } = useGetFollowingsQuery({ userId });
  const { data: moments } = useGetMyMomentsQuery({ userId });

  // VIP status
  const { data: vipData } = useGetVipStatusQuery(userId || "", {
    skip: !userId,
  });
  const isVip = userMode === "vip" || (vipData as any)?.data?.isActive;

  const { data: visitors } = useGetProfileVisitorsQuery(
    { userId: userId || "", page: 1, limit: 1 },
    { skip: !userId || !isVip }
  );

  // Local UI state
  const [activeTab, setActiveTab] = useState<string>("overview");

  // Derived data
  const user = (data?.data ?? {}) as UserProfileData;
  const followersData = followers as FollowerInterface;
  const followingsData = followings as FollowerInterface;
  const momentsData = moments as Moment;

  const imageUrls = user.imageUrls || [];
  const username =
    user.username || user.name?.toLowerCase().replace(/\s+/g, "") || "";

  const birthday =
    user.birth_day && user.birth_month && user.birth_year
      ? `${user.birth_day} ${t("profile.labels.of")} ${new Date(
          Number(user.birth_year),
          Number(user.birth_month) - 1
        ).toLocaleString("en-US", { month: "long" })}, ${user.birth_year}`
      : undefined;

  const location =
    typeof user.location === "string" ? user.location : undefined;

  const followersCount = Number(followersData?.count) || 0;
  const followingsCount = Number(followingsData?.count) || 0;
  const momentsCount = momentsData?.count ?? momentsData?.data?.length ?? 0;
  const visitorsCount = (visitors as any)?.count || 0;

  // Loading state
  if (isLoading) {
    return (
      <div className={PAGE_WRAPPER}>
        <div className="max-w-2xl mx-auto p-4 space-y-4 animate-pulse">
          <div className="h-44 rounded-2xl bg-gray-200 dark:bg-gray-700/60" />
          <div className="h-20 rounded-2xl bg-gray-200 dark:bg-gray-700/60" />
          <div className="h-12 rounded-full bg-gray-200 dark:bg-gray-700/60" />
          <div className="h-40 rounded-2xl bg-gray-200 dark:bg-gray-700/60" />
          <div className="h-40 rounded-2xl bg-gray-200 dark:bg-gray-700/60" />
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className={`${PAGE_WRAPPER} flex items-center justify-center`}>
        <div className="m-4 px-5 py-4 rounded-2xl bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-300 border border-red-100 dark:border-red-800">
          {t("profile.messages.error_loading_profile")}
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className={`${PAGE_WRAPPER} flex items-center justify-center`}>
        <div className="m-4 px-5 py-4 rounded-2xl bg-amber-50 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300 border border-amber-100 dark:border-amber-800">
          {t("profile.messages.no_profile_data")}
        </div>
      </div>
    );
  }

  return (
    <div className={PAGE_WRAPPER}>
      <div className="max-w-2xl mx-auto p-4 pb-20 space-y-4">
        <ProfileHeader
          name={user.name}
          username={username}
          avatarUrl={imageUrls[0]}
          isOnline={user.isOnline}
          onEdit={() => navigate("/profile/edit")}
        />

        <StatsRow
          followers={followersCount}
          following={followingsCount}
          moments={momentsCount}
          visitors={visitorsCount}
          isVip={isVip}
          onFollowers={() => navigate("/followersList")}
          onFollowing={() => navigate("/followingsList")}
          onVisitors={() => navigate("/visitors")}
        />

        <ProfileTabs active={activeTab} onChange={setActiveTab} />

        {activeTab === "overview" && (
          <div className="space-y-4">
            <AboutCard
              bio={user.bio}
              gender={user.gender}
              birthday={birthday}
              location={location}
            />
            <LanguagesCard
              native={user.native_language}
              learning={user.language_to_learn}
              level={user.languageLevel}
            />
            <PersonalityCard mbti={user.mbti} bloodType={user.bloodType} />
            <TopicsCard topics={user.topics} />
            {imageUrls.length > 0 && (
              <PhotoGrid images={imageUrls} mode="view" />
            )}
            <AdUnit slot={AD_SLOTS.profile} className="my-4" />
          </div>
        )}

        {activeTab === "moments" && <MyMoments />}

        {activeTab === "about" && (
          <div className="space-y-4">
            <AboutCard
              bio={user.bio}
              gender={user.gender}
              birthday={birthday}
              location={location}
            />
            <LanguagesCard
              native={user.native_language}
              learning={user.language_to_learn}
              level={user.languageLevel}
            />
            <PersonalityCard mbti={user.mbti} bloodType={user.bloodType} />
            <TopicsCard topics={user.topics} />
          </div>
        )}
      </div>
    </div>
  );
};

export default ProfileScreen;
