import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetLearningProgressQuery,
  useGetDailyGoalsQuery,
  useGetDueReviewsQuery,
  useGetAchievementsQuery,
} from "../../store/slices/learningSlice";
import {
  Flame,
  BookOpen,
  Brain,
  Trophy,
  Target,
  ChevronRight,
  Zap,
  Clock,
  Star,
  Award,
  TrendingUp,
  Loader2,
} from "lucide-react";

interface QuickActionProps {
  icon: React.ReactNode;
  title: string;
  subtitle: string;
  badge?: string | number;
  color: string;
  onClick: () => void;
}

const QuickAction: React.FC<QuickActionProps> = ({
  icon,
  title,
  subtitle,
  badge,
  color,
  onClick,
}) => (
  <button
    onClick={onClick}
    className={`relative bg-white/60 backdrop-blur-sm rounded-2xl p-6 border border-white/30 hover:shadow-lg transition-all duration-200 text-left w-full group`}
  >
    {badge && (
      <span className="absolute -top-2 -right-2 bg-red-500 text-white text-xs font-bold px-2 py-1 rounded-full">
        {badge}
      </span>
    )}
    <div className={`p-3 rounded-xl ${color} w-fit mb-4 group-hover:scale-110 transition-transform`}>
      {icon}
    </div>
    <h3 className="font-semibold text-gray-800 mb-1">{title}</h3>
    <p className="text-sm text-gray-500">{subtitle}</p>
  </button>
);

