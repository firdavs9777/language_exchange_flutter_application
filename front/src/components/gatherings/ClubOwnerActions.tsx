import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import { Club, useDeleteClubMutation } from "../../store/slices/gatheringsSlice";
import { gatheringErrorText } from "./lib/gatheringFormat";
import ConfirmDialog from "./ConfirmDialog";

/**
 * Owner-only: delete the club. Its gatherings are NOT deleted
 * (controllers/clubs.js deleteClub) -- people RSVP'd to them -- and the
 * confirmation says so.
 */
const ClubOwnerActions: React.FC<{ club: Club }> = ({ club }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [del, state] = useDeleteClubMutation();
  const [confirm, setConfirm] = useState(false);
  if (!club.viewerIsOwner) return null;
  const busy = !!(state && state.isLoading);

  const doDelete = async () => {
    try {
      await del(club._id).unwrap();
      navigate("/gatherings?tab=clubs", { replace: true });
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    }
  };

  return (
    <div className="mt-8">
      <button type="button" data-testid="club-delete" onClick={() => setConfirm(true)} className="text-sm font-bold text-red-700">
        {t("clubs.owner.delete") || "Delete club"}
      </button>
      {confirm && (
        <ConfirmDialog
          title={t("clubs.owner.deleteTitle", { name: club.name }) || `Delete ${club.name}?`}
          body={t("clubs.owner.deleteBody") || "Members lose the club. Gatherings already planned will still happen."}
          confirmLabel={t("clubs.owner.delete") || "Delete club"}
          danger
          busy={busy}
          onConfirm={doDelete}
          onCancel={() => setConfirm(false)}
        />
      )}
    </div>
  );
};

export default ClubOwnerActions;
