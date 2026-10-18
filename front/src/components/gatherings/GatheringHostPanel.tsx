import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import {
  Gathering,
  useDecideJoinRequestMutation,
  useHostDecisionMutation,
  useCancelGatheringMutation,
  useEndGatheringMutation,
} from "../../store/slices/gatheringsSlice";
import { isHostDecisionDue, minutesUntil, gatheringErrorText, personName } from "./lib/gatheringFormat";
import ConfirmDialog from "./ConfirmDialog";
import CoverEditor from "./CoverEditor";
import { photoUrl } from "../../utils/photoUrl";

/**
 * Everything only the host can do, in the app's order: answer join requests,
 * answer the T-2h "run it anyway?" question, end it once it has started, and
 * -- last, because it strands everyone who said yes -- cancel it.
 */
const GatheringHostPanel: React.FC<{ gathering: Gathering; now?: Date }> = ({ gathering: g, now }) => {
  const { t } = useTranslation();
  const [decide] = useDecideJoinRequestMutation();
  const [decision] = useHostDecisionMutation();
  const [cancel] = useCancelGatheringMutation();
  const [end] = useEndGatheringMutation();
  const [confirm, setConfirm] = useState<"" | "callOff" | "cancel">("");
  const [busy, setBusy] = useState(false);

  if (!g.viewerIsHost || g.status === "cancelled" || g.status === "ended") return null;
  const at = now || new Date();
  const started = minutesUntil(g.startsAt, at) <= 0;
  const requests = g.requests || [];
  // Everyone the host would let down: the people going, minus the host.
  const expecting = Math.max(0, (g.going || 0) - 1);

  const run = async (fn: () => Promise<any>, success?: string) => {
    setBusy(true);
    try {
      await fn();
      if (success) notify.success(success);
      setConfirm("");
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div data-testid="host-panel" className="mt-4 grid gap-4">
      <CoverEditor kind="gathering" id={g._id} hasCover={!!g.coverImage} />
      {requests.length > 0 && (
        <section data-testid="host-requests" className="rounded-2xl border border-gray-200 p-4 dark:border-gray-700">
          <h2 className="text-sm font-extrabold">
            {t("gatherings.host.requests", { count: requests.length }) || `${requests.length} waiting to join`}
          </h2>
          <ul className="mt-2 grid gap-2">
            {requests.map((p) => {
              const src = photoUrl(p.images);
              return (
                <li key={p._id} data-testid={`host-request-${p._id}`} className="flex items-center gap-2">
                  {src ? <img src={src} alt="" className="h-8 w-8 rounded-full object-cover" /> : <span className="h-8 w-8 rounded-full bg-gray-200" />}
                  <span className="flex-1 truncate text-sm font-bold">{personName(p) || t("gatherings.detail.someone") || "A BananaTalk member"}</span>
                  <button type="button" data-testid={`host-approve-${p._id}`} disabled={busy}
                    onClick={() => run(() => decide({ id: g._id, userId: p._id, approve: true }).unwrap())}
                    className="rounded-full bg-brand px-3 py-1 text-xs font-extrabold text-white">
                    {t("gatherings.host.approve") || "Approve"}
                  </button>
                  <button type="button" data-testid={`host-decline-${p._id}`} disabled={busy}
                    onClick={() => run(() => decide({ id: g._id, userId: p._id, approve: false }).unwrap())}
                    className="rounded-full border border-gray-300 px-3 py-1 text-xs font-bold">
                    {t("gatherings.host.decline") || "Decline"}
                  </button>
                </li>
              );
            })}
          </ul>
        </section>
      )}

      {isHostDecisionDue(g, at) && (
        <section data-testid="host-decision" className="rounded-2xl bg-amber-50 p-4 text-amber-900">
          <p className="text-sm font-bold">
            {g.going <= 1
              ? t("gatherings.host.decisionAlone") || "Only you are coming so far. Run it anyway, or call it off?"
              : t("gatherings.host.decision", { count: g.going }) || `Only ${g.going} people are coming so far. Run it anyway, or call it off?`}
          </p>
          <div className="mt-3 flex gap-2">
            <button type="button" data-testid="host-run-anyway" disabled={busy}
              onClick={() => run(() => decision({ id: g._id, run: true }).unwrap())}
              className="flex-1 rounded-full bg-brand px-4 py-2 text-sm font-extrabold text-white">
              {t("gatherings.host.runAnyway") || "Run it anyway"}
            </button>
            <button type="button" data-testid="host-call-off" disabled={busy} onClick={() => setConfirm("callOff")}
              className="flex-1 rounded-full border-2 border-amber-700 px-4 py-2 text-sm font-extrabold">
              {t("gatherings.host.callOff") || "Call it off"}
            </button>
          </div>
        </section>
      )}

      {started && (
        <button type="button" data-testid="host-end" disabled={busy}
          onClick={() => run(() => end(g._id).unwrap(), t("gatherings.host.ended") || "Ended — message anyone you met, it's free")}
          className="w-full rounded-full bg-brand px-5 py-3 font-extrabold text-white">
          {t("gatherings.host.end") || "End gathering"}
        </button>
      )}

      <button type="button" data-testid="host-cancel" disabled={busy} onClick={() => setConfirm("cancel")}
        className="w-full rounded-full px-5 py-2 text-sm font-bold text-red-700">
        {t("gatherings.host.cancel") || "Cancel gathering"}
      </button>

      {confirm && (
        <ConfirmDialog
          title={confirm === "callOff" ? t("gatherings.host.callOffTitle") || "Call it off?" : t("gatherings.host.cancelTitle") || "Cancel this gathering?"}
          body={
            expecting === 0
              ? t("gatherings.host.nobodyExpecting") || "Nobody else has said yes yet."
              : t("gatherings.host.cancelConfirm", { count: expecting }) ||
                `${expecting} ${expecting === 1 ? "person is" : "people are"} expecting this. They'll be told it's off.`
          }
          confirmLabel={confirm === "callOff" ? t("gatherings.host.callOff") || "Call it off" : t("gatherings.host.cancelOk") || "Cancel gathering"}
          danger
          busy={busy}
          onConfirm={() =>
            run(() => (confirm === "callOff" ? decision({ id: g._id, run: false }).unwrap() : cancel(g._id).unwrap()))
          }
          onCancel={() => setConfirm("")}
        />
      )}
    </div>
  );
};

export default GatheringHostPanel;
