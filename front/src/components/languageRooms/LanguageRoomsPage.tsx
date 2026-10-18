import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Users, Circle, Plus, Lock } from "lucide-react";
import { useGetLanguageRoomsQuery, groupRoomsByLanguage, LanguageRoom } from "../../store/slices/languageRoomsSlice";
import { languageFlag } from "../../utils/languages";
import CreateTopicRoomDialog from "./CreateTopicRoomDialog";
import "../voiceRooms/VoiceRooms.scss";
import "./LanguageRooms.scss";

const LanguageRoomsPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user);
  const { data, isLoading, isError, refetch } = useGetLanguageRoomsQuery();
  const [creating, setCreating] = useState(false);
  const rooms: LanguageRoom[] = (data && Array.isArray(data.data) ? data.data : []) as LanguageRoom[];
  const groups = groupRoomsByLanguage(rooms);

  const card = (room: LanguageRoom) => (
    <li key={room._id}>
      <button type="button" className="lr-card" data-testid={`language-room-card-${room._id}`} onClick={() => navigate(`/rooms/${room._id}`)}>
        <span className="lr-card__title">
          {room.roomType === "hub" ? room.emojiFlag || languageFlag(room.targetLanguage) : "#"} {room.title}
          {room.isBanned && <Lock size={12} aria-label={t("languageRooms.list.locked") || "Locked"} />}
        </span>
        <span className="lr-card__meta">
          <Users size={12} /> {room.memberCount || 0}
          <Circle size={8} className="lr-online" aria-hidden /> {room.onlineCount || 0}
          {room.isMember && <span className="vr-chip">{t("languageRooms.list.joined") || "Joined"}</span>}
        </span>
      </button>
    </li>
  );

  return (
    <section className="vr-page" data-testid="language-rooms-page">
      <header className="vr-page__head">
        <h1>{t("languageRooms.list.title") || "Language rooms"}</h1>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="language-rooms-create" onClick={() => setCreating(true)}>
          <Plus size={16} /> {t("languageRooms.list.create") || "New topic room"}
        </button>
      </header>
      {isError && (
        <p className="vr-error" role="alert">
          {t("languageRooms.list.error") || "Couldn't load language rooms."}{" "}
          <button type="button" className="vr-link" onClick={() => refetch()}>
            {t("common.retry") || "Retry"}
          </button>
        </p>
      )}
      {!isLoading && !isError && groups.length === 0 && <p className="vr-empty">{t("languageRooms.list.empty") || "No rooms yet."}</p>}
      {groups.map((g) => (
        <section key={g.language} className="lr-group" data-testid={`language-rooms-group-${g.language}`}>
          <h2 className="lr-group__title">{g.hub ? g.hub.title : g.language}</h2>
          <ul className="lr-list">
            {g.hub && card(g.hub)}
            {g.topics.map(card)}
          </ul>
        </section>
      ))}
      <CreateTopicRoomDialog
        open={creating}
        defaultLanguage={(me && me.language_to_learn) || ""}
        onClose={() => setCreating(false)}
        onCreated={(id) => {
          setCreating(false);
          navigate(`/rooms/${id}`);
        }}
      />
    </section>
  );
};

export default LanguageRoomsPage;
