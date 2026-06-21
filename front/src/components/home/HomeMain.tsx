import React, { useState } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  Globe2,
  MessageCircle,
  Mic,
  Sparkles,
  ChevronRight,
  Star,
  Check,
  ArrowRight,
  BookOpen,
  Headphones,
  Languages,
  ShieldCheck,
  Smartphone,
  Crown,
  X,
} from "lucide-react";
import "./HomeMain.scss";

const APP_STORE_URL =
  "https://apps.apple.com/us/app/bananatalk-learn-meet-or-date/id6755862146";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.bananatalk.app";
const DOWNLOAD_LINK = "https://banatalk.com/download";

interface Feature {
  icon: React.ReactNode;
  title: string;
  description: string;
  mobileOnly?: boolean;
}

interface PricingPlan {
  name: string;
  price: string;
  period: string;
  highlight?: string;
  features: string[];
  ctaLabel: string;
  ctaHref?: string;
  isVip?: boolean;
  popular?: boolean;
}

const HomeMain: React.FC = () => {
  const { t } = useTranslation();
  const [showVipModal, setShowVipModal] = useState(false);

  const handleVipCta = () => {
    const ua = navigator.userAgent;
    if (/iPad|iPhone|iPod/.test(ua)) {
      window.open(APP_STORE_URL, "_blank", "noopener,noreferrer");
    } else if (/Android/.test(ua)) {
      window.open(PLAY_STORE_URL, "_blank", "noopener,noreferrer");
    } else {
      setShowVipModal(true);
    }
  };

  const features: Feature[] = [
    {
      icon: <MessageCircle size={20} />,
      title: t("home.features.chat.title") || "Chat with corrections",
      description:
        t("home.features.chat.description") ||
        "Send text, voice, photos, and stickers. Tap a partner's message to translate it or correct theirs in one tap.",
    },
    {
      icon: <Languages size={20} />,
      title: t("home.features.translate.title") || "Built-in translation",
      description:
        t("home.features.translate.description") ||
        "Translate any message into your native language. Save phrases straight into your study queue.",
    },
    {
      icon: <BookOpen size={20} />,
      title: t("home.features.tutor.title") || "AI Tutor",
      description:
        t("home.features.tutor.description") ||
        "Roleplay scenarios, image-based vocab, and pronunciation coaching — all powered by your own AI study partner.",
      mobileOnly: true,
    },
    {
      icon: <Mic size={20} />,
      title: t("home.features.voice_rooms.title") || "Voice Rooms",
      description:
        t("home.features.voice_rooms.description") ||
        "Hop into live audio rooms with native speakers and language learners around the world.",
      mobileOnly: true,
    },
    {
      icon: <Headphones size={20} />,
      title: t("home.features.calls.title") || "Voice & video calls",
      description:
        t("home.features.calls.description") ||
        "One-tap audio and video calls with your language partners. Recorded by no one — secured by LiveKit.",
      mobileOnly: true,
    },
    {
      icon: <Globe2 size={20} />,
      title: t("home.features.community.title") || "Real community",
      description:
        t("home.features.community.description") ||
        "Browse partners by native language, see who's online, and share moments with people learning the same language.",
    },
  ];

  const steps = [
    {
      number: "01",
      title: t("home.steps.profile.title") || "Tell us your languages",
      description:
        t("home.steps.profile.description") ||
        "Pick what you speak fluently and what you're learning. Add a few topics you like.",
    },
    {
      number: "02",
      title: t("home.steps.partners.title") || "Find your partner",
      description:
        t("home.steps.partners.description") ||
        "Browse the community by language, country, or topic. Wave or message someone interesting.",
    },
    {
      number: "03",
      title: t("home.steps.learn.title") || "Practice every day",
      description:
        t("home.steps.learn.description") ||
        "Chat, swap voice notes, get corrections, and turn new words into spaced-repetition cards.",
    },
  ];

  const plans: PricingPlan[] = [
    {
      name: t("home.pricing.free.name") || "Free",
      price: "$0",
      period: t("home.pricing.free.period") || "forever",
      features: [
        t("home.pricing.free.features.messaging") ||
          "Unlimited 1-on-1 chat with translation",
        t("home.pricing.free.features.community") ||
          "Browse and connect with the community",
        t("home.pricing.free.features.moments") ||
          "Post Moments and read Stories",
        t("home.pricing.free.features.tutor_trial") ||
          "Daily AI Tutor and translation quota",
      ],
      ctaLabel: t("home.pricing.free.cta") || "Create a free account",
      ctaHref: "/register",
    },
    {
      name: t("home.pricing.monthly.name") || "VIP — Monthly",
      price: "$14.99",
      period: t("home.pricing.monthly.period") || "per month",
      highlight: t("home.pricing.monthly.highlight") || "Most flexible",
      features: [
        t("home.pricing.monthly.features.unlimited_translation") ||
          "Unlimited translations and corrections",
        t("home.pricing.monthly.features.unlimited_tutor") ||
          "Unlimited AI Tutor sessions and roleplay",
        t("home.pricing.monthly.features.voice_rooms") ||
          "Host and pin Voice Rooms",
        t("home.pricing.monthly.features.priority") ||
          "Priority partner matching",
      ],
      ctaLabel: t("home.pricing.monthly.cta") || "Start monthly",
      isVip: true,
      popular: true,
    },
    {
      name: t("home.pricing.yearly.name") || "VIP — Yearly",
      price: "$49.99",
      period: t("home.pricing.yearly.period") || "per year",
      highlight: t("home.pricing.yearly.highlight") || "Save 72%",
      features: [
        t("home.pricing.yearly.features.everything_in_monthly") ||
          "Everything in Monthly",
        t("home.pricing.yearly.features.equiv") ||
          "Just $4.16 / month equivalent",
        t("home.pricing.yearly.features.early_access") ||
          "Early access to new features",
        t("home.pricing.yearly.features.support") ||
          "Direct support from the BananaTalk team",
      ],
      ctaLabel: t("home.pricing.yearly.cta") || "Save with yearly",
      isVip: true,
    },
  ];

  return (
    <div className="home-page">
      <section className="hero-section hero-section--clean">
        <div className="hero-content">
          <div className="hero-badge">
            <Sparkles size={14} />
            <span>{t("home.hero.badge") || "Language exchange, real people"}</span>
          </div>

          <h1 className="hero-title">
            {t("home.hero.titlePart1") || "Practice"}
            <span className="gradient-text">
              {" "}
              {t("home.hero.titleHighlight") || "any language"}
            </span>
            <br />
            {t("home.hero.titlePart2") || "with someone who actually speaks it."}
          </h1>

          <p className="hero-description">
            {t("home.hero.description") ||
              "BananaTalk pairs you with native speakers around the world. Chat, voice-message, translate, and get corrected — every conversation makes you better."}
          </p>

          <div className="hero-cta">
            <Link to="/register" className="btn-primary">
              {t("home.hero.getStarted") || "Get started — it's free"}
              <ArrowRight size={18} />
            </Link>
            <Link to="/communities" className="btn-secondary">
              {t("home.hero.browseCommunity") || "Browse the community"}
            </Link>
          </div>

          <div className="hero-trust hero-trust--rating">
            <div className="trust-stars">
              {[1, 2, 3, 4, 5].map((i) => (
                <Star
                  key={i}
                  size={16}
                  className="fill-yellow-400 text-yellow-400"
                />
              ))}
            </div>
            <span className="trust-text-line">
              {t("home.hero.lovedBy") ||
                "Loved by language learners on iOS and Android"}
            </span>
          </div>
        </div>

        <div className="hero-visual">
          <div className="phone-mockup">
            <div className="phone-screen">
              <div className="chat-preview">
                <div className="chat-message received">
                  <span>
                    {t("home.hero.chatPreview.message1") ||
                      "안녕하세요! How was your weekend?"}
                  </span>
                </div>
                <div className="chat-message sent">
                  <span>
                    {t("home.hero.chatPreview.message2") ||
                      "주말에 친구들과 등산 갔어요 ⛰️"}
                  </span>
                </div>
                <div className="chat-message received">
                  <span>
                    {t("home.hero.chatPreview.message3") ||
                      "Nice! 산 → mountain. Saved to your study queue."}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="download-banner">
        <div className="section-container">
          <div className="download-banner-inner">
            <div className="download-banner-qr">
              <img
                src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(
                  DOWNLOAD_LINK
                )}&color=111827&bgcolor=FFFFFF&format=svg`}
                alt="Download BananaTalk QR Code"
                width={140}
                height={140}
                className="qr-image"
              />
              <span className="qr-scan-text">
                {t("home.download.scanQR") || "Scan to download"}
              </span>
            </div>

            <div className="download-banner-info">
              <div className="download-banner-text">
                <h2 className="download-banner-title">
                  <Smartphone size={22} />
                  {t("home.download.title") ||
                    "The full experience lives on mobile"}
                </h2>
                <p className="download-banner-desc">
                  {t("home.download.description") ||
                    "AI Tutor, Voice Rooms, calls, and live notifications are mobile-only. Get the app for the complete BananaTalk experience."}
                </p>
              </div>
              <div className="download-banner-actions">
                <div className="store-buttons">
                  <a
                    href={APP_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="store-btn apple-btn"
                  >
                    <svg
                      viewBox="0 0 24 24"
                      width="22"
                      height="22"
                      fill="currentColor"
                    >
                      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                    </svg>
                    <div className="store-btn-text">
                      <span className="store-btn-label">
                        {t("home.download.downloadOn") || "Download on the"}
                      </span>
                      <span className="store-btn-name">App Store</span>
                    </div>
                  </a>
                  <a
                    href={PLAY_STORE_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="store-btn google-btn"
                  >
                    <svg
                      viewBox="0 0 24 24"
                      width="22"
                      height="22"
                      fill="currentColor"
                    >
                      <path d="M3.18 23.77c-.35-.17-.57-.5-.6-.87L2.55 1.14c-.03-.37.14-.73.45-.93l9.55 11.25L3.18 23.77zm1.39.27l9.12-10.75 2.77 3.27-11.14 7.22c-.23.15-.49.23-.75.26zm12.88-8.44l-2.73-3.22 2.73-3.22 3.11 2.01c.72.47.72 1.23 0 1.69l-3.11 2.74zM4.57.03l11.14 7.22-2.77 3.27L3.81.77C4.04.35 4.3.14 4.57.03z" />
                    </svg>
                    <div className="store-btn-text">
                      <span className="store-btn-label">
                        {t("home.download.getItOn") || "Get it on"}
                      </span>
                      <span className="store-btn-name">Google Play</span>
                    </div>
                  </a>
                </div>
                <div className="download-badges">
                  <span className="download-badge-item">
                    <Check size={14} />{" "}
                    {t("home.download.features.fast") || "Free to install"}
                  </span>
                  <span className="download-badge-item">
                    <Check size={14} />{" "}
                    {t("home.download.features.push") || "Push notifications"}
                  </span>
                  <span className="download-badge-item">
                    <Check size={14} />{" "}
                    {t("home.download.features.offline") ||
                      "Offline-friendly chat"}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="features-section">
        <div className="section-container">
          <div className="section-header">
            <span className="section-badge">
              {t("home.sections.features") || "What's inside"}
            </span>
            <h2 className="section-title">
              {t("home.features.title") || "Everything you need to actually speak the language"}
            </h2>
            <p className="section-description">
              {t("home.features.subtitle") ||
                "Built on real conversations with real native speakers — not vocabulary drills."}
            </p>
          </div>

          <div className="features-grid">
            {features.map((feature) => (
              <div key={feature.title} className="feature-card">
                <div className="feature-icon">{feature.icon}</div>
                <div className="feature-card__head">
                  <h3 className="feature-title">{feature.title}</h3>
                  {feature.mobileOnly && (
                    <span className="feature-mobile-tag">
                      <Smartphone size={11} />
                      Mobile
                    </span>
                  )}
                </div>
                <p className="feature-description">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="how-it-works-section">
        <div className="section-container">
          <div className="section-header">
            <span className="section-badge">
              {t("home.sections.howItWorks") || "How it works"}
            </span>
            <h2 className="section-title">
              {t("home.howItWorks.title") || "Three steps to your first conversation"}
            </h2>
            <p className="section-description">
              {t("home.howItWorks.subtitle") ||
                "No phone numbers, no spam — just real people who want to learn."}
            </p>
          </div>

          <div className="steps-grid">
            {steps.map((step, index) => (
              <div key={step.number} className="step-card">
                <div className="step-number">{step.number}</div>
                <h3 className="step-title">{step.title}</h3>
                <p className="step-description">{step.description}</p>
                {index < steps.length - 1 && (
                  <ChevronRight className="step-arrow" />
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="pricing-section">
        <div className="section-container">
          <div className="section-header">
            <span className="section-badge">
              {t("home.sections.pricing") || "Pricing"}
            </span>
            <h2 className="section-title">
              {t("home.pricing.title") || "Free to start. VIP when you're ready to learn faster."}
            </h2>
            <p className="section-description">
              {t("home.pricing.subtitle") ||
                "BananaTalk is free for everyone. Upgrade to remove daily limits on translations, AI Tutor, and more."}
            </p>
          </div>

          <div className="pricing-grid">
            {plans.map((plan) => (
              <div
                key={plan.name}
                className={`pricing-card ${plan.popular ? "popular" : ""}`}
              >
                {plan.highlight && (
                  <div className="popular-badge">{plan.highlight}</div>
                )}
                <h3 className="plan-name">{plan.name}</h3>
                <div className="plan-price">
                  <span className="price">{plan.price}</span>
                  <span className="period">{plan.period}</span>
                </div>
                <ul className="plan-features">
                  {plan.features.map((feat) => (
                    <li key={feat}>
                      <Check className="w-5 h-5 text-teal-500" />
                      <span>{feat}</span>
                    </li>
                  ))}
                </ul>
                {plan.isVip ? (
                  <button
                    type="button"
                    className={`plan-button ${plan.popular ? "primary" : "secondary"}`}
                    onClick={handleVipCta}
                  >
                    {plan.ctaLabel}
                  </button>
                ) : (
                  <Link
                    to={plan.ctaHref!}
                    className="plan-button secondary"
                  >
                    {plan.ctaLabel}
                  </Link>
                )}
              </div>
            ))}
          </div>

          <p className="pricing-fineprint">
            <ShieldCheck size={14} />
            {t("home.pricing.fineprint") ||
              "Cancel anytime in your App Store or Google Play settings. Subscriptions auto-renew until cancelled."}
          </p>
        </div>
      </section>

      <section className="cta-section">
        <div className="section-container">
          <div className="cta-content">
            <h2 className="cta-title">
              {t("home.cta.title") || "Ready to have a real conversation?"}
            </h2>
            <p className="cta-description">
              {t("home.cta.description") ||
                "Join the BananaTalk community and start practicing today. No credit card needed."}
            </p>
            <div className="cta-buttons">
              <Link to="/register" className="btn-primary large">
                {t("home.cta.button") || "Create your free account"}
                <ArrowRight size={18} />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* VIP App Redirect Modal */}
      {showVipModal && (
        <div className="vip-modal-backdrop" onClick={() => setShowVipModal(false)}>
          <div className="vip-modal" onClick={(e) => e.stopPropagation()}>
            <button
              className="vip-modal-close"
              onClick={() => setShowVipModal(false)}
              aria-label="Close"
            >
              <X size={20} />
            </button>

            <div className="vip-modal-icon">
              <Crown size={32} />
            </div>

            <h3 className="vip-modal-title">
              {t("home.vipModal.title") || "Subscribe via the App"}
            </h3>
            <p className="vip-modal-desc">
              {t("home.vipModal.desc") ||
                "VIP plans are purchased through the BananaTalk mobile app on the App Store or Google Play."}
            </p>

            <div className="vip-modal-stores">
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="vip-store-btn apple"
              >
                <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
                <div>
                  <span className="store-sub">Download on the</span>
                  <span className="store-name">App Store</span>
                </div>
              </a>

              <a
                href={PLAY_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="vip-store-btn google"
              >
                <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor">
                  <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z" />
                </svg>
                <div>
                  <span className="store-sub">Get it on</span>
                  <span className="store-name">Google Play</span>
                </div>
              </a>
            </div>

            <div className="vip-modal-qr">
              <img
                src={`https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${encodeURIComponent(DOWNLOAD_LINK)}&color=111827&bgcolor=FFFFFF&format=svg`}
                alt="Scan to download BananaTalk"
                width={100}
                height={100}
              />
              <span className="vip-modal-qr-label">
                {t("home.vipModal.scanQR") || "Scan to download"}
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default HomeMain;
