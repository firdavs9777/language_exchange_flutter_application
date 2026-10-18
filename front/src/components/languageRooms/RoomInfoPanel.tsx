import React, { useState } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Users, Circle, Pencil, LogOut } from "lucide-react";
import DialogShell from "../../design/DialogShell";
import { languageFlag } from "../../utils/languages";
import { userAvatarUrl } from "../../utils/photoUrl";
import {
  LanguageRoom,
  useGetLanguageRoomMembersQuery,
  useUpdateLanguageRoomMutation,
  languageRoomErrorText,
} from "../../store/slices/languageRoomsSlice";
import { roomLanguageName } from "./roomLanguages";
import LanguageRoomOwnerPanel from "./LanguageRoomOwnerPanel";

interface Props {
  room: LanguageRoom;
  online: number;
  myId: string;
  onClose(): void;
  onJoin(): void;
  onLeave(): void;
  onRequestJoin(): void;
}

/** Plain member list (members who are not moderators). Every row opens the profile. */
const MemberList: React.FC<{ roomId: string; myId: string }> = ({ roomId, myId }) => {
  const { t } = useTranslation();
  const { data, isLoading, isError } = useGetLanguageRoomMembersQuery(roomId);
  const members: any[] = (data && data.data) || [];
  if (isLoading) return <p className="vr-host__empty">…</p>;
  if (isError) return <p className="vr-error">{t("languageRooms.errors.generic") || "Something went wrong. Try again."}</p>;
  return (
    <ul className="lr-members" data-testid="lr-members-list">
      {members.map((m) => {
        const id = String(m._id);
        const avatar = userAvatarUrl(m);
        return (
          <li key={id}>
            <Link to={id === myId ? "/profile" : `/profile/${id}`} data-testid={`lr-member-link-${id}`}>
              <span className="lr-msg__avatar">{avatar ? <img src={avatar} alt="" /> : <span>{String(m.name || "?").charAt(0)}</span>}</span>
              <span>{m.name}</span>
              {m.role && m.role !== "member" && (
                <span className="vr-chip">{m.role === "owner" ? t("languageRooms.owner.owner") || "owner" : t("languageRooms.owner.admin") || "admin"}</span>
              )}
            </Link>
          </li>
        );
      })}
    </ul>
  );
};

/** Room info, opened from the room title: language, counts, description, members, edit, join/leave. */
const RoomInfoPanel: React.FC<Props> = ({ room, online, myId, onClose, onJoin, onLeave, onRequestJoin }) => {
  const { t, i18n } = useTranslation();
  const locale = (i18n && i18n.language) || "en";
  const [view, setView] = useState<"info" | "members" | "edit">("info");
  const [title, setTitle] = useState(room.title || "");
  const [description, setDescription] = useState(room.description || "");
  const [error, setError] = useState("");
  const [update, { isLoading: saving }] = useUpdateLanguageRoomMutation();
  const isModerator = !!room.isOwnerOrAdmin;
  const isOwner = isModerator && room.owner === myId;

  const save = async () => {
    const trimmed = title.trim();
    if (!trimmed || trimmed.length > 60 || saving) return;
    setError("");
    try {
      await update({ roomId: room._id, title: trimmed, description: description.trim() }).unwrap();
      setView("info");
    } catch (err) {
      setError(languageRoomErrorText(err, t));
    }
  };

  return (
    <DialogShell labelledBy="lr-info-title" onClose={onClose} testId="lr-info-panel">
      <h2 id="lr-info-title" className="text-lg font-semibold text-ink-900 dark:text-ink-50">
        {room.emojiFlag || languageFlag(room.targetLanguage)} {room.title}
      </h2>

      {view === "info" && (
        <>
          <p className="mt-1 text-sm text-ink-600 dark:text-ink-300" data-testid="lr-info-language">
            {roomLanguageName(room.targetLanguage, locale)} ·{" "}
            {room.roomType === "hub" ? t("languageRooms.info.hub") || "Language hub" : t("languageRooms.info.topic") || "Topic room"}
          </p>
          <p className="lr-card__meta mt-2" data-testid="lr-info-counts">
            <Users size={14} /> {room.memberCount || 0} {t("languageRooms.info.members") || "members"}
            <Circle size={8} className="lr-online" aria-hidden /> {online} {t("languageRooms.room.online") || "online"}
          </p>
          {room.description ? (
            <p className="mt-3 whitespace-pre-line text-sm text-ink-800 dark:text-ink-100" data-testid="lr-info-description">
              {room.description}
            </p>
          ) : (
            <p className="mt-3 text-sm text-ink-500">{t("languageRooms.info.noDescription") || "No description yet."}</p>
          )}
          <div className="mt-4 flex flex-wrap gap-2">
            {room.isMember && (
              <button type="button" className="vr-btn vr-btn--ghost" data-testid="lr-info-members" onClick={() => setView("members")}>
                <Users size={14} /> {t("languageRooms.info.viewMembers") || "View members"}
              </button>
            )}
            {isModerator && (
              <button type="button" className="vr-btn vr-btn--ghost" data-testid="lr-info-edit" onClick={() => setView("edit")}>
                <Pencil size={14} /> {t("languageRooms.info.edit") || "Edit"}
              </button>
            )}
            {room.isMember && !isOwner && (
              <button type="button" className="vr-btn vr-btn--ghost" data-testid="language-room-leave" onClick={onLeave}>
                <LogOut size={14} /> {t("languageRooms.room.leave") || "Leave room"}
              </button>
            )}
            {!room.isMember && !room.isBanned && (
              <button type="button" className="vr-btn vr-btn--primary" data-testid="lr-info-join" onClick={onJoin}>
                {t("languageRooms.room.join") || "Join room"}
              </button>
            )}
            {!room.isMember && room.isBanned && !room.hasPendingRequest && (
              <button type="button" className="vr-btn vr-btn--primary" data-testid="lr-info-request" onClick={onRequestJoin}>
                {t("languageRooms.room.request") || "Ask to join"}
              </button>
            )}
          </div>
        </>
      )}

      {view === "members" && (
        <div className="mt-3">
          {isModerator && room.roomType === "topic" ? <LanguageRoomOwnerPanel roomId={room._id} /> : <MemberList roomId={room._id} myId={myId} />}
          <button type="button" className="vr-link mt-3" onClick={() => setView("info")}>
            {t("languageRooms.info.back") || "Back"}
          </button>
        </div>
      )}

      {view === "edit" && (
        <div className="mt-3 flex flex-col gap-3">
          <label className="vr-field">
            <span>{t("languageRooms.create.name") || "Topic"}</span>
            <input data-testid="lr-edit-title" value={title} maxLength={60} onChange={(e) => setTitle(e.target.value)} />
          </label>
          <label className="vr-field">
            <span>{t("languageRooms.create.description") || "Description (optional)"}</span>
            <textarea data-testid="lr-edit-description" value={description} maxLength={300} onChange={(e) => setDescription(e.target.value)} />
          </label>
          {error && (
            <p className="vr-error" role="alert" data-testid="lr-edit-error">
              {error}
            </p>
          )}
          <div className="vr-dialog__actions">
            <button type="button" className="vr-btn vr-btn--ghost" onClick={() => setView("info")} disabled={saving}>
              {t("common.cancel") || "Cancel"}
            </button>
            <button type="button" className="vr-btn vr-btn--primary" data-testid="lr-edit-save" disabled={!title.trim() || saving} onClick={save}>
              {t("languageRooms.info.save") || "Save"}
            </button>
          </div>
        </div>
      )}
    </DialogShell>
  );
};

export default RoomInfoPanel;
