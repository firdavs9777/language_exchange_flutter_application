import React from "react";
import { useTranslation } from "react-i18next";
import StoreLink, { StorePlacement } from "../../growth/StoreLink";

export interface FinalCtaProps {
  title?: string;
  subtitle?: string;
  /** utm_campaign on both store links. Each landing page passes its own. */
  placement?: StorePlacement;
}

const FinalCta: React.FC<FinalCtaProps> = ({ title, subtitle, placement = "final-cta" }) => {
  const { t } = useTranslation();
  return (
    // The gradient breathes: background-position only, so it costs no layout
    // and no repaint of the text. via-[#00ACC1] is a shade of the brand teal,
    // dark enough that white type clears AA-large on every stop of the sweep.
    <section
      data-testid="final-cta"
      className="bg-gradient-to-br from-brand via-[#00ACC1] to-brand bg-[length:200%_200%] px-4 py-16 text-center motion-safe:animate-bt-gradient"
    >
      <h2 className="text-3xl font-extrabold tracking-tight text-white">
        {title || t("home.cta.title") || "Someone is learning your language right now"}
      </h2>
      {/* Semibold, not regular: at 14px the softened white needs the extra
          weight to stay legible over the lightest stop of the gradient. */}
      <p className="mx-auto mt-2 max-w-md text-sm font-semibold text-white/[0.9]">
        {subtitle || t("home.cta.subtitle") || "Free to start. No card, no trial countdown."}
      </p>
      <div className="mt-7 flex flex-wrap justify-center gap-3">
        <StoreLink
          store="ios"
          placement={placement}
          className="rounded-xl bg-white px-6 py-3 text-sm font-extrabold text-brand-dark"
        />
        <StoreLink
          store="android"
          placement={placement}
          className="rounded-xl bg-gray-900 px-6 py-3 text-sm font-extrabold text-white"
        />
      </div>
    </section>
  );
};

export default FinalCta;
