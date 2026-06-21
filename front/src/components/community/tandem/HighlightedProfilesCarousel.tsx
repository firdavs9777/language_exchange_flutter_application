import React from "react";
import { Link } from "react-router-dom";
import { Zap } from "lucide-react";
import { useTranslation } from "react-i18next";
import LanguageFlagChip from "./LanguageFlagChip";
import { TandemMember } from "./TandemMemberCard";

interface HighlightedProfilesCarouselProps {
  profiles: TandemMember[];
  currentUser?: { _id?: string; name?: string; imageUrls?: string[] } | null;
  onTryPro?: () => void;
}

const HighlightedProfilesCarousel: React.FC<HighlightedProfilesCarouselProps> = ({
  profiles,
  currentUser,
  onTryPro,
}) => {
  const { t } = useTranslation();
  return (
    <section className="highlighted-banner">
      <header className="highlighted-banner__header">
        <div className="highlighted-banner__left">
          <h2>{t("communityMain.highlighted.title") || "Highlighted Profiles"}</h2>
          <span className="highlighted-banner__pro-chip">
            <Zap size={12} fill="currentColor" />
            {t("communityMain.highlighted.proBadge") || "Pro"}
          </span>
        </div>
      </header>

      <div className="highlighted-banner__track">
        {currentUser?._id && (
          <article className="highlighted-card highlighted-card--self">
            <div className="highlighted-card__avatar">
              <img
                src={currentUser.imageUrls?.[0] || "/default-avatar.png"}
                alt={currentUser.name || "You"}
              />
            </div>
            <h5>{currentUser.name || "You"}</h5>
            <p className="highlighted-card__topic">
              {t("communityMain.highlighted.highlightSelfTopic") ||
                "Highlight your profile and let more people see you"}
            </p>
            <button
              type="button"
              className="highlighted-card__pro-btn"
              onClick={onTryPro}
            >
              {t("communityMain.highlighted.tryPro") || "Try BananaTalk Pro"}
            </button>
          </article>
        )}

        {profiles.map((member) => {
          const isPro = member.isVIP || member.isVip;
          return (
            <Link
              key={member._id}
              to={`/community/${member._id}`}
              className="highlighted-card"
            >
              <div className="highlighted-card__avatar">
                <img
                  src={member.imageUrls?.[0] || "/default-avatar.png"}
                  alt={member.name}
                  loading="lazy"
                />
                {isPro && (
                  <span className="highlighted-card__pro-badge" aria-label="Pro">
                    <Zap size={12} fill="currentColor" />
                  </span>
                )}
              </div>
              <h5>{member.name}</h5>
              <p className="highlighted-card__topic">
                {member.topic ||
                  member.bio ||
                  t("communityMain.tandemCard.defaultTopic") ||
                  "Let's practice!"}
              </p>
              <div className="highlighted-card__languages">
                <LanguageFlagChip label="FLUENT" language={member.native_language} />
                <LanguageFlagChip
                  label="LEARNS"
                  language={member.language_to_learn}
                  extra={member.learnsExtras}
                />
              </div>
            </Link>
          );
        })}
      </div>
    </section>
  );
};

export default HighlightedProfilesCarousel;
