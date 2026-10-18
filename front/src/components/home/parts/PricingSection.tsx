import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { Check } from "lucide-react";
import { SurfaceCard, Badge } from "../../../design";
import {
  useGetVipPlansQuery,
  inferPlatform,
  FALLBACK_PLANS,
  VipPlan,
} from "../../../store/slices/plansSlice";
import StoreLink from "../../growth/StoreLink";
import { VIP_PERKS } from "../../vip/perks";

const PricingSection: React.FC = () => {
  const { t } = useTranslation();
  // Mount, then decide. Reading the user agent during render would bake the
  // prerendered iOS choice into the markup, and React 18 does not patch
  // mismatched attributes while hydrating — Android visitors would keep the
  // App Store link forever. Starting at "ios" makes the first client render
  // match the server; the effect then re-renders with the real platform, which
  // React does apply, and the plans query refetches for Android.
  const [platform, setPlatform] = useState<"ios" | "android">("ios");
  useEffect(() => {
    setPlatform(inferPlatform(typeof navigator === "undefined" ? "" : navigator.userAgent));
  }, []);

  const { data, isError } = useGetVipPlansQuery(platform);

  // A pricing section that renders nothing is worse than one slightly stale.
  const plans: VipPlan[] = isError || !data || data.length === 0 ? FALLBACK_PLANS : data;

  return (
    <section data-testid="pricing-section" className="px-4 py-16 bg-canvas dark:bg-canvas-dark">
      <div className="mx-auto max-w-5xl">
        <h2 className="text-center text-3xl font-extrabold tracking-tight text-gray-900 dark:text-gray-50">
          {t("home.pricing.title") || "Simple pricing"}
        </h2>
        <p className="mt-2 text-center text-sm text-gray-500 dark:text-gray-400">
          {t("home.pricing.subtitle") || "Start free. Upgrade in the app whenever you want."}
        </p>

        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {/* Free is not a store product and has no plan record. */}
          <SurfaceCard
            padding="lg"
            className="flex flex-col transition-transform duration-300 motion-safe:hover:-translate-y-1 hover:shadow-float"
          >
            <div data-testid="plan-card" className="flex h-full flex-col">
              <h3 className="text-sm font-bold text-gray-900 dark:text-gray-50">
                {t("home.pricing.free.name") || "Free"}
              </h3>
              <p data-testid="plan-price" className="mt-2 text-3xl font-extrabold text-gray-900 dark:text-gray-50">
                $0
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {t("home.pricing.free.period") || "forever"}
              </p>
              <ul className="mt-4 flex-1 space-y-2">
                {[
                  t("home.pricing.free.f1") || "Unlimited 1-on-1 chat with translation",
                  t("home.pricing.free.f2") || "Browse and connect with the community",
                  t("home.pricing.free.f3") || "Post Moments and read Stories",
                ].map((f) => (
                  <li key={f} className="flex gap-2 text-xs text-gray-600 dark:text-gray-300">
                    <Check className="mt-0.5 h-3.5 w-3.5 shrink-0 text-brand" aria-hidden />
                    <span>{f}</span>
                  </li>
                ))}
              </ul>
              <a
                href="/register"
                className="mt-5 rounded-full border-2 border-brand px-4 py-2 text-center text-xs font-bold text-brand-dark dark:text-brand-light"
              >
                {t("home.pricing.free.cta") || "Create a free account"}
              </a>
            </div>
          </SurfaceCard>

          {plans.map((plan) => (
            <SurfaceCard
              key={plan.id}
              padding="lg"
              className={`transition-transform duration-300 motion-safe:hover:-translate-y-1 hover:shadow-float${plan.recommended ? " ring-2 ring-brand" : ""}`}
            >
              <div data-testid="plan-card" className="flex h-full flex-col">
                <div className="flex items-center gap-2">
                  <h3 className="text-sm font-bold text-gray-900 dark:text-gray-50">{plan.name}</h3>
                  {plan.recommended && (
                    <span data-testid="plan-recommended">
                      <Badge tone="brand">{t("home.pricing.best") || "Best value"}</Badge>
                    </span>
                  )}
                </div>

                {/* localizedPrice verbatim: the store owns currency formatting. */}
                <p data-testid="plan-price" className="mt-2 text-3xl font-extrabold text-gray-900 dark:text-gray-50">
                  {plan.localizedPrice}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {plan.duration === 1
                    ? t("home.pricing.perMonth") || "per month"
                    : `${t("home.pricing.every") || "every"} ${plan.duration} ${plan.durationUnit}s`}
                </p>

                {plan.savings && (
                  <span data-testid="plan-savings" className="mt-2 self-start">
                    <Badge tone="banana">
                      {t("home.pricing.save") || "Save"} {plan.savings}
                    </Badge>
                  </span>
                )}

                {/* The real VIP perks, localized -- not `plan.features`, which the
                    server still fills with perks free users already have. */}
                <ul data-testid="plan-perks" className="mt-4 flex-1 space-y-2">
                  {VIP_PERKS.map((perk) => (
                    <li key={perk.id} className="flex gap-2 text-xs text-gray-600 dark:text-gray-300">
                      <Check className="mt-0.5 h-3.5 w-3.5 shrink-0 text-brand" aria-hidden />
                      <span>{t(perk.key) || perk.fallback}</span>
                    </li>
                  ))}
                </ul>

                <StoreLink
                  store={platform}
                  placement="pricing"
                  className="mt-5 rounded-full bg-brand px-4 py-2 text-center text-xs font-bold text-white shadow-brand"
                >
                  {t("home.pricing.getVip") || "Get VIP in the app"}
                </StoreLink>
              </div>
            </SurfaceCard>
          ))}
        </div>
      </div>
    </section>
  );
};

export default PricingSection;
