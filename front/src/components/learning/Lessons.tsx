import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetLessonsQuery,
  useGetRecommendedLessonsQuery,
} from "../../store/slices/learningSlice";
import {
  ArrowLeft,
  BookOpen,
  Clock,
  Star,
  ChevronRight,
  Loader2,
  Sparkles,
  Filter,
} from "lucide-react";

interface Lesson {
  _id: string;
  title: string;
  description: string;
  category: string;
  difficulty: "beginner" | "intermediate" | "advanced";
  duration: number;
  xpReward: number;
  completed: boolean;
  progress: number;
}

const DIFFICULTY_COLORS = {
  beginner: { bg: "bg-green-100", text: "text-green-600", label: "Beginner" },
  intermediate: { bg: "bg-yellow-100", text: "text-yellow-600", label: "Intermediate" },
  advanced: { bg: "bg-red-100", text: "text-red-600", label: "Advanced" },
};

const CATEGORIES = ["All", "Grammar", "Vocabulary", "Conversation", "Culture", "Writing"];

const Lessons: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [selectedCategory, setSelectedCategory] = useState("All");
  const [selectedDifficulty, setSelectedDifficulty] = useState<string | null>(null);

  const { data: lessonsData, isLoading } = useGetLessonsQuery({});
  const { data: recommendedData } = useGetRecommendedLessonsQuery({});

  const lessons: Lesson[] = Array.isArray(lessonsData?.data) ? lessonsData.data : [];
  const recommended: Lesson[] = Array.isArray(recommendedData?.data) ? recommendedData.data : [];

  const filteredLessons = lessons.filter((lesson) => {
    const categoryMatch = selectedCategory === "All" || lesson.category === selectedCategory;
    const difficultyMatch = !selectedDifficulty || lesson.difficulty === selectedDifficulty;
    return categoryMatch && difficultyMatch;
  });

  const LessonCard: React.FC<{ lesson: Lesson; recommended?: boolean }> = ({
    lesson,
    recommended: isRecommended = false,
  }) => {
    const difficultyInfo = DIFFICULTY_COLORS[lesson.difficulty];

    return (
      <button
        onClick={() => navigate(`/learn/lessons/${lesson._id}`)}
        className={`w-full text-left p-4 rounded-xl border transition-all duration-200 hover:shadow-lg ${
          lesson.completed
            ? "bg-gray-50 border-gray-200"
            : "bg-white/60 backdrop-blur-sm border-white/30 hover:bg-white/80"
        }`}
      >
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-2">
            {isRecommended && (
              <span className="flex items-center gap-1 px-2 py-0.5 bg-purple-100 text-purple-600 rounded-full text-xs">
                <Sparkles className="w-3 h-3" />
                {t("learning.lessons.recommended") || "Recommended"}
              </span>
            )}
            <span className={`px-2 py-0.5 rounded-full text-xs ${difficultyInfo.bg} ${difficultyInfo.text}`}>
              {difficultyInfo.label}
            </span>
          </div>
          {lesson.completed && (
            <span className="text-green-500">
              <Star className="w-5 h-5 fill-current" />
            </span>
          )}
        </div>

        <h3 className="font-semibold text-gray-800 mb-1">{lesson.title}</h3>
        <p className="text-sm text-gray-500 mb-3 line-clamp-2">{lesson.description}</p>

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4 text-sm text-gray-400">
            <span className="flex items-center gap-1">
              <Clock className="w-4 h-4" />
              {lesson.duration} {t("learning.lessons.minutes") || "min"}
            </span>
            <span className="flex items-center gap-1">
              <Star className="w-4 h-4" />
              +{lesson.xpReward} XP
            </span>
          </div>
          <ChevronRight className="w-5 h-5 text-gray-400" />
        </div>

        {lesson.progress > 0 && !lesson.completed && (
          <div className="mt-3">
            <div className="w-full bg-gray-200 rounded-full h-1.5 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-teal-500 to-green-500 rounded-full"
                style={{ width: `${lesson.progress}%` }}
              />
            </div>
            <p className="text-xs text-gray-400 mt-1">{lesson.progress}% complete</p>
          </div>
        )}
      </button>
    );
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-purple-50 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-500 to-green-500 text-white p-6 pb-20">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold">
              {t("learning.lessons.title") || "Lessons"}
            </h1>
            <p className="text-teal-100 text-sm">
              {lessons.length} {t("learning.lessons.available") || "lessons available"}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 -mt-14 pb-8 max-w-2xl mx-auto">
        {/* Filters */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-xl border border-white/30 mb-6">
          {/* Categories */}
          <div className="flex gap-2 overflow-x-auto pb-3 mb-3">
            {CATEGORIES.map((category) => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2 rounded-full text-sm whitespace-nowrap transition-colors ${
                  selectedCategory === category
                    ? "bg-teal-500 text-white"
                    : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                }`}
              >
                {category}
              </button>
            ))}
          </div>

          {/* Difficulty Filter */}
          <div className="flex gap-2">
            <button
              onClick={() => setSelectedDifficulty(null)}
              className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                !selectedDifficulty
                  ? "bg-gray-800 text-white"
                  : "bg-gray-100 text-gray-600"
              }`}
            >
              {t("learning.lessons.allLevels") || "All Levels"}
            </button>
            {Object.entries(DIFFICULTY_COLORS).map(([key, value]) => (
              <button
                key={key}
                onClick={() => setSelectedDifficulty(key)}
                className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                  selectedDifficulty === key
                    ? `${value.bg} ${value.text}`
                    : "bg-gray-100 text-gray-600"
                }`}
              >
                {value.label}
              </button>
            ))}
          </div>
        </div>

        {/* Recommended Section */}
        {recommended.length > 0 && selectedCategory === "All" && !selectedDifficulty && (
          <div className="mb-8">
            <h2 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-purple-500" />
              {t("learning.lessons.recommendedForYou") || "Recommended for You"}
            </h2>
            <div className="space-y-3">
              {recommended.slice(0, 3).map((lesson) => (
                <LessonCard key={lesson._id} lesson={lesson} recommended />
              ))}
            </div>
          </div>
        )}

        {/* All Lessons */}
        <div>
          <h2 className="text-lg font-bold text-gray-800 mb-4">
            {selectedCategory === "All"
              ? t("learning.lessons.allLessons") || "All Lessons"
              : selectedCategory}
          </h2>
          {filteredLessons.length === 0 ? (
            <div className="text-center py-12">
              <div className="p-4 rounded-full bg-gray-100 w-fit mx-auto mb-4">
                <BookOpen className="w-8 h-8 text-gray-400" />
              </div>
              <p className="text-gray-500">
                {t("learning.lessons.noLessonsFound") || "No lessons found"}
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {filteredLessons.map((lesson) => (
                <LessonCard key={lesson._id} lesson={lesson} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Lessons;
