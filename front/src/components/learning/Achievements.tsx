import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useGetAchievementsQuery } from "../../store/slices/learningSlice";
import {
  ArrowLeft,
  Trophy,
  Lock,
  Star,
  Flame,
  BookOpen,
  MessageSquare,
  Users,
  Zap,
  Award,
  Target,
  Calendar,
  Loader2,
} from "lucide-react";

interface Achievement {
  _id: string;
  title: string;
  description: string;
  icon: string;
  category: string;
  xpReward: number;
  unlockedAt?: string;
  progress?: number;
  requirement?: number;
}

const ICON_MAP: { [key: string]: React.ReactNode } = {
  trophy: <Trophy className="w-8 h-8" />,
  star: <Star className="w-8 h-8" />,
  flame: <Flame className="w-8 h-8" />,
  book: <BookOpen className="w-8 h-8" />,
  message: <MessageSquare className="w-8 h-8" />,
  users: <Users className="w-8 h-8" />,
  zap: <Zap className="w-8 h-8" />,
  award: <Award className="w-8 h-8" />,
  target: <Target className="w-8 h-8" />,
  calendar: <Calendar className="w-8 h-8" />,
};

const CATEGORY_COLORS: { [key: string]: string } = {
  learning: "from-purple-500 to-indigo-600",
  social: "from-pink-500 to-rose-600",
  streak: "from-orange-500 to-red-600",
  vocabulary: "from-teal-500 to-green-600",
  lessons: "from-blue-500 to-cyan-600",
  special: "from-yellow-500 to-amber-600",
};

const Achievements: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { data, isLoading } = useGetAchievementsQuery({});
  const achievements: Achievement[] = Array.isArray(data?.data) ? data.data : [];

  const unlockedCount = achievements.filter((a) => a.unlockedAt).length;
  const totalXP = achievements
    .filter((a) => a.unlockedAt)
    .reduce((sum, a) => sum + a.xpReward, 0);

  const categories = [...new Set(achievements.map((a) => a.category))];

  const AchievementCard: React.FC<{ achievement: Achievement }> = ({ achievement }) => {
    const isUnlocked = !!achievement.unlockedAt;
    const progress = achievement.progress || 0;
    const requirement = achievement.requirement || 1;
    const progressPercent = Math.min((progress / requirement) * 100, 100);
    const colorClass = CATEGORY_COLORS[achievement.category] || "from-gray-500 to-gray-600";

    return (
      <div
        className={`relative p-4 rounded-xl border transition-all duration-200 ${
          isUnlocked
            ? "bg-white/80 border-white/30 shadow-lg"
            : "bg-gray-100/50 border-gray-200/50"
        }`}
      >
        <div className="flex items-start gap-4">
          <div
            className={`p-3 rounded-xl ${
              isUnlocked
                ? `bg-gradient-to-br ${colorClass} text-white`
                : "bg-gray-200 text-gray-400"
            }`}
          >
            {isUnlocked ? (
              ICON_MAP[achievement.icon] || <Trophy className="w-8 h-8" />
            ) : (
              <Lock className="w-8 h-8" />
            )}
          </div>
          <div className="flex-1">
            <h3 className={`font-semibold ${isUnlocked ? "text-gray-800" : "text-gray-500"}`}>
              {achievement.title}
            </h3>
            <p className={`text-sm ${isUnlocked ? "text-gray-600" : "text-gray-400"}`}>
              {achievement.description}
            </p>

            {!isUnlocked && achievement.requirement && (
              <div className="mt-2">
                <div className="flex items-center justify-between text-xs text-gray-400 mb-1">
                  <span>
                    {progress} / {requirement}
                  </span>
                  <span>{Math.round(progressPercent)}%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-1.5 overflow-hidden">
                  <div
                    className={`h-full rounded-full bg-gradient-to-r ${colorClass}`}
                    style={{ width: `${progressPercent}%` }}
                  />
                </div>
              </div>
            )}

            {isUnlocked && (
              <div className="flex items-center gap-3 mt-2">
                <span className="flex items-center gap-1 text-sm text-yellow-600">
                  <Zap className="w-4 h-4" />+{achievement.xpReward} XP
                </span>
                <span className="text-xs text-gray-400">
                  {new Date(achievement.unlockedAt!).toLocaleDateString()}
                </span>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-yellow-50 via-white to-orange-50 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-yellow-500 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-yellow-50 via-white to-orange-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-yellow-500 to-orange-500 text-white p-6 pb-20">
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold">
              {t("learning.achievements.title") || "Achievements"}
            </h1>
            <p className="text-yellow-100 text-sm">
              {t("learning.achievements.subtitle") || "Your accomplishments"}
            </p>
          </div>
        </div>

        {/* Stats */}
        <div className="flex gap-4">
          <div className="flex-1 bg-white/20 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold">{unlockedCount}</p>
            <p className="text-yellow-100 text-sm">
              {t("learning.achievements.unlocked") || "Unlocked"}
            </p>
          </div>
          <div className="flex-1 bg-white/20 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold">{achievements.length}</p>
            <p className="text-yellow-100 text-sm">
              {t("learning.achievements.total") || "Total"}
            </p>
          </div>
          <div className="flex-1 bg-white/20 rounded-xl p-4 text-center">
            <p className="text-2xl font-bold">{totalXP}</p>
            <p className="text-yellow-100 text-sm">XP {t("learning.achievements.earned") || "Earned"}</p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 -mt-10 pb-8 max-w-2xl mx-auto">
        {categories.map((category) => {
          const categoryAchievements = achievements.filter((a) => a.category === category);
          const unlockedInCategory = categoryAchievements.filter((a) => a.unlockedAt).length;

          return (
            <div key={category} className="mb-8">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-bold text-gray-800 capitalize">{category}</h2>
                <span className="text-sm text-gray-500">
                  {unlockedInCategory}/{categoryAchievements.length}
                </span>
              </div>
              <div className="space-y-3">
                {categoryAchievements.map((achievement) => (
                  <AchievementCard key={achievement._id} achievement={achievement} />
                ))}
              </div>
            </div>
          );
        })}

        {achievements.length === 0 && (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-yellow-100 w-fit mx-auto mb-4">
              <Trophy className="w-8 h-8 text-yellow-500" />
            </div>
            <p className="text-gray-500">
              {t("learning.achievements.noAchievements") || "No achievements yet. Keep learning!"}
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Achievements;
