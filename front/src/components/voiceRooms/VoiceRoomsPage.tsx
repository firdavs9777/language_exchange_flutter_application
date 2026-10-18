import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Mic, Users, CalendarClock, Plus } from "lucide-react";
import {
  useGetVoiceRoomsQuery,
  useRsvpVoiceRoomMutation,
  voiceRoomErrorText,
  VoiceRoomSummary,
} from "../../store/slices/voiceRoomsSlice";
import { photoUrl } from "../../utils/photoUrl";
import notify from "../../design/notify";
import CreateVoiceRoomDialog from "./CreateVoiceRoomDialog";
import "./VoiceRooms.scss";

type Tab = "live" | "scheduled";

const hostName = (host: VoiceRoomSummary["host"]) => (host && typeof host === "object" ? host.name || "" : "");
const hostImages = (host: VoiceRoomSummary["host"]) => (host && typeof host === "object" ? host.images : undefined);

const VoiceRoomsPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user);
  const myId = me && me._id ? String(me._id) : "";
  const [tab, setTab] = useState<Tab>("live");
  const [creating, setCreating] = useState(false);
  const args = tab === "scheduled" ? { status: "scheduled", page: 1 } : { page: 1 };
  const { data, isLoading, isError, refetch } = useGetVoiceRoomsQuery(args, { pollingInterval: 30000 });
  const [rsvp] = useRsvpVoiceRoomMutation();
  const rooms: VoiceRoomSummary[] = (data && Array.isArray(data.data) ? data.data : []) as VoiceRoomSummary[];

  const toggleRsvp = async (room: VoiceRoomSummary, going: boolean) => {
    try {
      await rsvp({ roomId: room._id, going }).unwrap();
    } catch (err) {
      notify.error(voiceRoomErrorText(err, t));
    }
  };

  const formatStart = (iso?: string | null) => {
    if (!iso) return "";
    const d = new Date(iso);
    return isNaN(d.getTime())
      ? ""
      : d.toLocaleString(i18n.language, { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
  };

  return (
    <section className="vr-page" data-testid="voice-rooms-page">
      <header className="vr-page__head">
        <h1>{t("voiceRooms.list.title") || "Voice rooms"}</h1>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="voice-rooms-create" onClick={() => setCreating(true)}>
          <Plus size={16} /> {t("voiceRooms.list.create") || "Start a room"}
        </button>
      </header>
      <div className="vr-tabs" role="tablist">
        <button
          type="button"
          role="tab"
          aria-selected={tab === "live"}
          data-testid="voice-rooms-tab-live"
          className={tab === "live" ? "is-active" : ""}
          onClick={() => setTab("live")}
        >
          {t("voiceRooms.list.live") || "Live now"}
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={tab === "scheduled"}
          data-testid="voice-rooms-tab-scheduled"
          className={tab === "scheduled" ? "is-active" : ""}
          onClick={() => setTab("scheduled")}
        >
          {t("voiceRooms.list.scheduled") || "Coming up"}
        </button>
      </div>

      {isError && (
        <p className="vr-error" role="alert">
          {t("voiceRooms.list.error") || "Couldn't load voice rooms."}{" "}
          <button type="button" className="vr-link" onClick={() => refetch()}>
            {t("common.retry") || "Retry"}
          </button>
        </p>
      )}
      {!isLoading && !isError && rooms.length === 0 && (
        <p className="vr-empty" data-testid="voice-rooms-empty">
          {tab === "live"
            ? t("voiceRooms.list.emptyLive") || "No one is talking right now. Start a room and invite people in."
            : t("voiceRooms.list.emptyScheduled") || "No rooms are scheduled yet."}
        </p>
      )}

      <ul className="vr-grid">
        {rooms.map((room) => {
          const count = room.participantCount || 0;
          const full = count >= room.maxParticipants;
          const going = (room.rsvps || []).some((r) => String(r.user) === myId);
          const avatar = photoUrl(hostImages(room.host));
          return (
            <li key={room._id} className="vr-card" data-testid={`voice-room-card-${room._id}`}>
              <div className="vr-card__top">
                <span className="vr-chip">{room.language}</span>
                <span className="vr-card__count">
                  <Users size={14} /> {count}/{room.maxParticipants}
                </span>
              </div>
              <h2 className="vr-card__title">{room.title}</h2>
              {room.description && <p className="vr-card__desc">{room.description}</p>}
              <div className="vr-card__host">
                {avatar ? <img src={avatar} alt="" /> : <span className="vr-avatar-fallback" aria-hidden />}
                <span>{hostName(room.host)}</span>
              </div>
              {tab === "live" ? (
                <button
                  type="button"
                  className="vr-btn vr-btn--primary"
                  data-testid={`voice-room-join-${room._id}`}
                  disabled={full}
                  onClick={() => navigate(`/voice-rooms/${room._id}`)}
                >
                  <Mic size={16} /> {full ? t("voiceRooms.list.full") || "Full" : t("voiceRooms.list.join") || "Join"}
                </button>
              ) : (
                <div className="vr-card__scheduled">
                  <span>
                    <CalendarClock size={14} /> {formatStart(room.scheduledFor)}
                  </span>
                  <button
                    type="button"
                    className={`vr-btn ${going ? "vr-btn--ghost" : "vr-btn--primary"}`}
                    data-testid={`voice-room-rsvp-${room._id}`}
                    onClick={() => toggleRsvp(room, !going)}
                  >
                    {going ? t("voiceRooms.list.going") || "Going ✓" : t("voiceRooms.list.rsvp") || "Remind me"}
                  </button>
                </div>
              )}
            </li>
          );
        })}
      </ul>

      <CreateVoiceRoomDialog
        open={creating}
        defaultLanguage={(me && me.language_to_learn) || ""}
        onClose={() => setCreating(false)}
        onCreated={(id) => {
          setCreating(false);
          navigate(`/voice-rooms/${id}`);
        }}
      />
    </section>
  );
};

export default VoiceRoomsPage;
