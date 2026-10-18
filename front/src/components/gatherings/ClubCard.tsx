import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Club } from "../../store/slices/gatheringsSlice";
import { photoUrl } from "../../utils/photoUrl";

const ClubCard: React.FC<{ club: Club }> = ({ club: c }) => {
  const { t } = useTranslation();
  const count = c.memberCount || 0;
  return (
    <Link
      to={`/clubs/${c._id}`}
      data-testid={`club-card-${c._id}`}
      className="block rounded-2xl border border-gray-200 bg-white p-4 text-start no-underline shadow-sm hover:shadow dark:border-gray-700 dark:bg-gray-900"
    >
      {c.coverImage && (
        <img src={c.coverImage} alt="" className="mb-3 h-28 w-full rounded-xl object-cover" loading="lazy" />
      )}
      <h3 className="text-base font-extrabold text-gray-900 dark:text-gray-50">{c.name}</h3>
      <p className="mt-1 text-xs font-bold text-brand-dark dark:text-brand-light">
        {c.languageLabel || c.language}
        {c.interest ? ` · ${c.interest}` : ""}
      </p>
      <div className="mt-2 flex items-center gap-2">
        <div className="flex -space-x-2 rtl:space-x-reverse">
          {(c.members || []).slice(0, 4).map((m) => {
            const src = photoUrl(m.images);
            return src ? (
              <img key={m._id} src={src} alt="" className="h-6 w-6 rounded-full border-2 border-white object-cover" />
            ) : (
              <span key={m._id} className="h-6 w-6 rounded-full border-2 border-white bg-gray-200" />
            );
          })}
        </div>
        <span className="text-sm text-gray-700 dark:text-gray-200">
          {t("clubs.card.members", { count }) || `${count} members`}
        </span>
        {c.viewerIsMember && (
          <span className="ms-auto rounded-full bg-brand px-2 py-0.5 text-xs font-bold text-white">
            {t("clubs.card.joined") || "Joined"}
          </span>
        )}
      </div>
    </Link>
  );
};

export default ClubCard;
