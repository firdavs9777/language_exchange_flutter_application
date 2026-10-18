import React, { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import Loader from "../Loader";
import { useGetGatheringQuery, useRsvpGatheringMutation, useCancelRsvpMutation } from "../../store/slices/gatheringsSlice";
import {
  formatGatheringTime,
  hostLocalTime,
  quorumLine,
  rsvpState,
  statusLabel,
  topicLabel,
  gatheringErrorText,
  personId,
  personName,
} from "./lib/gatheringFormat";
import GatheringSafetyMenu from "./GatheringSafetyMenu";
import ConfirmDialog from "./ConfirmDialog";
import GatheringHostPanel from "./GatheringHostPanel";
import { photoUrl } from "../../utils/photoUrl";

const GatheringDetail: React.FC = () => {
  const { id = "" } = useParams();
  const navigate = useNavigate();
  const { t, i18n } = useTranslation();
  const { data: g, isLoading, isError, refetch } = useGetGatheringQuery(id, { skip: !id });
  const [rsvp, rsvpState_] = useRsvpGatheringMutation();
  const [leave, leaveState] = useCancelRsvpMutation();
  const [confirmLeave, setConfirmLeave] = useState(false);
  const busy = !!(rsvpState_ && rsvpState_.isLoading) || !!(leaveState && leaveState.isLoading);

  if (isLoading) return <Loader />;
  if (isError || !g) {
    return (
      <section data-testid="gathering-unavailable" className="mx-auto max-w-xl px-4 py-16 text-center">
        <p className="text-lg font-bold">{t("gatherings.errors.gatheringGone") || "This gathering isn't available."}</p>
        <Link to="/gatherings" className="mt-4 inline-block font-extrabold text-brand-dark">
          {t("gatherings.detail.back") || "See other gatherings"}
        </Link>
      </section>
    );
  }

  const state = rsvpState(g);
  const hostId = personId(g.host);
  const hostName = personName(g.host);
  const hostAvatar = g.host && typeof g.host === "object" ? photoUrl(g.host.images) : undefined;
  const hostTime = hostLocalTime(g, i18n.language);

  const doRsvp = async () => {
    try {
      const res: any = await rsvp(id).unwrap();
      notify.success(
        res && res.pending
          ? t("gatherings.detail.requestSent") || "Request sent. The host will decide."
          : t("gatherings.detail.youreGoing") || "You're going."
      );
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
      refetch();
    }
  };
  const doLeave = async () => {
    try {
      await leave(id).unwrap();
      setConfirmLeave(false);
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    }
  };

  return (
    <article data-testid="gathering-detail" className="mx-auto max-w-2xl px-4 py-6 text-start">
      {g.coverImage && <img src={g.coverImage} alt="" className="mb-4 h-48 w-full rounded-2xl object-cover" />}
      <div className="flex items-start gap-2">
        <div className="min-w-0 flex-1">
          <p className="text-xs font-bold uppercase text-brand-dark dark:text-brand-light">{statusLabel(g.status, t)}</p>
          <h1 className="text-2xl font-extrabold text-gray-900 dark:text-gray-50">{g.title}</h1>
        </div>
        <GatheringSafetyMenu type="gathering" targetId={g._id} ownerId={hostId} ownerName={hostName} onBlocked={() => navigate("/gatherings")} />
      </div>

      <p data-testid="gathering-time" className="mt-2 font-semibold">
        {formatGatheringTime(g.startsAt, i18n.language)}
        {" · "}
        {t("gatherings.detail.duration", { count: g.durationMinutes }) || `${g.durationMinutes} min`}
      </p>
      {hostTime && (
        <p data-testid="gathering-host-time" className="text-sm text-gray-600 dark:text-gray-300">
          {t("gatherings.time.hostLocal", { time: hostTime }) || `${hostTime} for the host`}
        </p>
      )}

      <div className="mt-3 flex flex-wrap gap-2 text-xs">
        <span className="rounded-full bg-gray-100 px-2 py-0.5 dark:bg-gray-800">{g.languageLabel || g.language}</span>
        {g.level && <span className="rounded-full bg-gray-100 px-2 py-0.5 dark:bg-gray-800">{g.level}</span>}
        {g.topic && <span className="rounded-full bg-gray-100 px-2 py-0.5 dark:bg-gray-800">{topicLabel(g.topic, t)}</span>}
        <span className="rounded-full bg-gray-100 px-2 py-0.5 dark:bg-gray-800">
          {t("gatherings.detail.online") || "Online"}
        </span>
      </div>

      <p data-testid="gathering-quorum" className="mt-4 text-base font-bold">{quorumLine(g, t)}</p>
      <p className="text-sm text-gray-600 dark:text-gray-300">
        {t("gatherings.detail.capacity", { count: g.capacity, quorum: g.quorum }) ||
          `Up to ${g.capacity} people · confirms at ${g.quorum}`}
      </p>

      {g.description && <p className="mt-4 whitespace-pre-wrap text-gray-800 dark:text-gray-100">{g.description}</p>}

      {hostId && (
        <Link to={`/profile/${hostId}`} data-testid="gathering-host-link" className="mt-5 flex items-center gap-3 no-underline">
          {hostAvatar ? (
            <img src={hostAvatar} alt="" className="h-10 w-10 rounded-full object-cover" />
          ) : (
            <span className="h-10 w-10 rounded-full bg-gray-200" />
          )}
          <span className="text-sm">
            <span className="block text-gray-500">{t("gatherings.detail.host") || "Host"}</span>
            <span className="font-bold text-gray-900 dark:text-gray-50">{hostName || t("gatherings.detail.someone") || "A BananaTalk member"}</span>
            {(g.hostCity || g.hostCountry) && (
              <span className="block text-xs text-gray-500">{[g.hostCity, g.hostCountry].filter(Boolean).join(", ")}</span>
            )}
          </span>
        </Link>
      )}

      <div className="mt-6">
        {state === "join" && (
          <button type="button" data-testid="gathering-rsvp" disabled={busy} onClick={doRsvp} className="w-full rounded-full bg-brand px-5 py-3 font-extrabold text-white">
            {t("gatherings.detail.join") || "I'm going"}
          </button>
        )}
        {state === "request" && (
          <button type="button" data-testid="gathering-rsvp" disabled={busy} onClick={doRsvp} className="w-full rounded-full bg-brand px-5 py-3 font-extrabold text-white">
            {t("gatherings.detail.askToJoin") || "Ask to join"}
          </button>
        )}
        {state === "going" && (
          <button type="button" data-testid="gathering-leave" disabled={busy} onClick={() => setConfirmLeave(true)} className="w-full rounded-full border-2 border-gray-300 px-5 py-3 font-extrabold">
            {t("gatherings.detail.leave") || "I can't go any more"}
          </button>
        )}
        {state === "pending" && (
          <button type="button" data-testid="gathering-cancel-request" disabled={busy} onClick={doLeave} className="w-full rounded-full border-2 border-gray-300 px-5 py-3 font-extrabold">
            {t("gatherings.detail.cancelRequest") || "Cancel my request"}
          </button>
        )}
        {state === "full" && (
          <p data-testid="gathering-full" className="rounded-full bg-gray-100 px-5 py-3 text-center font-bold dark:bg-gray-800">
            {t("gatherings.card.full") || "Full"}
          </p>
        )}
        {state === "closed" && (
          <p data-testid="gathering-closed" className="rounded-full bg-gray-100 px-5 py-3 text-center font-bold dark:bg-gray-800">
            {statusLabel(g.status, t)}
          </p>
        )}
        {state === "host" && (
          <Link to={`/gatherings/${g._id}/edit`} data-testid="gathering-edit-link" className="block w-full rounded-full border-2 border-brand px-5 py-3 text-center font-extrabold text-brand-dark no-underline">
            {t("gatherings.detail.edit") || "Edit gathering"}
          </Link>
        )}
        {state === "host" && <GatheringHostPanel gathering={g} />}
      </div>

      {confirmLeave && (
        <ConfirmDialog
          title={t("gatherings.confirm.leaveTitle") || "Give up your seat?"}
          body={t("gatherings.confirm.leaveBody") || "The others are counting on the people who said yes."}
          confirmLabel={t("gatherings.confirm.leaveOk") || "Give up my seat"}
          danger
          busy={busy}
          onConfirm={doLeave}
          onCancel={() => setConfirmLeave(false)}
        />
      )}
    </article>
  );
};

export default GatheringDetail;
