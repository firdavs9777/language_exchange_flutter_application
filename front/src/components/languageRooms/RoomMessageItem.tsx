import React, { useState } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Reply, Smile, Trash2, Flag, MoreHorizontal } from "lucide-react";
import ReactionRow from "../chat/actions/ReactionRow";
import { userAvatarUrl } from "../../utils/photoUrl";
import { RoomMessage, senderIdOf, senderNameOf, messageLabel, replyPreview, isPhoto } from "./roomMessages";

interface Props {
  message: RoomMessage;
  myId: string;
  /** Members may reply and react; visitors only read. */
  canInteract: boolean;
  canDelete: boolean;
  onReply(m: RoomMessage): void;
  onReact(m: RoomMessage, emoji: string): void;
  onDelete(m: RoomMessage): void;
  onReport(m: RoomMessage): void;
}

const profilePath = (id: string, myId: string) => (id && id === myId ? "/profile" : `/profile/${id}`);

/** One line in a language room: avatar + name (open the profile), quote, photo, text, reactions, actions. */
const RoomMessageItem: React.FC<Props> = ({ message: m, myId, canInteract, canDelete, onReply, onReact, onDelete, onReport }) => {
  const { t } = useTranslation();
  const [menu, setMenu] = useState(false);
  const [picking, setPicking] = useState(false);

  if (m.messageType === "system") {
    return (
      <li className="lr-line__system" data-testid="language-room-line">
        {messageLabel(m, t)}
      </li>
    );
  }

  const sid = senderIdOf(m.sender);
  const mine = !!sid && sid === myId;
  const name = senderNameOf(m.sender) || t("languageRooms.room.someone") || "Member";
  const avatar = m.sender && typeof m.sender === "object" ? userAvatarUrl(m.sender as any) : undefined;
  const text = messageLabel(m, t);
  const quote = m.replyTo ? replyPreview(m.replyTo, t) : "";
  const quoteName = m.replyTo && m.replyTo.sender && typeof m.replyTo.sender === "object" ? m.replyTo.sender.name || "" : "";

  return (
    <li className={mine ? "lr-msg is-mine" : "lr-msg"} data-testid="language-room-line" data-message-id={m._id}>
      <Link to={profilePath(sid, myId)} className="lr-msg__avatar" data-testid={`language-room-avatar-${m._id}`} aria-label={name}>
        {avatar ? <img src={avatar} alt="" /> : <span>{name.charAt(0).toUpperCase()}</span>}
      </Link>
      <div className="lr-msg__body">
        <Link to={profilePath(sid, myId)} className="lr-msg__name" data-testid={`language-room-sender-${m._id}`}>
          {name}
        </Link>
        {m.replyTo && (
          <div className="lr-msg__quote" data-testid={`language-room-quote-${m._id}`}>
            {quoteName && <strong>{quoteName}</strong>} <span>{quote}</span>
          </div>
        )}
        {isPhoto(m) && (
          <a href={m.media!.url} target="_blank" rel="noopener noreferrer" className="lr-msg__photo">
            <img src={m.media!.url} alt={t("languageRooms.room.photo") || "Photo"} loading="lazy" />
          </a>
        )}
        {text && <span className="lr-msg__text">{text}</span>}
        <ReactionRow reactions={m.reactions} myUserId={myId} onToggle={(emoji) => canInteract && onReact(m, emoji)} />
        {picking && canInteract && (
          <ReactionRow
            reactions={[]}
            myUserId={myId}
            showQuickPick
            onToggle={(emoji) => {
              setPicking(false);
              onReact(m, emoji);
            }}
          />
        )}
      </div>
      <div className="lr-msg__actions">
        {canInteract && (
          <>
            <button type="button" className="lr-icon-btn" data-testid={`language-room-reply-${m._id}`} aria-label={t("languageRooms.room.reply") || "Reply"} onClick={() => onReply(m)}>
              <Reply size={14} />
            </button>
            <button type="button" className="lr-icon-btn" data-testid={`language-room-react-${m._id}`} aria-label={t("languageRooms.room.react") || "React"} onClick={() => setPicking((p) => !p)}>
              <Smile size={14} />
            </button>
          </>
        )}
        {(canDelete || !mine) && (
          <span className="lr-msg__more">
            <button type="button" className="lr-icon-btn" data-testid={`language-room-more-${m._id}`} aria-label={t("languageRooms.room.more") || "More"} aria-expanded={menu} onClick={() => setMenu((v) => !v)}>
              <MoreHorizontal size={14} />
            </button>
            {menu && (
              <span className="lr-msg__menu" role="menu">
                {canDelete && (
                  <button type="button" role="menuitem" data-testid={`language-room-delete-${m._id}`} className="is-danger" onClick={() => { setMenu(false); onDelete(m); }}>
                    <Trash2 size={14} /> {t("languageRooms.room.delete") || "Delete"}
                  </button>
                )}
                {!mine && (
                  <button type="button" role="menuitem" data-testid={`language-room-report-${m._id}`} onClick={() => { setMenu(false); onReport(m); }}>
                    <Flag size={14} /> {t("languageRooms.room.report") || "Report"}
                  </button>
                )}
              </span>
            )}
          </span>
        )}
      </div>
    </li>
  );
};

export default RoomMessageItem;
