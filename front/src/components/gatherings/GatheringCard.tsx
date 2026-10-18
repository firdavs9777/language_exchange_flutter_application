import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Gathering } from "../../store/slices/gatheringsSlice";
import { formatGatheringTime, quorumLine, seatsLeft, topicLabel, personName, rsvpState } from "./lib/gatheringFormat";

const GatheringCard: React.FC<{ gathering: Gathering }> = ({ gathering: g }) => {
  const { t, i18n } = useTranslation();
  const state = rsvpState(g);
  const seats = seatsLeft(g);
  const host = personName(g.host);
  return (
    <Link
      to={`/gatherings/${g._id}`}
      data-testid={`gathering-card-${g._id}`}
      className="block rounded-2xl border border-gray-200 bg-white p-4 text-start no-underline shadow-sm hover:shadow dark:border-gray-700 dark:bg-gray-900"
    >
      {g.coverImage && (
        <img src={g.coverImage} alt="" className="mb-3 h-32 w-full rounded-xl object-cover" loading="lazy" />
      )}
      <div className="flex items-center gap-2 text-xs font-bold text-brand-dark dark:text-brand-light">
        <span>{formatGatheringTime(g.startsAt, i18n.language)}</span>
        <span aria-hidden>·</span>
        <span>{g.languageLabel || g.language}</span>
        {g.topic && (
          <>
            <span aria-hidden>·</span>
            <span>{topicLabel(g.topic, t)}</span>
          </>
        )}
      </div>
      <h3 className="mt-1 text-base font-extrabold text-gray-900 dark:text-gray-50">{g.title}</h3>
      {host && (
        <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
          {t("gatherings.card.hostedBy", { name: host }) || `Hosted by ${host}`}
        </p>
      )}
      <p className="mt-2 text-sm font-semibold text-gray-800 dark:text-gray-100">{quorumLine(g, t)}</p>
      <div className="mt-2 flex flex-wrap gap-2 text-xs">
        {state === "going" && (
          <span className="rounded-full bg-brand px-2 py-0.5 font-bold text-white">
            {t("gatherings.card.going") || "Going"}
          </span>
        )}
        {state === "pending" && (
          <span className="rounded-full bg-amber-100 px-2 py-0.5 font-bold text-amber-800">
            {t("gatherings.card.requested") || "Requested"}
          </span>
        )}
        {state === "host" && (
          <span className="rounded-full bg-gray-900 px-2 py-0.5 font-bold text-white">
            {t("gatherings.card.hosting") || "You're hosting"}
          </span>
        )}
        {state !== "closed" && (
          <span className="rounded-full bg-gray-100 px-2 py-0.5 text-gray-700 dark:bg-gray-800 dark:text-gray-200">
            {seats === 0
              ? t("gatherings.card.full") || "Full"
              : t("gatherings.card.seatsLeft", { count: seats }) || `${seats} seats left`}
          </span>
        )}
        {g.joinMode === "approval" && (
          <span className="rounded-full bg-gray-100 px-2 py-0.5 text-gray-700 dark:bg-gray-800 dark:text-gray-200">
            {t("gatherings.card.approval") || "Host approves"}
          </span>
        )}
      </div>
    </Link>
  );
};

export default GatheringCard;
