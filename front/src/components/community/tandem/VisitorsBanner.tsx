import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";

interface VisitorAvatar {
  _id: string;
  name?: string;
  imageUrls?: string[];
  photo?: string;
}

interface VisitorsBannerProps {
  visitors: VisitorAvatar[];
  totalCount: number;
}

const VisitorsBanner: React.FC<VisitorsBannerProps> = ({ visitors, totalCount }) => {
  const { t } = useTranslation();
  if (!visitors.length || totalCount === 0) return null;

  const featuredName = visitors[0]?.name || "Someone";
  const otherCount = Math.max(totalCount - 1, 0);
  const previewAvatars = visitors.slice(0, 3);
  const remaining = Math.max(totalCount - previewAvatars.length, 0);

  const headline =
    otherCount > 0
      ? t("communityMain.visitors.andOthers", {
          name: featuredName,
          count: otherCount,
        }) ||
        `${featuredName} and ${otherCount} others visited your profile!`
      : t("communityMain.visitors.justYou", { name: featuredName }) ||
        `${featuredName} visited your profile!`;

  return (
    <div className="visitors-banner">
      <h3>{headline}</h3>
      <div className="visitors-banner__bottom">
        <div className="visitors-banner__members">
          <div className="visitors-banner__avatars">
            {previewAvatars.map((visitor) => (
              <img
                key={visitor._id}
                src={visitor.imageUrls?.[0] || visitor.photo || "/default-avatar.png"}
                alt={visitor.name || "Visitor's Profile"}
                loading="lazy"
              />
            ))}
          </div>
          {remaining > 0 && <p>+{remaining}</p>}
        </div>
        <Link to="/visitors" className="visitors-banner__see-all">
          {t("communityMain.visitors.seeAll") || "See all"}
        </Link>
      </div>
    </div>
  );
};

export default VisitorsBanner;
