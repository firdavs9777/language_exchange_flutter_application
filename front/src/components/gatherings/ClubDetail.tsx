import React, { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import Loader from "../Loader";
import { useGetClubQuery, useJoinClubMutation, useLeaveClubMutation } from "../../store/slices/gatheringsSlice";
import { gatheringErrorText, personId, personName } from "./lib/gatheringFormat";
import GatheringCard from "./GatheringCard";
import GatheringSafetyMenu from "./GatheringSafetyMenu";
import ConfirmDialog from "./ConfirmDialog";
import ClubPeople from "./ClubPeople";
import ClubOwnerActions from "./ClubOwnerActions";
import CoverEditor from "./CoverEditor";

const ClubDetail: React.FC = () => {
  const { id = "" } = useParams();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { data: club, isLoading, isError } = useGetClubQuery(id, { skip: !id });
  const [join, joinState] = useJoinClubMutation();
  const [leave, leaveState] = useLeaveClubMutation();
  const [confirmLeave, setConfirmLeave] = useState(false);
  const busy = !!(joinState && joinState.isLoading) || !!(leaveState && leaveState.isLoading);

  if (isLoading) return <Loader />;
  if (isError || !club) {
    return (
      <section data-testid="club-unavailable" className="mx-auto max-w-xl px-4 py-16 text-center">
        <p className="text-lg font-bold">{t("gatherings.errors.clubGone") || "This club isn't available."}</p>
        <Link to="/gatherings?tab=clubs" className="mt-4 inline-block font-extrabold text-brand-dark">
          {t("clubs.detail.back") || "See other clubs"}
        </Link>
      </section>
    );
  }

  const run = async (fn: () => Promise<any>) => {
    try {
      await fn();
      setConfirmLeave(false);
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    }
  };
  const gatherings = club.gatherings || [];
  const past = club.pastCount || 0;
  const where = [club.place && club.place.name, club.place && club.place.address, club.city].filter(Boolean).join(" · ");

  return (
    <article data-testid="club-detail" className="mx-auto max-w-2xl px-4 py-6 text-start">
      {club.coverImage && <img src={club.coverImage} alt="" className="mb-4 h-44 w-full rounded-2xl object-cover" />}
      <div className="flex items-start gap-2">
        <div className="min-w-0 flex-1">
          <h1 className="text-2xl font-extrabold text-gray-900 dark:text-gray-50">{club.name}</h1>
          <p className="text-sm font-bold text-brand-dark dark:text-brand-light">
            {club.languageLabel || club.language}
            {club.interest ? ` · ${club.interest}` : ""}
          </p>
        </div>
        <GatheringSafetyMenu type="club" targetId={club._id} ownerId={personId(club.owner)} ownerName={personName(club.owner)}
          onBlocked={() => navigate("/gatherings?tab=clubs")} />
      </div>

      {where && <p className="mt-2 text-sm text-gray-700 dark:text-gray-200">{where}</p>}
      <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
        {past > 0
          ? t("clubs.detail.metTimes", { count: past }) || `Met ${past} times`
          : t("clubs.detail.neverMet") || "Hasn't met yet"}
      </p>
      {club.description && <p className="mt-4 whitespace-pre-wrap">{club.description}</p>}

      <div className="mt-5 flex flex-wrap gap-2">
        {!club.viewerIsMember && (
          <button type="button" data-testid="club-join" disabled={busy} onClick={() => run(() => join(club._id).unwrap())}
            className="rounded-full bg-brand px-5 py-2 font-extrabold text-white">
            {t("clubs.detail.join") || "Join club"}
          </button>
        )}
        {club.viewerIsMember && !club.viewerIsOwner && (
          <button type="button" data-testid="club-leave" disabled={busy} onClick={() => setConfirmLeave(true)}
            className="rounded-full border-2 border-gray-300 px-5 py-2 font-extrabold">
            {t("clubs.detail.leave") || "Leave club"}
          </button>
        )}
        {club.viewerIsOwner && (
          <p data-testid="club-owner-note" className="rounded-full bg-gray-100 px-4 py-2 text-sm dark:bg-gray-800">
            {t("clubs.detail.youOwn") || "You own this club"}
          </p>
        )}
        {club.viewerCanManage && (
          <Link to={`/clubs/${club._id}/edit`} data-testid="club-edit-link" className="rounded-full border-2 border-brand px-5 py-2 font-extrabold text-brand-dark no-underline">
            {t("clubs.detail.edit") || "Edit club"}
          </Link>
        )}
      </div>
      {club.viewerCanManage && (
        <div className="mt-3">
          <CoverEditor kind="club" id={club._id} hasCover={!!club.coverImage} />
        </div>
      )}

      <section className="mt-6">
        <div className="flex items-center">
          <h2 className="text-sm font-extrabold">{t("clubs.detail.upcoming") || "Coming up"}</h2>
          {club.viewerIsMember && (
            <Link to={`/gatherings/new?club=${club._id}`} data-testid="club-host-gathering-link" className="ms-auto text-sm font-extrabold text-brand-dark">
              {t("clubs.detail.host") || "Host a gathering for this club"}
            </Link>
          )}
        </div>
        {gatherings.length === 0 ? (
          <p data-testid="club-no-gatherings" className="mt-2 rounded-xl bg-gray-50 p-4 text-sm dark:bg-gray-800">
            {t("clubs.detail.noGatherings") || "Nothing planned yet."}
          </p>
        ) : (
          <div data-testid="club-gatherings" className="mt-2 grid gap-3">
            {gatherings.map((g) => (
              <GatheringCard key={g._id} gathering={g} />
            ))}
          </div>
        )}
      </section>

      <ClubPeople club={club} />
      {club.viewerIsOwner && <ClubOwnerActions club={club} />}

      {confirmLeave && (
        <ConfirmDialog
          title={t("clubs.detail.leaveTitle") || "Leave this club?"}
          confirmLabel={t("clubs.detail.leave") || "Leave club"}
          busy={busy}
          onConfirm={() => run(() => leave(club._id).unwrap())}
          onCancel={() => setConfirmLeave(false)}
        />
      )}
    </article>
  );
};

export default ClubDetail;
