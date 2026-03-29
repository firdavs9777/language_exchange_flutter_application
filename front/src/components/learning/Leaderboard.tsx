import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RootState } from "../../store";
import { useGetLeaderboardQuery } from "../../store/slices/learningSlice";
import {
  ArrowLeft,
  Trophy,
  Medal,
  Crown,
  Zap,
  TrendingUp,
  Loader2,
} from "lucide-react";

interface LeaderboardUser {
  _id: string;
  name: string;
  imageUrls?: string[];
  totalXP: number;
  level: number;
  rank: number;
  currentStreak: number;
}

const Leaderboard: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const currentUserId = userInfo?.user?._id;

  const [timeRange, setTimeRange] = useState<"weekly" | "monthly" | "allTime">("weekly");

  const { data, isLoading } = useGetLeaderboardQuery({ timeRange });
  const leaderboard: LeaderboardUser[] = Array.isArray(data?.data) ? data.data : [];

  const currentUserRank = leaderboard.find((u) => u._id === currentUserId);

  const getRankIcon = (rank: number) => {
    switch (rank) {
      case 1:
        return <Crown className="w-6 h-6 text-yellow-500" />;
      case 2:
        return <Medal className="w-6 h-6 text-gray-400" />;
      case 3:
        return <Medal className="w-6 h-6 text-amber-600" />;
      default:
        return (
          <span className="w-6 h-6 flex items-center justify-center text-gray-500 font-bold">
            {rank}
          </span>
        );
    }
  };

  const getRankBg = (rank: number) => {
    switch (rank) {
      case 1:
        return "bg-gradient-to-r from-yellow-100 to-amber-100 border-yellow-300";
      case 2:
        return "bg-gradient-to-r from-gray-100 to-slate-100 border-gray-300";
      case 3:
        return "bg-gradient-to-r from-amber-50 to-orange-50 border-amber-300";
      default:
        return "bg-white/60 border-white/30";
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-900 via-indigo-900 to-purple-900 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-white animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-900 via-indigo-900 to-purple-900">
      {/* Header */}
      <div className="p-6 pb-8">
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors text-white"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-white">
              {t("learning.leaderboard.title") || "Leaderboard"}
            </h1>
            <p className="text-blue-200 text-sm">
              {t("learning.leaderboard.subtitle") || "See how you rank"}
            </p>
          </div>
        </div>

        {/* Time Range Tabs */}
        <div className="flex gap-2 bg-white/10 p-1 rounded-xl">
          {[
            { key: "weekly", label: t("learning.leaderboard.weekly") || "Weekly" },
            { key: "monthly", label: t("learning.leaderboard.monthly") || "Monthly" },
            { key: "allTime", label: t("learning.leaderboard.allTime") || "All Time" },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setTimeRange(tab.key as typeof timeRange)}
              className={`flex-1 py-2 rounded-lg font-medium transition-colors ${
                timeRange === tab.key
                  ? "bg-white text-blue-900"
                  : "text-white/70 hover:text-white"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Top 3 Podium */}
      {leaderboard.length >= 3 && (
        <div className="px-6 mb-6">
          <div className="flex items-end justify-center gap-4">
            {/* 2nd Place */}
            <div className="flex flex-col items-center">
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-gray-300 to-gray-400 border-4 border-gray-400 overflow-hidden mb-2">
                {leaderboard[1]?.imageUrls?.[0] ? (
                  <img
                    src={leaderboard[1].imageUrls[0]}
                    alt={leaderboard[1].name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-gray-500 text-white text-xl font-bold">
                    {leaderboard[1]?.name?.[0]}
                  </div>
                )}
              </div>
              <Medal className="w-6 h-6 text-gray-400 mb-1" />
              <p className="text-white font-medium text-sm truncate max-w-[80px]">
                {leaderboard[1]?.name}
              </p>
              <p className="text-yellow-400 text-sm font-bold">{leaderboard[1]?.totalXP} XP</p>
              <div className="bg-gray-400/50 w-20 h-16 rounded-t-lg mt-2" />
            </div>

            {/* 1st Place */}
            <div className="flex flex-col items-center -mt-6">
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-yellow-300 to-amber-400 border-4 border-yellow-400 overflow-hidden mb-2 shadow-lg">
                {leaderboard[0]?.imageUrls?.[0] ? (
                  <img
                    src={leaderboard[0].imageUrls[0]}
                    alt={leaderboard[0].name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-yellow-500 text-white text-2xl font-bold">
                    {leaderboard[0]?.name?.[0]}
                  </div>
                )}
              </div>
              <Crown className="w-8 h-8 text-yellow-400 mb-1" />
              <p className="text-white font-bold truncate max-w-[100px]">{leaderboard[0]?.name}</p>
              <p className="text-yellow-400 font-bold">{leaderboard[0]?.totalXP} XP</p>
              <div className="bg-yellow-400/50 w-24 h-24 rounded-t-lg mt-2" />
            </div>

            {/* 3rd Place */}
            <div className="flex flex-col items-center">
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-amber-500 to-orange-500 border-4 border-amber-600 overflow-hidden mb-2">
                {leaderboard[2]?.imageUrls?.[0] ? (
                  <img
                    src={leaderboard[2].imageUrls[0]}
                    alt={leaderboard[2].name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-amber-600 text-white text-xl font-bold">
                    {leaderboard[2]?.name?.[0]}
                  </div>
                )}
              </div>
              <Medal className="w-6 h-6 text-amber-600 mb-1" />
              <p className="text-white font-medium text-sm truncate max-w-[80px]">
                {leaderboard[2]?.name}
              </p>
              <p className="text-yellow-400 text-sm font-bold">{leaderboard[2]?.totalXP} XP</p>
              <div className="bg-amber-600/50 w-20 h-12 rounded-t-lg mt-2" />
            </div>
          </div>
        </div>
      )}

      {/* Full List */}
      <div className="bg-gradient-to-br from-blue-50 via-white to-purple-50 rounded-t-3xl min-h-[40vh] px-4 py-6">
        {/* Current User Position */}
        {currentUserRank && currentUserRank.rank > 3 && (
          <div className="mb-4">
            <p className="text-sm text-gray-500 mb-2">
              {t("learning.leaderboard.yourPosition") || "Your Position"}
            </p>
            <div className="flex items-center gap-4 p-4 bg-gradient-to-r from-teal-100 to-blue-100 border-2 border-teal-300 rounded-xl">
              <span className="w-8 h-8 flex items-center justify-center bg-teal-500 text-white rounded-full font-bold">
                {currentUserRank.rank}
              </span>
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 overflow-hidden">
                {currentUserRank.imageUrls?.[0] ? (
                  <img
                    src={currentUserRank.imageUrls[0]}
                    alt={currentUserRank.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-white font-bold">
                    {currentUserRank.name?.[0]}
                  </div>
                )}
              </div>
              <div className="flex-1">
                <p className="font-semibold text-gray-800">{currentUserRank.name}</p>
                <p className="text-sm text-gray-500">Level {currentUserRank.level}</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-teal-600 flex items-center gap-1">
                  <Zap className="w-4 h-4" />
                  {currentUserRank.totalXP} XP
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Rankings List */}
        <div className="space-y-2">
          {leaderboard.slice(3).map((user) => (
            <div
              key={user._id}
              className={`flex items-center gap-4 p-4 rounded-xl border backdrop-blur-sm ${
                user._id === currentUserId
                  ? "bg-teal-50 border-teal-300"
                  : getRankBg(user.rank)
              }`}
            >
              {getRankIcon(user.rank)}
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-gray-300 to-gray-400 overflow-hidden">
                {user.imageUrls?.[0] ? (
                  <img
                    src={user.imageUrls[0]}
                    alt={user.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-white font-bold">
                    {user.name?.[0]}
                  </div>
                )}
              </div>
              <div className="flex-1">
                <p className="font-medium text-gray-800">{user.name}</p>
                <p className="text-xs text-gray-500">Level {user.level}</p>
              </div>
              <div className="text-right">
                <p className="font-semibold text-gray-800 flex items-center gap-1">
                  <Zap className="w-4 h-4 text-yellow-500" />
                  {user.totalXP}
                </p>
                {user.currentStreak > 0 && (
                  <p className="text-xs text-orange-500 flex items-center gap-1">
                    <TrendingUp className="w-3 h-3" />
                    {user.currentStreak} day streak
                  </p>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Leaderboard;
