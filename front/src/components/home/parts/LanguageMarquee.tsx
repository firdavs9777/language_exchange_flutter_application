import React from "react";
import { useTranslation } from "react-i18next";
import { languageFlag, displayCode } from "../../../utils/languages";
import { MARQUEE_LANGUAGES } from "../../../data/marqueeLanguages";

const LanguageMarquee: React.FC = () => {
  const { t } = useTranslation();
  // Rendered twice so the -50% translate loops seamlessly.
  const loop = [...MARQUEE_LANGUAGES, ...MARQUEE_LANGUAGES];

  return (
    <section
      data-testid="language-marquee"
      className="overflow-hidden py-10 [mask-image:linear-gradient(90deg,transparent,#000_12%,#000_88%,transparent)]"
    >
      <h2 className="mb-1 text-center text-xs font-bold uppercase tracking-widest text-gray-900 dark:text-gray-50">
        {t("home.marquee.title") || "Native speakers of every language you want to learn"}
      </h2>
      <p className="mb-5 text-center text-[11px] font-semibold uppercase tracking-widest text-gray-400">
        {t("home.marquee.caption") || "137 languages, and counting"}
      </p>
      <div className="flex w-max gap-2 motion-safe:animate-bt-marquee hover:[animation-play-state:paused]">
        {loop.map((name, i) => (
          <span
            key={`${name}-${i}`}
            data-testid="marquee-chip"
            className="inline-flex items-center gap-2 whitespace-nowrap rounded-full border border-gray-200 bg-surface px-3.5 py-2 text-xs font-bold text-gray-900 shadow-card dark:border-gray-700 dark:bg-cardbg-dark dark:text-gray-50"
          >
            <span aria-hidden className="text-sm">{languageFlag(name)}</span>
            {name}
            <b className="rounded-full bg-brand/[0.09] px-1.5 py-0.5 text-[9px] font-extrabold text-brand-dark dark:text-brand-light">
              {displayCode(name)}
            </b>
          </span>
        ))}
      </div>
    </section>
  );
};

export default LanguageMarquee;
