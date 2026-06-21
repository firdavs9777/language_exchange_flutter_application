import React from "react";
import { Link } from "react-router-dom";
import { Zap } from "lucide-react";
import { useTranslation } from "react-i18next";
import LanguageFlagChip from "./LanguageFlagChip";

export interface TandemMember {
  _id: string;
  name: string;
  imageUrls?: string[];
  bio?: string;
  topic?: string;
  native_language?: string;
  language_to_learn?: string;
  isVIP?: boolean;
  isVip?: boolean;
  isOnline?: boolean;
  isNew?: boolean;
  createdAt?: string;
  fluentExtras?: number;
  learnsExtras?: number;
}

interface TandemMemberCardProps {
  member: TandemMember;
}

const isRecentlyJoined = (createdAt?: string): boolean => {
  if (!createdAt) return false;
  const created = new Date(createdAt).getTime();
  if (Number.isNaN(created)) return false;
  const SEVEN_DAYS = 7 * 24 * 60 * 60 * 1000;
  return Date.now() - created < SEVEN_DAYS;
};

const TandemMemberCard: React.FC<TandemMemberCardProps> = ({ member }) => {
  const { t } = useTranslation();
  const avatar = member.imageUrls?.[0] || "/default-avatar.png";
  const isPro = member.isVIP || member.isVip;
  const isNew = member.isNew ?? isRecentlyJoined(member.createdAt);
  const topic =
    member.topic ||
    member.bio ||
    t("communityMain.tandemCard.defaultTopic") ||
    "Let's practice!";

  return (
    <Link to={`/community/${member._id}`} className="tandem-member-card" id={member._id}>
      <div className="tandem-member-card__picture">
        {isPro && (
          <span className="tandem-member-card__pro-icon" aria-label="Pro member">
            <Zap size={14} fill="currentColor" />
          </span>
        )}
        <img src={avatar} alt={member.name} loading="lazy" />
        {member.isOnline && <span className="tandem-member-card__online" aria-label="Online" />}
      </div>

      <div className="tandem-member-card__content">
        <div className="tandem-member-card__bio">
          <div className="tandem-member-card__first-row">
            <h3>{member.name}</h3>
            {isNew && (
              <div className="tandem-member-card__chip tandem-member-card__chip--new">
                <span>{t("communityMain.tandemCard.newChip") || "NEW"}</span>
              </div>
            )}
          </div>
          <p className="tandem-member-card__topic">{topic}</p>
        </div>

        <div className="tandem-member-card__languages">
          <LanguageFlagChip
            label="FLUENT"
            language={member.native_language}
            extra={member.fluentExtras}
          />
          <LanguageFlagChip
            label="LEARNS"
            language={member.language_to_learn}
            extra={member.learnsExtras}
          />
        </div>
      </div>
    </Link>
  );
};

export default TandemMemberCard;
