import React from "react";
import { Globe, ArrowRight, BookOpen, Award } from "lucide-react";

interface LanguagesCardProps {
  native?: string;
  learning?: string;
  level?: string;
}

const LanguagesCard: React.FC<LanguagesCardProps> = ({ native, learning, level }) => {
  const hasNative = Boolean(native && native.trim());
  const hasLearning = Boolean(learning && learning.trim());
  const hasLevel = Boolean(level && level.trim());

  if (!hasNative && !hasLearning) return null;

  return (
    <div className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 dark:border-gray-700/30">
      <h3 className="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
        Languages
      </h3>
      <div className="flex flex-wrap items-center gap-3">
        {hasNative && (
          <div
            data-testid="language-native"
            className="flex items-center gap-2 px-4 py-3 rounded-xl bg-teal-50 dark:bg-teal-900/30 border border-teal-100 dark:border-teal-800"
          >
            <Globe className="w-5 h-5 text-teal-500 dark:text-teal-400" />
            <div className="leading-tight">
              <p className="text-[11px] uppercase tracking-wide text-gray-400 dark:text-gray-500">
                Native
              </p>
              <p className="text-sm font-semibold text-gray-800 dark:text-gray-100">{native}</p>
            </div>
          </div>
        )}

        {hasNative && hasLearning && (
          <ArrowRight className="w-5 h-5 text-gray-400 dark:text-gray-500 shrink-0" />
        )}

        {hasLearning && (
          <div
            data-testid="language-learning"
            className="flex items-center gap-2 px-4 py-3 rounded-xl bg-sky-50 dark:bg-sky-900/30 border border-sky-100 dark:border-sky-800"
          >
            <BookOpen className="w-5 h-5 text-sky-500 dark:text-sky-400" />
            <div className="leading-tight">
              <p className="text-[11px] uppercase tracking-wide text-gray-400 dark:text-gray-500">
                Learning
              </p>
              <p className="text-sm font-semibold text-gray-800 dark:text-gray-100">{learning}</p>
            </div>
          </div>
        )}

        {hasLevel && (
          <span
            data-testid="language-level"
            className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold bg-purple-50 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 border border-purple-100 dark:border-purple-800"
          >
            <Award className="w-3.5 h-3.5" />
            {level}
          </span>
        )}
      </div>
    </div>
  );
};

export default LanguagesCard;
