import React from "react";
import HeroDemo from "./parts/HeroDemo";
import StatStrip from "./parts/StatStrip";
import HowItWorks from "./parts/HowItWorks";
import FeatureShowcase from "./parts/FeatureShowcase";
import LanguageMarquee from "./parts/LanguageMarquee";
import PricingSection from "./parts/PricingSection";
import EarlyAdopterBand from "./parts/EarlyAdopterBand";
import FinalCta from "./parts/FinalCta";
import PromoCarousel from "../growth/PromoCarousel";
import AppDownloadPopup from "../growth/AppDownloadPopup";
import StickyAppBanner from "../growth/StickyAppBanner";
import AdUnit from "../ads/AdUnit";
import { AD_SLOTS } from "../ads/adsenseConfig";

// The homepage is an ordering of sections and nothing else. Every section owns
// its own markup, copy and tests; this file owns only the sequence, which is
// the argument the page makes: show the mechanic, prove the scale, explain the
// use, show the features, name the price, ask for the install.
//
// The AdUnit placement below predates this rewrite (see commit 1ff24d4,
// "place AdUnit on home, community list, and profile (env-gated)") and is
// carried forward in the same relative position -- after the feature
// showcase -- rather than dropped by the rewrite. It renders nothing unless
// ads are configured, so it does not affect the section-ordering tests.
const HomeMain: React.FC = () => (
  <div className="bg-surface dark:bg-canvas-dark">
    <PromoCarousel />
    <HeroDemo />
    <StatStrip />
    <HowItWorks />
    <FeatureShowcase />
    <AdUnit slot={AD_SLOTS.home} className="my-6" />
    <LanguageMarquee />
    <div id="pricing">
      <PricingSection />
    </div>
    <EarlyAdopterBand />
    <FinalCta />
    <AppDownloadPopup />
    <StickyAppBanner />
  </div>
);

export default HomeMain;
