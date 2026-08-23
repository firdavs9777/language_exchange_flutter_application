import React from "react";
import { FileText, Venus, Cake, MapPin, LucideIcon } from "lucide-react";

interface AboutCardProps {
  bio?: string;
  gender?: string;
  birthday?: string;
  location?: string;
}

interface Row {
  key: string;
  icon: LucideIcon;
  label: string;
  value?: string;
}

const AboutCard: React.FC<AboutCardProps> = ({ bio, gender, birthday, location }) => {
  const rows: Row[] = [
    { key: "bio", icon: FileText, label: "Bio", value: bio },
    { key: "gender", icon: Venus, label: "Gender", value: gender },
    { key: "birthday", icon: Cake, label: "Birthday", value: birthday },
    { key: "location", icon: MapPin, label: "Location", value: location },
  ];

  const visible = rows.filter((r) => Boolean(r.value && r.value.trim()));

  if (visible.length === 0) return null;

  return (
    <div className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 dark:border-gray-700/30">
      <h3 className="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
        About
      </h3>
      <div className="flex flex-col gap-3">
        {visible.map(({ key, icon: Icon, label, value }) => (
          <div key={key} data-testid={`about-row-${key}`} className="flex items-start gap-3">
            <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-teal-50 dark:bg-teal-900/30">
              <Icon className="w-4 h-4 text-teal-500 dark:text-teal-400" />
            </span>
            <div className="leading-tight">
              <p className="text-[11px] uppercase tracking-wide text-gray-400 dark:text-gray-500">
                {label}
              </p>
              <p className="text-sm text-gray-800 dark:text-gray-100 whitespace-pre-wrap break-words">
                {value}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default AboutCard;
