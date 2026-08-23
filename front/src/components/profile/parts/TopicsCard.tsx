import React from "react";
import { Hash } from "lucide-react";

interface TopicsCardProps {
  topics?: string[];
}

const TopicsCard: React.FC<TopicsCardProps> = ({ topics }) => {
  const items = (topics ?? []).filter((t) => Boolean(t && t.trim()));

  if (items.length === 0) return null;

  return (
    <div className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 dark:border-gray-700/30">
      <h3 className="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
        Topics &amp; Interests
      </h3>
      <div className="flex flex-wrap gap-2">
        {items.map((topic) => (
          <span
            key={topic}
            data-testid="topic-chip"
            className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-sm font-medium bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300 border border-teal-100 dark:border-teal-800"
          >
            <Hash className="w-3.5 h-3.5" />
            {topic}
          </span>
        ))}
      </div>
    </div>
  );
};

export default TopicsCard;
