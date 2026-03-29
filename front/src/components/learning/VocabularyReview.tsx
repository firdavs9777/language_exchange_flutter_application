import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetDueReviewsQuery,
  useSubmitReviewMutation,
} from "../../store/slices/learningSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  X,
  Check,
  RotateCcw,
  Volume2,
  Eye,
  EyeOff,
  Sparkles,
  Loader2,
} from "lucide-react";

interface ReviewItem {
  _id: string;
  word: string;
  translation: string;
  pronunciation?: string;
  exampleSentence?: string;
  srsLevel: number;
}

const VocabularyReview: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { data, isLoading, refetch } = useGetDueReviewsQuery({});
  const [submitReview, { isLoading: isSubmitting }] = useSubmitReviewMutation();

  const [currentIndex, setCurrentIndex] = useState(0);
  const [showAnswer, setShowAnswer] = useState(false);
  const [correctCount, setCorrectCount] = useState(0);
  const [incorrectCount, setIncorrectCount] = useState(0);
  const [isComplete, setIsComplete] = useState(false);

  const reviews: ReviewItem[] = Array.isArray(data?.data) ? data.data : [];
  const currentItem = reviews[currentIndex];
  const totalReviews = reviews.length;

  useEffect(() => {
    setShowAnswer(false);
  }, [currentIndex]);

  const handleAnswer = async (correct: boolean) => {
    if (!currentItem || isSubmitting) return;

    try {
      await submitReview({
        vocabularyId: currentItem._id,
        correct,
      }).unwrap();

      if (correct) {
        setCorrectCount((prev) => prev + 1);
      } else {
        setIncorrectCount((prev) => prev + 1);
      }

      if (currentIndex + 1 >= totalReviews) {
        setIsComplete(true);
      } else {
        setCurrentIndex((prev) => prev + 1);
      }
    } catch (error) {
      toast.error(t("learning.review.submitError") || "Failed to submit review", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleRestart = () => {
    setCurrentIndex(0);
    setCorrectCount(0);
    setIncorrectCount(0);
    setIsComplete(false);
    setShowAnswer(false);
    refetch();
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-900 via-indigo-900 to-teal-900 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-white animate-spin" />
      </div>
    );
  }

  if (totalReviews === 0) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-900 via-indigo-900 to-teal-900 flex flex-col items-center justify-center p-6">
        <div className="bg-white/10 backdrop-blur-xl rounded-3xl p-8 text-center max-w-md border border-white/20">
          <div className="p-6 rounded-full bg-green-500/20 w-fit mx-auto mb-6">
            <Check className="w-12 h-12 text-green-400" />
          </div>
          <h2 className="text-2xl font-bold text-white mb-4">
            {t("learning.review.allCaughtUp") || "All Caught Up!"}
          </h2>
          <p className="text-white/60 mb-8">
            {t("learning.review.noReviewsDue") ||
              "You have no reviews due right now. Come back later!"}
          </p>
          <button
            onClick={() => navigate("/learn")}
            className="px-6 py-3 bg-gradient-to-r from-teal-500 to-green-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
          >
            {t("learning.review.backToDashboard") || "Back to Dashboard"}
          </button>
        </div>
      </div>
    );
  }

  if (isComplete) {
    const accuracy = Math.round((correctCount / totalReviews) * 100);

    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-900 via-indigo-900 to-teal-900 flex flex-col items-center justify-center p-6">
        <div className="bg-white/10 backdrop-blur-xl rounded-3xl p-8 text-center max-w-md border border-white/20">
          <div className="p-6 rounded-full bg-yellow-500/20 w-fit mx-auto mb-6">
            <Sparkles className="w-12 h-12 text-yellow-400" />
          </div>
          <h2 className="text-2xl font-bold text-white mb-2">
            {t("learning.review.sessionComplete") || "Session Complete!"}
          </h2>
          <p className="text-white/60 mb-8">
            {t("learning.review.greatWork") || "Great work on your review session!"}
          </p>

          <div className="grid grid-cols-3 gap-4 mb-8">
            <div className="bg-white/10 rounded-xl p-4">
              <p className="text-3xl font-bold text-white">{totalReviews}</p>
              <p className="text-white/60 text-sm">{t("learning.review.reviewed") || "Reviewed"}</p>
            </div>
            <div className="bg-green-500/20 rounded-xl p-4">
              <p className="text-3xl font-bold text-green-400">{correctCount}</p>
              <p className="text-white/60 text-sm">{t("learning.review.correct") || "Correct"}</p>
            </div>
            <div className="bg-red-500/20 rounded-xl p-4">
              <p className="text-3xl font-bold text-red-400">{incorrectCount}</p>
              <p className="text-white/60 text-sm">{t("learning.review.incorrect") || "Incorrect"}</p>
            </div>
          </div>

          <div className="mb-8">
            <p className="text-white/60 mb-2">{t("learning.review.accuracy") || "Accuracy"}</p>
            <div className="w-full bg-white/10 rounded-full h-4 overflow-hidden">
              <div
                className={`h-full rounded-full transition-all duration-500 ${
                  accuracy >= 80
                    ? "bg-gradient-to-r from-green-400 to-teal-400"
                    : accuracy >= 50
                    ? "bg-gradient-to-r from-yellow-400 to-orange-400"
                    : "bg-gradient-to-r from-red-400 to-pink-400"
                }`}
                style={{ width: `${accuracy}%` }}
              />
            </div>
            <p className="text-2xl font-bold text-white mt-2">{accuracy}%</p>
          </div>

          <div className="flex gap-3">
            <button
              onClick={handleRestart}
              className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-white/10 text-white rounded-xl font-semibold hover:bg-white/20 transition-all"
            >
              <RotateCcw className="w-5 h-5" />
              {t("learning.review.reviewAgain") || "Review Again"}
            </button>
            <button
              onClick={() => navigate("/learn")}
              className="flex-1 px-6 py-3 bg-gradient-to-r from-teal-500 to-green-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
            >
              {t("learning.review.done") || "Done"}
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-indigo-900 to-teal-900 flex flex-col">
      {/* Header */}
      <div className="p-6">
        <div className="flex items-center justify-between">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors text-white"
          >
            <X className="w-6 h-6" />
          </button>
          <div className="text-center">
            <p className="text-white/60 text-sm">
              {t("learning.review.progress") || "Progress"}
            </p>
            <p className="text-white font-bold">
              {currentIndex + 1} / {totalReviews}
            </p>
          </div>
          <div className="w-10" />
        </div>

        {/* Progress Bar */}
        <div className="mt-4 w-full bg-white/10 rounded-full h-2 overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-teal-400 to-green-400 rounded-full transition-all duration-300"
            style={{ width: `${((currentIndex + 1) / totalReviews) * 100}%` }}
          />
        </div>
      </div>

      {/* Card */}
      <div className="flex-1 flex items-center justify-center px-6">
        <div
          className="w-full max-w-md bg-white/10 backdrop-blur-xl rounded-3xl p-8 border border-white/20 cursor-pointer transition-transform hover:scale-[1.02]"
          onClick={() => setShowAnswer(!showAnswer)}
        >
          {!showAnswer ? (
            <div className="text-center py-8">
              <p className="text-3xl font-bold text-white mb-4">{currentItem?.word}</p>
              {currentItem?.pronunciation && (
                <div className="flex items-center justify-center gap-2 text-white/60 mb-8">
                  <Volume2 className="w-5 h-5" />
                  <span>{currentItem.pronunciation}</span>
                </div>
              )}
              <div className="flex items-center justify-center gap-2 text-white/40">
                <Eye className="w-5 h-5" />
                <span>{t("learning.review.tapToReveal") || "Tap to reveal answer"}</span>
              </div>
            </div>
          ) : (
            <div className="text-center py-8">
              <p className="text-xl text-white/60 mb-2">{currentItem?.word}</p>
              <div className="border-t border-white/20 my-4" />
              <p className="text-3xl font-bold text-white mb-4">{currentItem?.translation}</p>
              {currentItem?.pronunciation && (
                <div className="flex items-center justify-center gap-2 text-white/60 mb-4">
                  <Volume2 className="w-5 h-5" />
                  <span>{currentItem.pronunciation}</span>
                </div>
              )}
              {currentItem?.exampleSentence && (
                <p className="text-white/60 text-sm italic">"{currentItem.exampleSentence}"</p>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="p-6">
        {!showAnswer ? (
          <button
            onClick={() => setShowAnswer(true)}
            className="w-full py-4 bg-white/10 text-white rounded-xl font-semibold hover:bg-white/20 transition-all flex items-center justify-center gap-2"
          >
            <EyeOff className="w-5 h-5" />
            {t("learning.review.showAnswer") || "Show Answer"}
          </button>
        ) : (
          <div className="flex gap-4">
            <button
              onClick={() => handleAnswer(false)}
              disabled={isSubmitting}
              className="flex-1 py-4 bg-red-500/20 text-red-400 rounded-xl font-semibold hover:bg-red-500/30 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <X className="w-6 h-6" />
              {t("learning.review.wrong") || "Wrong"}
            </button>
            <button
              onClick={() => handleAnswer(true)}
              disabled={isSubmitting}
              className="flex-1 py-4 bg-green-500/20 text-green-400 rounded-xl font-semibold hover:bg-green-500/30 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <Check className="w-6 h-6" />
              {t("learning.review.correct") || "Correct"}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default VocabularyReview;
