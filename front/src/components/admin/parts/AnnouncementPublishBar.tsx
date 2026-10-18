import React from "react";
import { useTranslation } from "react-i18next";
import {
  usePublishAnnouncementMutation,
  useEndAnnouncementMutation,
  useLazyGetAnnouncementAudienceQuery,
  AnnouncementStatus,
} from "../../../store/slices/adminSlice";
import ConfirmDialog from "./ConfirmDialog";

export interface AnnouncementPublishBarProps {
  /** null until the first save of a new announcement. */
  announcementId: string | null;
  status: AnnouncementStatus;
  /** The form's "Send notification" switch. */
  notify: boolean;
  /** The form's start time as ISO, sent as `at` when scheduling. */
  startsAtIso: string | null;
  /** Validate and save the form; resolves to the saved id, or null if it did not save. */
  prepare: (mode: "publish" | "schedule") => Promise<string | null>;
  onDone: (message: string) => void;
  /** The editor is busy (e.g. an image is uploading): no action may start. */
  disabled?: boolean;
  /** The saved row's updatedAt: a change means a refetch landed, so the buttons may re-arm. */
  updatedAt?: string | null;
  /** Bump to ask the bar to run the Schedule path (save, fresh count, confirm) on the editor's behalf. */
  scheduleRequest?: number;
  /**
   * The editor asked for the schedule path and the admin backed out after the save
   * (cancelled the confirm, or the audience count failed): the editor reverts the save.
   */
  onScheduleCancelled?: () => void;
}

type Mode = "publish" | "schedule";

type Pending =
  | { kind: "publish"; mode: Mode; id: string; count: number; listed: number; webOnly?: boolean }
  | { kind: "end"; id: string }
  | null;

const errorMessage = (err: any, fallback: string): string =>
  (err && err.data && err.data.message) || (err && err.message) || fallback;

/**
 * The three actions that reach users. Publishing with "Send notification" on
 * pushes to everyone in the audience, so it always asks first and shows how
 * many people that is — fetched fresh from the server, after the save, so the
 * number matches the targeting that will actually be used.
 */
