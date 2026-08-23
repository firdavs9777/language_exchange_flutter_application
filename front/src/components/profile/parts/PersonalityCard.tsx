import React from "react";
import { Brain, Droplet } from "lucide-react";

interface PersonalityCardProps {
  mbti?: string;
  bloodType?: string;
}

const PersonalityCard: React.FC<PersonalityCardProps> = ({ mbti, bloodType }) => {
  const hasMbti = Boolean(mbti && mbti.trim());
  const hasBlood = Boolean(bloodType && bloodType.trim());

  if (!hasMbti && !hasBlood) return null;

  return (
    <div className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 dark:border-gray-700/30">
      <h3 className="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
        Personality
      </h3>
      <div className="flex flex-wrap gap-3">
        {hasMbti && (
          <div
            data-testid="personality-mbti"
            className="flex items-center gap-2 px-4 py-3 rounded-xl bg-teal-50 dark:bg-teal-900/30 border border-teal-100 dark:border-teal-800"
          >
            <Brain className="w-5 h-5 text-teal-500 dark:text-teal-400" />
            <div className="leading-tight">
              <p className="text-[11px] uppercase tracking-wide text-gray-400 dark:text-gray-500">
                MBTI
              </p>
              <p className="text-sm font-semibold text-gray-800 dark:text-gray-100">
                {mbti}
              </p>
            </div>
          </div>
        )}
        {hasBlood && (
          <div
            data-testid="personality-blood"
            className="flex items-center gap-2 px-4 py-3 rounded-xl bg-red-50 dark:bg-red-900/30 border border-red-100 dark:border-red-800"
          >
            <Droplet className="w-5 h-5 text-red-500 dark:text-red-400" />
            <div className="leading-tight">
              <p className="text-[11px] uppercase tracking-wide text-gray-400 dark:text-gray-500">
                Blood Type
              </p>
              <p className="text-sm font-semibold text-gray-800 dark:text-gray-100">
                {bloodType}
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default PersonalityCard;
