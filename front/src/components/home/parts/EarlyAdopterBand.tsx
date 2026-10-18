import React from "react";
import { useTranslation } from "react-i18next";
import { Badge } from "../../../design";

// Honest framing in place of social proof the product has not earned. This
// band is explicitly temporary: once real reviews exist, they replace it.
const EarlyAdopterBand: React.FC = () => {
  const { t } = useTranslation();
  return (
    <section data-testid="early-adopter-band" className="px-4 py-14">
      <div className="mx-auto max-w-3xl rounded-card bg-banana/[0.14] p-8 text-center">
        <Badge tone="banana">{t("home.earlyAdopter.badge") || "Launched December 2025"}</Badge>
        <h2 className="mt-3 text-2xl font-extrabold tracking-tight text-gray-900 dark:text-gray-50">
          {t("home.earlyAdopter.title") || "Be one of the first"}
        </h2>
        <p className="mx-auto mt-2 max-w-xl text-sm leading-relaxed text-gray-600 dark:text-gray-300">
          {t("home.earlyAdopter.body") ||
            "BananaTalk is new. The people you meet here are the ones building what this community becomes — which is a better reason to join early than any review."}
        </p>
      </div>
    </section>
  );
};

export default EarlyAdopterBand;
