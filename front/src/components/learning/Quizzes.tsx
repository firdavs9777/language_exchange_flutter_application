import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useGetQuizzesQuery } from "../../store/slices/learningSlice";
import {
  ArrowLeft,
  Target,
  Clock,
  Star,
  ChevronRight,
  Loader2,
  Zap,
  Trophy,
} from "lucide-react";

interface Quiz {
  _id: string;
  title: string;
  description: string;
  category: string;
  questionCount: number;
  timeLimit: number;
  xpReward: number;
  difficulty: "easy" | "medium" | "hard";
  completedCount: number;
  bestScore?: number;
}

const DIFFICULTY_CONFIG = {
  easy: { bg: "bg-green-100", text: "text-green-600", label: "Easy" },
  medium: { bg: "bg-yellow-100", text: "text-yellow-600", label: "Medium" },
  hard: { bg: "bg-red-100", text: "text-red-600", label: "Hard" },
};

const Quizzes: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { data, isLoading } = useGetQuizzesQuery({});
  const quizzes: Quiz[] = Array.isArray(data?.data) ? data.data : [];

  const QuizCard: React.FC<{ quiz: Quiz }> = ({ quiz }) => {
    const difficultyInfo = DIFFICULTY_CONFIG[quiz.difficulty];

    return (
      <button
        onClick={() => navigate(`/learn/quizzes/${quiz._id}`)}
        className="w-full text-left p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 hover:bg-white/80 hover:shadow-lg transition-all duration-200"
      >
        <div className="flex items-start justify-between mb-3">
          <span className={`px-2 py-0.5 rounded-full text-xs ${difficultyInfo.bg} ${difficultyInfo.text}`}>
            {difficultyInfo.label}
          </span>
          {quiz.bestScore !== undefined && (
            <span className="flex items-center gap-1 text-yellow-500 text-sm">
              <Trophy className="w-4 h-4" />
              {quiz.bestScore}%
            </span>
          )}
        </div>

        <h3 className="font-semibold text-gray-800 mb-1">{quiz.title}</h3>
        <p className="text-sm text-gray-500 mb-3 line-clamp-2">{quiz.description}</p>

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4 text-sm text-gray-400">
            <span className="flex items-center gap-1">
              <Target className="w-4 h-4" />
              {quiz.questionCount} {t("learning.quizzes.questions") || "questions"}
            </span>
            <span className="flex items-center gap-1">
              <Clock className="w-4 h-4" />
              {quiz.timeLimit} {t("learning.quizzes.minutes") || "min"}
            </span>
            <span className="flex items-center gap-1">
              <Star className="w-4 h-4" />
              +{quiz.xpReward} XP
            </span>
          </div>
          <ChevronRight className="w-5 h-5 text-gray-400" />
        </div>
      </button>
    );
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-red-50 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-orange-500 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-red-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-orange-500 to-red-500 text-white p-6 pb-20">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold">{t("learning.quizzes.title") || "Quizzes"}</h1>
            <p className="text-orange-100 text-sm">
              {t("learning.quizzes.testYourKnowledge") || "Test your knowledge"}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 -mt-14 pb-8 max-w-2xl mx-auto">
        {/* Quick Quiz Card */}
        <div className="bg-gradient-to-r from-yellow-400 to-orange-500 rounded-2xl p-6 mb-6 shadow-xl">
          <div className="flex items-center gap-4">
            <div className="p-4 bg-white/20 rounded-xl">
              <Zap className="w-8 h-8 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="font-bold text-white text-lg">
                {t("learning.quizzes.quickQuiz") || "Quick Quiz"}
              </h3>
              <p className="text-white/80 text-sm">
                {t("learning.quizzes.quickQuizDesc") || "Random 10 questions, 5 minutes"}
              </p>
            </div>
            <button
              onClick={() => navigate("/learn/quizzes/quick")}
              className="px-4 py-2 bg-white text-orange-500 rounded-lg font-semibold hover:bg-white/90 transition-colors"
            >
              {t("learning.quizzes.start") || "Start"}
            </button>
          </div>
        </div>

        {/* Quiz Categories */}
        <h2 className="text-lg font-bold text-gray-800 mb-4">
          {t("learning.quizzes.allQuizzes") || "All Quizzes"}
        </h2>

        {quizzes.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-orange-100 w-fit mx-auto mb-4">
              <Target className="w-8 h-8 text-orange-500" />
            </div>
            <p className="text-gray-500">
              {t("learning.quizzes.noQuizzes") || "No quizzes available yet"}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {quizzes.map((quiz) => (
              <QuizCard key={quiz._id} quiz={quiz} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Quizzes;
