import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import {
  useSetGatheringCoverMutation,
  useRemoveGatheringCoverMutation,
  useSetClubCoverMutation,
  useRemoveClubCoverMutation,
} from "../../store/slices/gatheringsSlice";
import { gatheringErrorText } from "./lib/gatheringFormat";

/** be/middleware/uploadToSpaces.js ALLOWED_IMAGE_TYPES. */
export const COVER_TYPES = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"];
/** Web-side cap; the server compresses and has no image-specific limit. */
export const COVER_MAX_BYTES = 10 * 1024 * 1024;

const CoverEditor: React.FC<{ kind: "gathering" | "club"; id: string; hasCover: boolean }> = ({ kind, id, hasCover }) => {
  const { t } = useTranslation();
  const [setG] = useSetGatheringCoverMutation();
  const [removeG] = useRemoveGatheringCoverMutation();
  const [setC] = useSetClubCoverMutation();
  const [removeC] = useRemoveClubCoverMutation();
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const run = async (fn: () => Promise<any>) => {
    setBusy(true);
    try {
      await fn();
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    } finally {
      setBusy(false);
    }
  };

  const onPick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files && e.target.files[0];
    e.target.value = "";
    setError("");
    if (!file) return;
    if (COVER_TYPES.indexOf(file.type) === -1) {
      setError(t("gatherings.cover.badType") || "Use a JPEG, PNG, GIF or WebP image.");
      return;
    }
    if (file.size > COVER_MAX_BYTES) {
      setError(t("gatherings.cover.tooBig") || "That image is over 10 MB.");
      return;
    }
    run(() => (kind === "club" ? setC({ id, file }).unwrap() : setG({ id, file }).unwrap()));
  };

  return (
    <div data-testid="cover-editor" className="flex flex-wrap items-center gap-3 text-sm">
      <label className="cursor-pointer font-extrabold text-brand-dark">
        {hasCover ? t("gatherings.cover.change") || "Change cover photo" : t("gatherings.cover.add") || "Add a cover photo"}
        <input data-testid="cover-input" type="file" accept={COVER_TYPES.join(",")} className="sr-only" disabled={busy} onChange={onPick} />
      </label>
      {hasCover && (
        <button type="button" data-testid="cover-remove" disabled={busy} className="font-bold text-gray-600"
          onClick={() => run(() => (kind === "club" ? removeC(id).unwrap() : removeG(id).unwrap()))}>
          {t("gatherings.cover.remove") || "Remove cover"}
        </button>
      )}
      {error && (
        <p data-testid="cover-error" role="alert" className="w-full text-red-700">
          {error}
        </p>
      )}
    </div>
  );
};

export default CoverEditor;