const AnnouncementPublishBar: React.FC<AnnouncementPublishBarProps> = ({
  announcementId, status, notify, startsAtIso, prepare, onDone, disabled = false, updatedAt = null, scheduleRequest = 0, onScheduleCancelled,
}) => {
  const { t } = useTranslation();
  const [publish, publishState] = usePublishAnnouncementMutation();
  const [end, endState] = useEndAnnouncementMutation();
  const [fetchAudience] = useLazyGetAnnouncementAudienceQuery();
  const [pending, setPending] = React.useState<Pending>(null);
  const [working, setWorking] = React.useState(false);
  const [error, setError] = React.useState("");
  const [dialogError, setDialogError] = React.useState("");
  // After a successful action the buttons stay off until the refetched status
  // (or start time) arrives, so Publish now can't be clicked again in the gap.
  const [finished, setFinished] = React.useState(false);
  // updatedAt too: re-scheduling a scheduled row with the same start changes neither
  // status nor start, but the refetched row has a new updatedAt.
  React.useEffect(() => { setFinished(false); }, [status, startsAtIso, updatedAt]);
  // Synchronous: state updates land a render late, so a fast second click would
  // otherwise slip through before `busy` disables the button.
  const inFlight = React.useRef(false);

  const canPublish = status === "draft" || status === "scheduled";
  const canEnd = status === "scheduled" || status === "live";
  const fallback = t("admin.common.actionError") || "Something went wrong.";

  // Follows what the server did: a schedule whose start had passed goes live at once.
  const doneMessage = (mode: Mode, result?: { status?: string } | null) =>
    (result && result.status ? result.status === "scheduled" : mode === "schedule")
      ? t("admin.announcements.scheduledDone") || "Scheduled."
      : t("admin.announcements.publishedDone") || "Published.";
  const atFor = (mode: Mode) => (mode === "schedule" ? startsAtIso || undefined : undefined);

  const fromEditor = React.useRef(false);
  const start = async (mode: Mode, requested = false) => {
    if (inFlight.current) return;
    inFlight.current = true;
    fromEditor.current = requested;
    setError("");
    setWorking(true);
    try {
      const id = await prepare(mode);
      if (!id) return;
      if (!notify) {
        // No push: nothing irreversible reaches anyone's phone, so no dialog.
        try {
          const done = await publish({ id, at: atFor(mode) }).unwrap();
          setFinished(true);
          onDone(doneMessage(mode, done));
        } catch (err) {
          setError(errorMessage(err, fallback));
        }
        return;
      }
      try {
        const audience: { count: number; listed: number; reason?: string } = await fetchAudience(id).unwrap();
        setDialogError("");
        setPending({ kind: "publish", mode, id, count: audience.count, listed: audience.listed, webOnly: audience.reason === "web_only" });
      } catch (err) {
        setError(errorMessage(err, t("admin.announcements.audienceError") || "Couldn't count the audience."));
        if (fromEditor.current) { fromEditor.current = false; if (onScheduleCancelled) onScheduleCancelled(); }
      }
    } finally {
      inFlight.current = false;
      setWorking(false);
    }
  };

  // The editor's Save on a scheduled row routes here (see AdminAnnouncementEditor).
  const lastRequest = React.useRef(scheduleRequest);
  const startRef = React.useRef(start);
  startRef.current = start;
  React.useEffect(() => {
    if (scheduleRequest === lastRequest.current) return;
    lastRequest.current = scheduleRequest;
    if (scheduleRequest > 0) startRef.current("schedule", true);
  }, [scheduleRequest]);

  const confirm = async () => {
    if (!pending || inFlight.current) return;
    inFlight.current = true;
    try {
      if (pending.kind === "publish") {
        const mode = pending.mode;
        // The start was checked when the dialog opened; the admin may have sat on it.
        // Past `at` is treated as "now" by the server, which would push immediately.
        if (mode === "schedule" && startsAtIso && new Date(startsAtIso) <= new Date()) {
          setDialogError(t("admin.announcements.startPassed") || "The start time has passed. Cancel, pick a later start and schedule again.");
          return;
        }
        const done = await publish({ id: pending.id, at: atFor(mode) }).unwrap();
        setPending(null);
        fromEditor.current = false;
        setFinished(true);
        onDone(doneMessage(mode, done));
      } else {
        await end(pending.id).unwrap();
        setPending(null);
        setFinished(true);
        onDone(t("admin.announcements.endedDone") || "Ended.");
      }
    } catch (err) {
      setDialogError(errorMessage(err, fallback));
    } finally {
      inFlight.current = false;
    }
  };

  const busy = disabled || finished || working || publishState.isLoading || endState.isLoading;
  const buttonClass = "rounded-chip px-3 py-1.5 text-sm font-medium disabled:opacity-60";

  const dialogBody = () => {
    if (!pending) return null;
    if (pending.kind === "end") {
      return t("admin.announcements.endBody") || "It disappears from the app now. Notifications already sent stay in people's lists.";
    }
    const when = pending.mode === "schedule"
      ? t("admin.announcements.atStart") || "at the scheduled start"
      : t("admin.announcements.now") || "now";
    if (pending.webOnly) return "Website only — no push notifications, no app notification rows.";
    return `Sends a push notification to ${pending.count.toLocaleString("en-US")} people ${when} and adds it to ${pending.listed.toLocaleString("en-US")} notification lists.`;
  };

  if (!canPublish && !canEnd) return null;

  return (
    <div className="flex flex-wrap items-center gap-2" data-testid="publish-bar">
      {canPublish ? (
        <>
          <button type="button" disabled={busy} onClick={() => start("schedule")}
            className={`${buttonClass} border border-line text-ink-700 hover:bg-ink-100 dark:border-line-dark dark:text-ink-200`}>
            {t("admin.announcements.schedule") || "Schedule"}
          </button>
          <button type="button" disabled={busy} onClick={() => start("publish")}
            className={`${buttonClass} bg-brand-deep text-white hover:opacity-90`}>
            {t("admin.announcements.publishNow") || "Publish now"}
          </button>
        </>
      ) : null}
      {canEnd && announcementId ? (
        <button type="button" disabled={busy} onClick={() => { setDialogError(""); setPending({ kind: "end", id: announcementId }); }}
          className={`${buttonClass} border border-red-300 text-red-700 hover:bg-red-50`}>
          {t("admin.announcements.endNow") || "End now"}
        </button>
      ) : null}
      {error ? <p role="alert" className="w-full text-sm text-red-600">{error}</p> : null}

      <ConfirmDialog
        open={!!pending}
        title={
          pending && pending.kind === "end"
            ? t("admin.announcements.endTitle") || "End this announcement?"
            : pending && pending.mode === "schedule"
              ? t("admin.announcements.scheduleTitle") || "Schedule this announcement?"
              : t("admin.announcements.publishTitle") || "Publish this announcement?"
        }
        body={dialogBody()}
        confirmLabel={
          pending && pending.kind === "end"
            ? t("admin.announcements.endNow") || "End now"
            : pending && pending.mode === "schedule"
              ? t("admin.announcements.schedule") || "Schedule"
              : t("admin.announcements.publishNow") || "Publish now"
        }
        cancelLabel={t("admin.common.cancel") || "Cancel"}
        danger={!!pending && pending.kind === "end"}
        busy={publishState.isLoading || endState.isLoading}
        error={dialogError || undefined}
        onConfirm={() => { confirm(); }}
        onCancel={() => {
          const revert = !!pending && pending.kind === "publish" && fromEditor.current;
          setPending(null);
          if (revert) { fromEditor.current = false; if (onScheduleCancelled) onScheduleCancelled(); }
        }}
      />
    </div>
  );
};

export default AnnouncementPublishBar;
