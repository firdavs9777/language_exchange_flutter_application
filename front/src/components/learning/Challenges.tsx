import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetChallengesQuery,
  useJoinChallengeMutation,
} from "../../store/slices/learningSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Trophy,
  Users,
  Clock,
  Zap,
  ChevronRight,
  Loader2,
  Target,
  Calendar,
  Star,
  Flame,
} from "lucide-react";

interface Challenge {
  _id: string;
  title: string;
  description: string;
  type: "daily" | "weekly" | "special";
  xpReward: number;
  participantsCount: number;
  startDate: string;
  endDate: string;
  goal: number;
  progress?: number;
  isJoined: boolean;
  leaderboard?: {
    _id: string;
    name: string;
    imageUrls?: string[];
    score: number;
  }[];
}

const TYPE_CONFIG = {
  daily: {
    bg: "bg-gradient-to-r from-green-500 to-teal-500",
    badge: "bg-green-100 text-green-700",
    label: "Daily",
  },
  weekly: {
    bg: "bg-gradient-to-r from-blue-500 to-indigo-500",
    badge: "bg-blue-100 text-blue-700",
    label: "Weekly",
  },
  special: {
    bg: "bg-gradient-to-r from-purple-500 to-pink-500",
    badge: "bg-purple-100 text-purple-700",
    label: "Special",
  },
};

