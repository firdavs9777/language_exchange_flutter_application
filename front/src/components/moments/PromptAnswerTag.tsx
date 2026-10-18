import React from "react";
import { useTranslation } from "react-i18next";
import { MomentPrompt } from "./types";

/**
 * "Answering: <prompt>" on a moment that answers a prompt of the day. Renders
 * nothing for a moment without one, or from a backend that does not populate
 * `prompt` yet.
 */
const PromptAnswerTag: React.FC<{ prompt?: MomentPrompt | null; className?: string }> = ({
  prompt,
  className,
}) => {
  const { t } = useTranslation();
  if (!prompt || !prompt.text) return null;
  return (
    <div
      data-testid="moment-prompt-tag"
      className={
        className ||
        "mb-2 inline-flex max-w-full items-center gap-1.5 rounded-full border border-amber-300/60 bg-amber-50 px-2.5 py-0.5 text-[11px] sm:text-xs font-medium text-amber-800"
      }
    >
      <span aria-hidden="true">{prompt.emoji || "☀️"}</span>
      <span className="truncate">
        <span className="font-semibold">
          {t("moments_section.prompt.answering") || "Answering"}:
        </span>{" "}
        {prompt.text}
      </span>
    </div>
  );
};

export default PromptAnswerTag;
