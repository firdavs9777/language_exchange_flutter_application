import React from "react";
import { useTranslation } from "react-i18next";
import { FaGlobe, FaLock, FaUsers } from "react-icons/fa";

export const PRIVACY_OPTIONS = [
  { value: "public", key: "privacyPublic", english: "Public", Icon: FaGlobe },
  { value: "friends", key: "privacyFriends", english: "Friends", Icon: FaUsers },
  { value: "private", key: "privacyPrivate", english: "Only me", Icon: FaLock },
];

export const privacyOption = (value: string) =>
  PRIVACY_OPTIONS.find((o) => o.value === value) || PRIVACY_OPTIONS[0];

export const privacyLabel = (t: (k: string) => string, value: string) => {
  const option = privacyOption(value);
  return t(`moments_section.fields.${option.key}`) || option.english;
};

const PrivacyField: React.FC<{ value: string; onChange: (v: string) => void }> = ({ value, onChange }) => {
  const { t } = useTranslation();
  return (
    <div className="grid grid-cols-3 gap-2">
      {PRIVACY_OPTIONS.map(({ value: v, Icon }) => (
        <button
          key={v}
          type="button"
          onClick={() => onChange(v)}
          aria-pressed={value === v}
          className={`p-3 rounded-lg flex flex-col items-center gap-2 text-sm transition-colors ${
            value === v ? "bg-blue-100 text-blue-600" : "hover:bg-gray-100"
          }`}
        >
          <Icon />
          {privacyLabel(t, v)}
        </button>
      ))}
    </div>
  );
};

export default PrivacyField;