const LearningDashboard: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { data: progressData, isLoading: progressLoading } = useGetLearningProgressQuery({});
  const { data: goalsData } = useGetDailyGoalsQuery({});
  const { data: reviewsData } = useGetDueReviewsQuery({});
  const { data: achievementsData } = useGetAchievementsQuery({});

  const progress = progressData?.data || {
    currentStreak: 0,
    longestStreak: 0,
    totalXP: 0,
    level: 1,
    vocabularyCount: 0,
    lessonsCompleted: 0,
  };

  const goals = goalsData?.data || {
    dailyXP: 0,
    targetXP: 50,
    wordsLearned: 0,
    targetWords: 10,
    lessonsCompleted: 0,
    targetLessons: 1,
  };

  const dueReviews = Array.isArray(reviewsData?.data) ? reviewsData.data.length : 0;
  const recentAchievements = Array.isArray(achievementsData?.data) ? achievementsData.data.slice(0, 3) : [];

  const dailyProgress = Math.min((goals.dailyXP / goals.targetXP) * 100, 100);

  if (progressLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-900 via-indigo-900 to-teal-900 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-white animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-indigo-900 to-teal-900">
      {/* Header */}
      <div className="p-6 pb-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold text-white">
              {t("learning.dashboard.title") || "Learn"}
            </h1>
            <p className="text-purple-200">
              {t("learning.dashboard.subtitle") || "Keep up the great work!"}
            </p>
          </div>
          <div className="flex items-center gap-2 bg-yellow-400/20 px-4 py-2 rounded-full">
            <Zap className="w-5 h-5 text-yellow-400" />
            <span className="font-bold text-yellow-400">{progress.totalXP} XP</span>
          </div>
        </div>

        {/* Streak Card */}
        <div className="bg-gradient-to-r from-orange-500 to-red-500 rounded-2xl p-6 mb-6 shadow-xl">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-white/20 rounded-xl">
                <Flame className="w-8 h-8 text-white" />
              </div>
              <div>
                <p className="text-white/80 text-sm">
                  {t("learning.dashboard.currentStreak") || "Current Streak"}
                </p>
                <p className="text-3xl font-bold text-white">
                  {progress.currentStreak} {t("learning.dashboard.days") || "days"}
                </p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-white/60 text-sm">
                {t("learning.dashboard.longest") || "Longest"}
              </p>
              <p className="text-xl font-semibold text-white">{progress.longestStreak}</p>
            </div>
          </div>
        </div>

        {/* Daily Progress */}
        <div className="bg-white/10 backdrop-blur-xl rounded-2xl p-6 mb-6 border border-white/20">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <Target className="w-5 h-5 text-teal-400" />
              <span className="font-semibold text-white">
                {t("learning.dashboard.dailyGoal") || "Daily Goal"}
              </span>
            </div>
            <span className="text-teal-400 font-medium">
              {goals.dailyXP}/{goals.targetXP} XP
            </span>
          </div>
          <div className="w-full bg-white/10 rounded-full h-3 overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-teal-400 to-green-400 rounded-full transition-all duration-500"
              style={{ width: `${dailyProgress}%` }}
            />
          </div>
          {dailyProgress >= 100 && (
            <p className="text-green-400 text-sm mt-2 flex items-center gap-1">
              <Star className="w-4 h-4" />
              {t("learning.dashboard.goalComplete") || "Daily goal complete!"}
            </p>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="bg-gradient-to-br from-teal-50 via-white to-purple-50 rounded-t-3xl min-h-[50vh] px-4 py-8">
        {/* Quick Actions */}
        <h2 className="text-lg font-bold text-gray-800 mb-4">
          {t("learning.dashboard.quickActions") || "Quick Actions"}
        </h2>
        <div className="grid grid-cols-2 gap-4 mb-8">
          <QuickAction
            icon={<Brain className="w-6 h-6 text-white" />}
            title={t("learning.dashboard.review") || "Review"}
            subtitle={t("learning.dashboard.practiceWords") || "Practice vocabulary"}
            badge={dueReviews > 0 ? dueReviews : undefined}
            color="bg-gradient-to-br from-purple-500 to-indigo-600"
            onClick={() => navigate("/learn/review")}
          />
          <QuickAction
            icon={<BookOpen className="w-6 h-6 text-white" />}
            title={t("learning.dashboard.lessons") || "Lessons"}
            subtitle={t("learning.dashboard.learnNew") || "Learn new content"}
            color="bg-gradient-to-br from-teal-500 to-green-600"
            onClick={() => navigate("/learn/lessons")}
          />
          <QuickAction
            icon={<Target className="w-6 h-6 text-white" />}
            title={t("learning.dashboard.quiz") || "Quiz"}
            subtitle={t("learning.dashboard.testKnowledge") || "Test your knowledge"}
            color="bg-gradient-to-br from-orange-500 to-red-600"
            onClick={() => navigate("/learn/quizzes")}
          />
          <QuickAction
            icon={<TrendingUp className="w-6 h-6 text-white" />}
            title={t("learning.dashboard.leaderboard") || "Leaderboard"}
            subtitle={t("learning.dashboard.seeRankings") || "See rankings"}
            color="bg-gradient-to-br from-blue-500 to-cyan-600"
            onClick={() => navigate("/learn/leaderboard")}
          />
        </div>

        {/* Stats Grid */}
        <h2 className="text-lg font-bold text-gray-800 mb-4">
          {t("learning.dashboard.yourProgress") || "Your Progress"}
        </h2>
        <div className="grid grid-cols-3 gap-3 mb-8">
          <div className="bg-white/60 backdrop-blur-sm rounded-xl p-4 text-center border border-white/30">
            <p className="text-2xl font-bold text-purple-600">{progress.vocabularyCount}</p>
            <p className="text-xs text-gray-500">
              {t("learning.dashboard.words") || "Words"}
            </p>
          </div>
          <div className="bg-white/60 backdrop-blur-sm rounded-xl p-4 text-center border border-white/30">
            <p className="text-2xl font-bold text-teal-600">{progress.lessonsCompleted}</p>
            <p className="text-xs text-gray-500">
              {t("learning.dashboard.lessonsLabel") || "Lessons"}
            </p>
          </div>
          <div className="bg-white/60 backdrop-blur-sm rounded-xl p-4 text-center border border-white/30">
            <p className="text-2xl font-bold text-orange-600">Lv.{progress.level}</p>
            <p className="text-xs text-gray-500">
              {t("learning.dashboard.level") || "Level"}
            </p>
          </div>
        </div>

        {/* Quick Links */}
        <div className="space-y-3">
          <button
            onClick={() => navigate("/learn/vocabulary")}
            className="w-full flex items-center justify-between p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 hover:bg-white/80 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-purple-100">
                <BookOpen className="w-5 h-5 text-purple-600" />
              </div>
              <div className="text-left">
                <p className="font-medium text-gray-800">
                  {t("learning.dashboard.vocabulary") || "Vocabulary"}
                </p>
                <p className="text-sm text-gray-500">
                  {progress.vocabularyCount} {t("learning.dashboard.wordsLearned") || "words learned"}
                </p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <button
            onClick={() => navigate("/learn/achievements")}
            className="w-full flex items-center justify-between p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 hover:bg-white/80 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-yellow-100">
                <Trophy className="w-5 h-5 text-yellow-600" />
              </div>
              <div className="text-left">
                <p className="font-medium text-gray-800">
                  {t("learning.dashboard.achievements") || "Achievements"}
                </p>
                <p className="text-sm text-gray-500">
                  {recentAchievements.length} {t("learning.dashboard.unlocked") || "unlocked"}
                </p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <button
            onClick={() => navigate("/learn/challenges")}
            className="w-full flex items-center justify-between p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 hover:bg-white/80 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-red-100">
                <Award className="w-5 h-5 text-red-600" />
              </div>
              <div className="text-left">
                <p className="font-medium text-gray-800">
                  {t("learning.dashboard.challenges") || "Challenges"}
                </p>
                <p className="text-sm text-gray-500">
                  {t("learning.dashboard.joinChallenges") || "Join weekly challenges"}
                </p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>
        </div>
      </div>
    </div>
  );
};

export default LearningDashboard;
