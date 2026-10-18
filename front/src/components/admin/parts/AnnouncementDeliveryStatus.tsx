import React from "react";
import { useTranslation } from "react-i18next";
import { MAX_DELIVERY_ATTEMPTS, deliveryInfo } from "./announcementForm";

/**
 * Where an announcement's push send stands (services/announcementDelivery.js):
 * state, attempts against the minute job's cap of 3, and the last error. An
 * exhausted `failed` send is called out, because nothing retries it and the
 * counters alone look like a normal partial send.
 *
 * `compact` is the list cell; otherwise the editor's panel with every counter.
 */

export interface DeliveryRow {
  status?: string;
  notify?: boolean;
  delivery?: {
    state?: string;
    targeted?: number;
    pushed?: number;
    listed?: number;
    failed?: number;
    attempts?: number;
    error?: string | null;
    startedAt?: string | null;
    finishedAt?: string | null;
    heartbeatAt?: string | null;
    stoppedReason?: string | null;
  } | null;
}

const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString("en-US") : "—";

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

const STATE_CLASS: { [state: string]: string } = {
  none: "bg-ink-100 text-ink-600 dark:bg-ink-800 dark:text-ink-300",
  queued: "bg-banana-light/40 text-ink-800 dark:bg-ink-800 dark:text-banana-light",
  running: "bg-brand-light/30 text-brand-deep dark:text-brand-light",
  done: "bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-200",
  failed: "bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-200",
};

const AnnouncementDeliveryStatus: React.FC<{ row: DeliveryRow; compact?: boolean }> = ({ row, compact = false }) => {
  const { t } = useTranslation();
  const info = deliveryInfo(row);
  const d = row.delivery || {};

  const stateLabel = (state: string): string => {
    if (state === "queued") return t("admin.announcements.deliveryQueued") || "Queued";
    if (state === "running") return t("admin.announcements.deliveryRunning") || "Sending";
    if (state === "done" && info.endedByAdmin) return t("admin.announcements.deliveryEndedByAdmin") || "Ended by admin";
    if (state === "done" && info.stoppedAtEnd) return t("admin.announcements.deliveryStoppedAtEnd") || "Stopped at end time";
    if (state === "done") return t("admin.announcements.deliveryDone") || "Sent";
    if (state === "failed") return t("admin.announcements.deliveryFailed") || "Failed";
    return t("admin.announcements.deliveryNone") || "Not sent";
  };

  if (!row.notify && info.state === "none") {
    return compact ? (
      <span className="text-ink-400">—</span>
    ) : (
      <p data-testid="delivery-off" className="text-sm text-ink-500">
        {t("admin.announcements.deliveryOff") || "No push: \"Send notification\" is off."}
      </p>
    );
  }

  const attemptsText = `${t("admin.announcements.deliveryAttempts") || "Attempts"} ${info.attempts}/${MAX_DELIVERY_ATTEMPTS}`;
  const counts = `${num(d.targeted)} / ${num(d.pushed)} / ${num(d.listed)} / ${num(d.failed)}`;
  const stoppedLabel = info.endedByAdmin
    ? t("admin.announcements.deliveryEndedByAdmin") || "Ended by admin"
    : info.stoppedAtEnd
      ? t("admin.announcements.deliveryStoppedAtEnd") || "Stopped at end time"
      : "";
  const stoppedText = stoppedLabel ? `${stoppedLabel} — sent to ${num(d.pushed)} of ${num(d.targeted)}` : "";
  const note = info.exhausted
    ? t("admin.announcements.deliveryExhausted") ||
      "Gave up after 3 attempts. Nothing will retry it; people not reached yet won't get the push."
    : info.retrying
      ? t("admin.announcements.deliveryRetrying") || "The minute job retries it from where it stopped."
      : info.state === "failed"
        ? t("admin.announcements.deliveryNotRetried") || "Not retried: the announcement is no longer live."
        : "";

  const badge = (
    <span
      data-testid="delivery-state"
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wide ${STATE_CLASS[info.state] || STATE_CLASS.none}`}
    >
      {stateLabel(info.state)}
    </span>
  );

  if (compact) {
    return (
      <div className="space-y-0.5 text-right">
        <div className="flex items-center justify-end gap-2">
          {badge}
          <span className="tabular-nums">{counts}</span>
        </div>
        {stoppedText ? <div data-testid="delivery-stopped" className="text-xs text-ink-500">{stoppedText}</div> : null}
        {info.attempts > 0 ? <div className="text-xs text-ink-500">{attemptsText}</div> : null}
        {info.exhausted ? (
          <div data-testid="delivery-exhausted" className="text-xs font-medium text-red-600">
            {t("admin.announcements.deliveryGaveUp") || "Gave up after 3 attempts"}
          </div>
        ) : null}
        {info.error ? (
          <div data-testid="delivery-error" className="ml-auto max-w-[16rem] truncate text-xs text-red-600" title={info.error}>
            {info.error}
          </div>
        ) : null}
      </div>
    );
  }

  return (
    <section data-testid="delivery-panel" className="space-y-2 rounded-card border border-line p-3 text-sm dark:border-line-dark">
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-medium text-ink-700 dark:text-ink-200">{t("admin.announcements.delivery") || "Push delivery"}</span>
        {badge}
        <span className="text-xs text-ink-500">{attemptsText}</span>
      </div>
      <dl className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs sm:grid-cols-4">
        <div><dt className="text-ink-400">{t("admin.announcements.targeted") || "Targeted"}</dt><dd className="tabular-nums">{num(d.targeted)}</dd></div>
        <div><dt className="text-ink-400">{t("admin.announcements.pushed") || "Pushed"}</dt><dd className="tabular-nums">{num(d.pushed)}</dd></div>
        <div><dt className="text-ink-400">{t("admin.announcements.listed") || "Listed"}</dt><dd className="tabular-nums">{num(d.listed)}</dd></div>
        <div><dt className="text-ink-400">{t("admin.announcements.failedCount") || "Failed"}</dt><dd className="tabular-nums">{num(d.failed)}</dd></div>
        <div><dt className="text-ink-400">{t("admin.announcements.started") || "Started"}</dt><dd>{formatWhen(d.startedAt)}</dd></div>
        <div><dt className="text-ink-400">{t("admin.announcements.finished") || "Finished"}</dt><dd>{formatWhen(d.finishedAt)}</dd></div>
        {info.state === "running" ? (
          <div><dt className="text-ink-400">{t("admin.announcements.heartbeat") || "Last batch"}</dt><dd>{formatWhen(d.heartbeatAt)}</dd></div>
        ) : null}
      </dl>
      {info.error ? (
        <p data-testid="delivery-error" className="break-words text-xs text-red-600">
          {t("admin.announcements.deliveryError") || "Last error:"} {info.error}
        </p>
      ) : null}
      {stoppedText ? <p data-testid="delivery-stopped" className="text-xs text-ink-500">{stoppedText}</p> : null}
      {note ? (
        <p data-testid={info.exhausted ? "delivery-exhausted" : "delivery-note"}
          className={info.exhausted ? "text-xs font-medium text-red-600" : "text-xs text-ink-500"}>
          {note}
        </p>
      ) : null}
    </section>
  );
};

export default AnnouncementDeliveryStatus;
