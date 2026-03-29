import React, { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetLessonQuery,
  useStartLessonMutation,
  useSubmitLessonMutation,
} from "../../store/slices/learningSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Clock,
  Star,
  Play,
  CheckCircle,
  XCircle,
  ChevronRight,
  Loader2,
  Award,
} from "lucide-react";

interface Exercise {
  _id: string;
  type: "multiple_choice" | "fill_blank" | "matching";
  question: string;
  options?: string[];
  correctAnswer: string | number;
}

const LessonDetail: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { lessonId } = useParams<{ lessonId: string }>();

  const { data, isLoading } = useGetLessonQuery(lessonId || "", { skip: !lessonId });
  const [startLesson, { isLoading: isStarting }] = useStartLessonMutation();
  const [submitLesson, { isLoading: isSubmitting }] = useSubmitLessonMutation();

  const [isStarted, setIsStarted] = useState(false);
  const [currentExercise, setCurrentExercise] = useState(0);
  const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null);
  const [answers, setAnswers] = useState<{ exerciseId: string; answer: number }[]>([]);
  const [showResult, setShowResult] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [completed, setCompleted] = useState(false);
  const [results, setResults] = useState<{ correct: number; total: number; xp: number } | null>(null);

  const lesson = data?.data;
  const exercises: Exercise[] = lesson?.exercises || [];
  const exercise = exercises[currentExercise];

  const handleStart = async () => {
    try {
      await startLesson(lessonId || "").unwrap();
      setIsStarted(true);
    } catch (error) {
      toast.error(t("learning.lesson.startError") || "Failed to start lesson", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleAnswer = (index: number) => {
    if (showResult) return;
    setSelectedAnswer(index);
  };

  const handleSubmitAnswer = () => {
    if (selectedAnswer === null) return;

    const correct = selectedAnswer === exercise.correctAnswer;
    setIsCorrect(correct);
    setShowResult(true);
    setAnswers([...answers, { exerciseId: exercise._id, answer: selectedAnswer }]);
  };

  const handleNext = async () => {
    if (currentExercise + 1 >= exercises.length) {
      // Submit lesson
      try {
        const result = await submitLesson({
          lessonId: lessonId || "",
          answers: [...answers],
        }).unwrap();

        setResults(result.data);
        setCompleted(true);
      } catch (error) {
        toast.error(t("learning.lesson.submitError") || "Failed to submit lesson", {
          position: "top-right",
          autoClose: 3000,
          theme: "dark",
          transition: Bounce,
        });
      }
    } else {
      setCurrentExercise((prev) => prev + 1);
      setSelectedAnswer(null);
      setShowResult(false);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-purple-50 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
      </div>
    );
  }

  if (!lesson) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-purple-50 flex items-center justify-center">
        <p className="text-gray-500">{t("learning.lesson.notFound") || "Lesson not found"}</p>
      </div>
    );
  }

  if (completed && results) {
    const accuracy = Math.round((results.correct / results.total) * 100);

    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-500 to-green-500 flex flex-col items-center justify-center p-6">
        <div className="bg-white rounded-3xl p-8 text-center max-w-md w-full shadow-2xl">
          <div className="p-6 rounded-full bg-yellow-100 w-fit mx-auto mb-6">
            <Award className="w-12 h-12 text-yellow-500" />
          </div>
          <h2 className="text-2xl font-bold text-gray-800 mb-2">
            {t("learning.lesson.completed") || "Lesson Complete!"}
          </h2>
          <p className="text-gray-500 mb-6">{lesson.title}</p>

          <div className="grid grid-cols-3 gap-4 mb-8">
            <div className="bg-gray-50 rounded-xl p-4">
              <p className="text-2xl font-bold text-teal-600">{results.correct}</p>
              <p className="text-gray-500 text-sm">{t("learning.lesson.correct") || "Correct"}</p>
            </div>
            <div className="bg-gray-50 rounded-xl p-4">
              <p className="text-2xl font-bold text-gray-600">{results.total}</p>
              <p className="text-gray-500 text-sm">{t("learning.lesson.total") || "Total"}</p>
            </div>
            <div className="bg-yellow-50 rounded-xl p-4">
              <p className="text-2xl font-bold text-yellow-600">+{results.xp}</p>
              <p className="text-gray-500 text-sm">XP</p>
            </div>
          </div>

          <div className="mb-8">
            <p className="text-gray-500 mb-2">{t("learning.lesson.accuracy") || "Accuracy"}</p>
            <div className="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
              <div
                className={`h-full rounded-full ${
                  accuracy >= 80 ? "bg-green-500" : accuracy >= 50 ? "bg-yellow-500" : "bg-red-500"
                }`}
                style={{ width: `${accuracy}%` }}
              />
            </div>
            <p className="text-xl font-bold text-gray-800 mt-2">{accuracy}%</p>
          </div>

          <div className="flex gap-3">
            <button
              onClick={() => navigate("/learn/lessons")}
              className="flex-1 py-3 bg-gray-100 text-gray-600 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
            >
              {t("learning.lesson.backToLessons") || "Back to Lessons"}
            </button>
            <button
              onClick={() => navigate("/learn")}
              className="flex-1 py-3 bg-gradient-to-r from-teal-500 to-green-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
            >
              {t("learning.lesson.continue") || "Continue"}
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!isStarted) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-purple-50">
        {/* Header */}
        <div className="bg-gradient-to-r from-teal-500 to-green-500 text-white p-6">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-4"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
        </div>

        {/* Content */}
        <div className="px-4 -mt-20 pb-8 max-w-2xl mx-auto">
          <div className="bg-white rounded-2xl p-6 shadow-xl">
            <h1 className="text-2xl font-bold text-gray-800 mb-2">{lesson.title}</h1>
            <p className="text-gray-500 mb-6">{lesson.description}</p>

            <div className="flex items-center gap-6 mb-6 text-sm">
              <span className="flex items-center gap-2 text-gray-500">
                <Clock className="w-5 h-5" />
                {lesson.duration} {t("learning.lesson.minutes") || "min"}
              </span>
              <span className="flex items-center gap-2 text-yellow-500">
                <Star className="w-5 h-5" />
                +{lesson.xpReward} XP
              </span>
            </div>

            <div className="bg-gray-50 rounded-xl p-4 mb-6">
              <h3 className="font-semibold text-gray-800 mb-2">
                {t("learning.lesson.whatYouWillLearn") || "What you'll learn"}
              </h3>
              <ul className="space-y-2">
                {lesson.objectives?.map((obj: string, index: number) => (
                  <li key={index} className="flex items-start gap-2 text-gray-600">
                    <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
                    {obj}
                  </li>
                )) || (
                  <li className="text-gray-500">
                    {t("learning.lesson.noObjectives") || "Complete exercises to earn XP"}
                  </li>
                )}
              </ul>
            </div>

            <button
              onClick={handleStart}
              disabled={isStarting}
              className="w-full flex items-center justify-center gap-2 py-4 bg-gradient-to-r from-teal-500 to-green-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all disabled:opacity-50"
            >
              <Play className="w-5 h-5" />
              {isStarting
                ? t("learning.lesson.starting") || "Starting..."
                : t("learning.lesson.startLesson") || "Start Lesson"}
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-purple-50 flex flex-col">
      {/* Header */}
      <div className="bg-white border-b p-4">
        <div className="flex items-center justify-between max-w-2xl mx-auto">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-gray-600" />
          </button>
          <p className="font-semibold text-gray-800">
            {currentExercise + 1} / {exercises.length}
          </p>
          <div className="w-10" />
        </div>
        <div className="max-w-2xl mx-auto mt-4">
          <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-teal-500 to-green-500 rounded-full transition-all duration-300"
              style={{ width: `${((currentExercise + 1) / exercises.length) * 100}%` }}
            />
          </div>
        </div>
      </div>

      {/* Exercise */}
      <div className="flex-1 flex flex-col items-center justify-center px-4 py-8">
        <div className="w-full max-w-2xl">
          <h2 className="text-xl font-semibold text-gray-800 mb-8 text-center">
            {exercise?.question}
          </h2>

          <div className="space-y-3">
            {exercise?.options?.map((option, index) => (
              <button
                key={index}
                onClick={() => handleAnswer(index)}
                disabled={showResult}
                className={`w-full p-4 rounded-xl text-left font-medium transition-all duration-200 ${
                  showResult
                    ? index === exercise.correctAnswer
                      ? "bg-green-100 text-green-800 border-2 border-green-500"
                      : selectedAnswer === index
                      ? "bg-red-100 text-red-800 border-2 border-red-500"
                      : "bg-gray-100 text-gray-500"
                    : selectedAnswer === index
                    ? "bg-teal-100 text-teal-800 border-2 border-teal-500"
                    : "bg-white border-2 border-gray-200 hover:border-teal-300"
                }`}
              >
                <div className="flex items-center gap-3">
                  <span
                    className={`w-8 h-8 rounded-full flex items-center justify-center text-sm ${
                      showResult
                        ? index === exercise.correctAnswer
                          ? "bg-green-500 text-white"
                          : selectedAnswer === index
                          ? "bg-red-500 text-white"
                          : "bg-gray-200 text-gray-500"
                        : selectedAnswer === index
                        ? "bg-teal-500 text-white"
                        : "bg-gray-100 text-gray-500"
                    }`}
                  >
                    {String.fromCharCode(65 + index)}
                  </span>
                  <span>{option}</span>
                  {showResult && index === exercise.correctAnswer && (
                    <CheckCircle className="w-5 h-5 text-green-500 ml-auto" />
                  )}
                  {showResult && selectedAnswer === index && index !== exercise.correctAnswer && (
                    <XCircle className="w-5 h-5 text-red-500 ml-auto" />
                  )}
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="p-4 bg-white border-t">
        <div className="max-w-2xl mx-auto">
          {!showResult ? (
            <button
              onClick={handleSubmitAnswer}
              disabled={selectedAnswer === null}
              className="w-full py-4 bg-gradient-to-r from-teal-500 to-green-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {t("learning.lesson.checkAnswer") || "Check Answer"}
            </button>
          ) : (
            <button
              onClick={handleNext}
              disabled={isSubmitting}
              className="w-full flex items-center justify-center gap-2 py-4 bg-gradient-to-r from-teal-500 to-green-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all disabled:opacity-50"
            >
              {currentExercise + 1 >= exercises.length
                ? t("learning.lesson.finish") || "Finish Lesson"
                : t("learning.lesson.next") || "Next"}
              <ChevronRight className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default LessonDetail;
