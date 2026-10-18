import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import DialogShell from "../../design/DialogShell";
import notify from "../../design/notify";
import { useReportUserMutation } from "../../store/slices/usersSlice";
import { REPORT_REASONS } from "../moments/actions/ReportMomentDialog";
import BlockAuthorDialog from "../moments/actions/BlockAuthorDialog";

export interface GatheringSafetyMenuProps {
  type: "gathering" | "club";
  targetId: string;
  ownerId: string;
  ownerName?: string;
  onBlocked: () => void;
}

const REASON_FALLBACK: { [k: string]: string } = {
  spam: "Spam",
  harassment: "Harassment",
  hate_speech: "Hate speech",
  violence: "Violence",
  nudity: "Nudity",
  false_information: "False information",
  copyright: "Copyright",
  other: "Something else",
};

/**
 * Report-or-block for a gathering or a club, like the app's
 * gathering_safety_menu.dart. The backend has always accepted `gathering` and
 * `club` reports (models/Report.js); the reported user is the host/owner.
 */
const GatheringSafetyMenu: React.FC<GatheringSafetyMenuProps> = ({ type, targetId, ownerId, ownerName, onBlocked }) => {
  const { t } = useTranslation();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id);
  const [open, setOpen] = useState(false);
  const [dialog, setDialog] = useState<"" | "report" | "block">("");
  const [reason, setReason] = useState("");
  const [description, setDescription] = useState("");
  const [busy, setBusy] = useState(false);
  const [report] = useReportUserMutation();

  if (!ownerId || String(ownerId) === String(me)) return null;

  const send = async () => {
    if (!reason) return;
    setBusy(true);
    try {
      await report({ type, reportId: targetId, reportedUser: ownerId, reason, description: description.trim() }).unwrap();
      notify.success(t("gatherings.safety.reported") || "Thanks — our moderators will review it.");
      setDialog("");
      setReason("");
      setDescription("");
    } catch (e) {
      notify.error(t("gatherings.safety.reportFailed") || "Couldn't send the report. Try again.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="relative">
      <button
        type="button"
        data-testid="safety-menu-button"
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label={t("gatherings.safety.more") || "More"}
        className="rounded-full px-3 py-1 text-xl leading-none text-gray-600"
        onClick={() => setOpen(!open)}
      >
        ⋯
      </button>
      {open && (
        <div role="menu" className="absolute end-0 z-10 mt-1 w-48 rounded-xl border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-900">
          <button type="button" role="menuitem" data-testid="safety-report" className="block w-full px-4 py-2 text-start text-sm"
            onClick={() => { setOpen(false); setDialog("report"); }}>
            {type === "club" ? t("gatherings.safety.reportClub") || "Report club" : t("gatherings.safety.reportGathering") || "Report gathering"}
          </button>
          <button type="button" role="menuitem" data-testid="safety-block" className="block w-full px-4 py-2 text-start text-sm text-red-700"
            onClick={() => { setOpen(false); setDialog("block"); }}>
            {type === "club" ? t("gatherings.safety.blockOwner") || "Block the owner" : t("gatherings.safety.blockHost") || "Block the host"}
          </button>
        </div>
      )}

      {dialog === "report" && (
        <DialogShell labelledBy="safety-report-title" onClose={() => setDialog("")} testId="safety-report-dialog" dismissible={!busy}>
          <h2 id="safety-report-title" className="text-lg font-extrabold">
            {type === "club" ? t("gatherings.safety.reportClub") || "Report club" : t("gatherings.safety.reportGathering") || "Report gathering"}
          </h2>
          <fieldset className="mt-3 grid gap-1">
            <legend className="text-sm font-bold">{t("moments_section.report.reasonLabel") || "Why are you reporting it?"}</legend>
            {REPORT_REASONS.map((value) => (
              <label key={value} className="flex items-center gap-2 text-sm">
                <input type="radio" name="gathering-report-reason" data-testid={`safety-report-reason-${value}`} checked={reason === value} onChange={() => setReason(value)} />
                <span>{t(`moments_section.report.reasons.${value}`) || REASON_FALLBACK[value] || value}</span>
              </label>
            ))}
          </fieldset>
          <textarea
            className="mt-3 w-full rounded-lg border border-gray-300 p-2 text-sm"
            maxLength={500}
            value={description}
            placeholder={t("moments_section.report.descriptionLabel") || "Anything else? (optional)"}
            onChange={(e) => setDescription(e.target.value)}
          />
          <div className="mt-4 flex justify-end gap-2">
            <button type="button" disabled={busy} onClick={() => setDialog("")} className="rounded-full px-4 py-2 text-sm font-bold">
              {t("moments_section.report.cancel") || "Cancel"}
            </button>
            <button type="button" data-testid="safety-report-submit" disabled={!reason || busy} onClick={send}
              className="rounded-full bg-red-600 px-4 py-2 text-sm font-extrabold text-white disabled:opacity-50">
              {t("moments_section.report.submit") || "Send report"}
            </button>
          </div>
        </DialogShell>
      )}

      {dialog === "block" && (
        <BlockAuthorDialog authorId={ownerId} authorName={ownerName} onClose={() => setDialog("")} onBlocked={onBlocked} />
      )}
    </div>
  );
};

export default GatheringSafetyMenu;
