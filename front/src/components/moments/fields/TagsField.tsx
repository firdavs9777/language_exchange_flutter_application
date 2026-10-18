import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { FaTimes } from "react-icons/fa";

export const MAX_TAGS = 5;

/** Up to five tags: an input with Add, the chips, and the count. */
const TagsField: React.FC<{ value: string[]; onChange: (v: string[]) => void; showChips?: boolean }> = ({
  value,
  onChange,
  showChips = true,
}) => {
  const { t } = useTranslation();
  const [draft, setDraft] = useState("");
  const tag = draft.trim();
  const full = value.length >= MAX_TAGS;

  const add = () => {
    if (!tag || full || value.indexOf(tag) > -1) return;
    onChange(value.concat([tag]));
    setDraft("");
  };

  return (
    <div>
      <div className="flex gap-2">
        <input
          type="text"
          placeholder={t("moments_section.fields.tagPlaceholder") || "Add a tag..."}
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              add();
            }
          }}
          className="flex-1 p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          maxLength={20}
        />
        <button
          type="button"
          onClick={add}
          disabled={!tag || full}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {t("moments_section.fields.addTag") || "Add"}
        </button>
      </div>
      <div className="text-xs text-gray-500 mt-1">
        {t("moments_section.fields.tagsUsed", { count: value.length }) || `${value.length}/5 tags`}
      </div>
      {showChips && value.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-2">
          {value.map((v) => (
            <span key={v} className="inline-flex items-center gap-1 px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
              #{v}
              <button
                type="button"
                aria-label={`Remove ${v}`}
                onClick={() => onChange(value.filter((x) => x !== v))}
                className="ml-1 hover:text-blue-900"
              >
                <FaTimes className="w-3 h-3" />
              </button>
            </span>
          ))}
        </div>
      )}
    </div>
  );
};

export default TagsField;
