import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import ConfirmDialog from "../../../design/ConfirmDialog";
import notify from "../../../design/notify";
import { useBlockUserMutation } from "../../../store/slices/usersSlice";

export interface BlockAuthorDialogProps {
  authorId: string;
  /** Shown in the title; falls back to "this person". */
  authorName?: string;
  onClose: () => void;
  /** Called after the server confirmed the block. */
  onBlocked?: () => void;
}

/**
 * Block whoever wrote a moment, comment or story. Same copy and confirm as
 * the profile's Block (profile.block.*). blockUser invalidates Moments and
 * Comments, and the server filters a blocked author out of feeds and comment
 * lists, so the open lists drop their content on the refetch.
 */
const BlockAuthorDialog: React.FC<BlockAuthorDialogProps> = ({ authorId, authorName, onClose, onBlocked }) => {
  const { t } = useTranslation();
  const [blockUser, { isLoading }] = useBlockUserMutation();
  const [error, setError] = useState("");
  const name = authorName || t("profile.actions.this_person") || "this person";

  const confirm = async () => {
    setError("");
    try {
      await blockUser(authorId).unwrap();
      notify.success(t("moments_section.block.done", { name }) || `${name} is blocked.`);
      if (onBlocked) onBlocked();
      onClose();
    } catch (e) {
      setError(t("profile.actions.action_failed") || "That didn't work. Try again.");
    }
  };

  return (
    <ConfirmDialog
      open
      danger
      title={t("profile.block.title", { name }) || `Block ${name}?`}
      body={t("profile.block.body") || "They will not be able to message you or see your profile."}
      confirmLabel={t("profile.actions.block") || "Block"}
      cancelLabel={t("profile.actions.cancel") || "Cancel"}
      busy={isLoading}
      error={error || undefined}
      onConfirm={confirm}
      onCancel={onClose}
    />
  );
};

export default BlockAuthorDialog;
