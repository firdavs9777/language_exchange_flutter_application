import React from "react";

interface ProfileTabsProps {
  active: string;
  onChange: (tab: string) => void;
  tabs?: string[];
}

const DEFAULT_TABS = ["overview", "moments", "about"];

const ProfileTabs: React.FC<ProfileTabsProps> = ({ active, onChange, tabs }) => {
  const items = tabs && tabs.length > 0 ? tabs : DEFAULT_TABS;

  return (
    <div
      role="tablist"
      className="flex gap-1 p-1 rounded-full bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl border border-white/30 dark:border-gray-700/30 shadow-lg"
    >
      {items.map((tab) => {
        const isActive = tab === active;
        return (
          <button
            key={tab}
            type="button"
            role="tab"
            aria-selected={isActive}
            data-testid={`profile-tab-${tab}`}
            onClick={() => onChange(tab)}
            className={`flex-1 px-4 py-2 rounded-full text-sm font-medium capitalize transition-all ${
              isActive
                ? "bg-teal-500 text-white shadow"
                : "text-gray-600 dark:text-gray-300 hover:bg-teal-50 dark:hover:bg-teal-900/30"
            }`}
          >
            {tab}
          </button>
        );
      })}
    </div>
  );
};

export default ProfileTabs;