const Challenges: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { data, isLoading, refetch } = useGetChallengesQuery({});
  const [joinChallenge, { isLoading: isJoining }] = useJoinChallengeMutation();

  const challenges: Challenge[] = Array.isArray(data?.data) ? data.data : [];

  const activeChallenges = challenges.filter((c) => c.isJoined);
  const availableChallenges = challenges.filter((c) => !c.isJoined);

  const handleJoin = async (challengeId: string) => {
    try {
      await joinChallenge(challengeId).unwrap();
      toast.success(t("learning.challenges.joinSuccess") || "Joined challenge!", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      refetch();
    } catch (error) {
      toast.error(t("learning.challenges.joinError") || "Failed to join challenge", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const getTimeRemaining = (endDate: string) => {
    const end = new Date(endDate);
    const now = new Date();
    const diff = end.getTime() - now.getTime();

    if (diff <= 0) return "Ended";

    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));

    if (days > 0) return `${days}d ${hours}h`;
    return `${hours}h`;
  };

  const ChallengeCard: React.FC<{ challenge: Challenge; showJoinButton?: boolean }> = ({
    challenge,
    showJoinButton = false,
  }) => {
    const config = TYPE_CONFIG[challenge.type];
    const progressPercent = challenge.progress
      ? Math.min((challenge.progress / challenge.goal) * 100, 100)
      : 0;

    return (
      <div className="bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 overflow-hidden">
        <div className={`${config.bg} p-4 text-white`}>
          <div className="flex items-center justify-between mb-2">
            <span className={`px-2 py-0.5 rounded-full text-xs ${config.badge}`}>
              {config.label}
            </span>
            <span className="flex items-center gap-1 text-sm">
              <Clock className="w-4 h-4" />
              {getTimeRemaining(challenge.endDate)}
            </span>
          </div>
          <h3 className="font-bold text-lg">{challenge.title}</h3>
          <p className="text-white/80 text-sm">{challenge.description}</p>
        </div>

        <div className="p-4">
          <div className="flex items-center justify-between mb-3">
            <span className="flex items-center gap-2 text-sm text-gray-500">
              <Users className="w-4 h-4" />
              {challenge.participantsCount} participants
            </span>
            <span className="flex items-center gap-1 text-yellow-600 font-medium">
              <Zap className="w-4 h-4" />+{challenge.xpReward} XP
            </span>
          </div>

          {challenge.isJoined && (
            <div className="mb-4">
              <div className="flex items-center justify-between text-sm text-gray-600 mb-1">
                <span>{t("learning.challenges.progress") || "Progress"}</span>
                <span>
                  {challenge.progress || 0} / {challenge.goal}
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                <div
                  className={`h-full rounded-full ${config.bg}`}
                  style={{ width: `${progressPercent}%` }}
                />
              </div>
            </div>
          )}

          {/* Mini Leaderboard */}
          {challenge.isJoined && challenge.leaderboard && challenge.leaderboard.length > 0 && (
            <div className="mb-4 pt-3 border-t">
              <p className="text-sm text-gray-500 mb-2">
                {t("learning.challenges.topParticipants") || "Top Participants"}
              </p>
              <div className="space-y-2">
                {challenge.leaderboard.slice(0, 3).map((user, index) => (
                  <div key={user._id} className="flex items-center gap-2">
                    <span className="w-5 text-center text-sm font-medium text-gray-400">
                      {index + 1}
                    </span>
                    <div className="w-6 h-6 rounded-full bg-gray-200 overflow-hidden">
                      {user.imageUrls?.[0] ? (
                        <img
                          src={user.imageUrls[0]}
                          alt={user.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-xs text-gray-400">
                          {user.name?.[0]}
                        </div>
                      )}
                    </div>
                    <span className="flex-1 text-sm text-gray-700 truncate">{user.name}</span>
                    <span className="text-sm text-gray-500">{user.score}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {showJoinButton && !challenge.isJoined && (
            <button
              onClick={() => handleJoin(challenge._id)}
              disabled={isJoining}
              className="w-full py-3 bg-gradient-to-r from-teal-500 to-green-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all disabled:opacity-50"
            >
              {isJoining
                ? t("learning.challenges.joining") || "Joining..."
                : t("learning.challenges.join") || "Join Challenge"}
            </button>
          )}

          {challenge.isJoined && (
            <button
              onClick={() => navigate(`/learn/challenges/${challenge._id}`)}
              className="w-full flex items-center justify-center gap-2 py-3 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200 transition-colors"
            >
              {t("learning.challenges.viewDetails") || "View Details"}
              <ChevronRight className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    );
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-50 via-white to-orange-50 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-red-500 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-50 via-white to-orange-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-red-500 to-orange-500 text-white p-6 pb-8">
        <div className="flex items-center gap-4 mb-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold">
              {t("learning.challenges.title") || "Challenges"}
            </h1>
            <p className="text-red-100 text-sm">
              {t("learning.challenges.subtitle") || "Compete and earn rewards"}
            </p>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="flex gap-4">
          <div className="flex-1 bg-white/20 rounded-xl p-3 text-center">
            <Flame className="w-6 h-6 mx-auto mb-1" />
            <p className="text-lg font-bold">{activeChallenges.length}</p>
            <p className="text-xs text-red-100">Active</p>
          </div>
          <div className="flex-1 bg-white/20 rounded-xl p-3 text-center">
            <Target className="w-6 h-6 mx-auto mb-1" />
            <p className="text-lg font-bold">{availableChallenges.length}</p>
            <p className="text-xs text-red-100">Available</p>
          </div>
          <div className="flex-1 bg-white/20 rounded-xl p-3 text-center">
            <Trophy className="w-6 h-6 mx-auto mb-1" />
            <p className="text-lg font-bold">0</p>
            <p className="text-xs text-red-100">Won</p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {/* Active Challenges */}
        {activeChallenges.length > 0 && (
          <div className="mb-8">
            <h2 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
              <Flame className="w-5 h-5 text-orange-500" />
              {t("learning.challenges.active") || "Active Challenges"}
            </h2>
            <div className="space-y-4">
              {activeChallenges.map((challenge) => (
                <ChallengeCard key={challenge._id} challenge={challenge} />
              ))}
            </div>
          </div>
        )}

        {/* Available Challenges */}
        <div>
          <h2 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
            <Star className="w-5 h-5 text-yellow-500" />
            {t("learning.challenges.available") || "Available Challenges"}
          </h2>

          {availableChallenges.length === 0 ? (
            <div className="text-center py-12">
              <div className="p-4 rounded-full bg-gray-100 w-fit mx-auto mb-4">
                <Trophy className="w-8 h-8 text-gray-400" />
              </div>
              <p className="text-gray-500">
                {t("learning.challenges.noChallenges") || "No challenges available right now"}
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {availableChallenges.map((challenge) => (
                <ChallengeCard key={challenge._id} challenge={challenge} showJoinButton />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Challenges;
