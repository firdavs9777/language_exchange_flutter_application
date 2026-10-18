import React from "react";
import { useSelector } from "react-redux";
import { useNavigate, useParams, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Mic, MicOff, Hand, LogOut, Volume2, Crown } from "lucide-react";
import { useGetVoiceRoomQuery } from "../../store/slices/voiceRoomsSlice";
import { useVoiceRoom } from "./useVoiceRoom";
import { photoUrl } from "../../utils/photoUrl";
import Loader from "../Loader";
import VoiceRoomChat from "./VoiceRoomChat";
import VoiceRoomHostPanel from "./VoiceRoomHostPanel";
import "./VoiceRooms.scss";

const VoiceRoomPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const myId = useSelector((s: any) => String((s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id) || ""));
  const { data: room } = useGetVoiceRoomQuery(id, { skip: !id });
  const vr = useVoiceRoom(id, myId);
  const live = vr.phase === "live" || vr.phase === "reconnecting";
  const me = vr.members.find((m) => m.userId === myId);
  const isHost = vr.role === "host" || (!!myId && vr.hostId === myId);
  const canEnd = isHost || (!!me && me.role === "cohost");
  const endRoom = async () => {
    await vr.endRoom();
    navigate("/voice-rooms");
  };

  const leave = () => {
    vr.leave();
    navigate("/voice-rooms");
  };

  const header = (
    <header className="vr-room__head">
      <Link to="/voice-rooms" className="vr-link">
        {t("voiceRooms.room.back") || "All rooms"}
      </Link>
      <h1>{(room && room.title) || ""}</h1>
      {room && room.language && <span className="vr-chip">{room.language}</span>}
    </header>
  );

  let body: React.ReactNode = null;
  if (vr.phase === "idle") {
    body = (
      <div className="vr-room__gate">
        <p>{t("voiceRooms.room.joinHint") || "You'll join as a listener. Take the mic whenever you're ready."}</p>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="voice-room-join" onClick={() => vr.join()}>
          {t("voiceRooms.room.join") || "Join room"}
        </button>
      </div>
    );
  } else if (vr.phase === "joining") {
    body = (
      <div className="vr-room__gate" data-testid="voice-room-joining" aria-busy="true">
        <Loader />
      </div>
    );
  } else if (vr.phase === "ended") {
    body = (
      <div className="vr-room__gate" data-testid="voice-room-ended">
        <p>{t("voiceRooms.room.ended") || "This room has ended."}</p>
        <Link to="/voice-rooms" className="vr-btn vr-btn--primary">
          {t("voiceRooms.room.findAnother") || "Find another room"}
        </Link>
      </div>
    );
  } else if (vr.phase === "elsewhere") {
    body = (
      <div className="vr-room__gate" data-testid="voice-room-elsewhere">
        <p>{t("voiceRooms.room.elsewhere") || "You joined this room from another tab or device."}</p>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="voice-room-use-here" onClick={() => vr.join()}>
          {t("voiceRooms.room.useHere") || "Listen here instead"}
        </button>
      </div>
    );
  } else if (vr.phase === "lost") {
    body = (
      <div className="vr-room__gate" data-testid="voice-room-lost">
        <p>{t("voiceRooms.room.lost") || "Connection to the room was lost."}</p>
        <button type="button" className="vr-btn vr-btn--primary" data-testid="voice-room-rejoin" onClick={() => vr.join()}>
          {t("voiceRooms.room.rejoin") || "Rejoin"}
        </button>
      </div>
    );
  } else if (vr.phase === "error") {
    body = (
      <div className="vr-room__gate">
        <p className="vr-error" role="alert" data-testid="voice-room-error">
          {vr.error}
        </p>
        <button type="button" className="vr-btn vr-btn--primary" onClick={() => vr.join()}>
          {t("common.retry") || "Retry"}
        </button>
      </div>
    );
  }

  return (
    <section className="vr-page vr-room" data-testid="voice-room-page">
      {header}
      {body}
      {live && (
        <>
          {vr.phase === "reconnecting" && (
            <p className="vr-banner" role="status" data-testid="voice-room-reconnecting">
              {t("voiceRooms.room.reconnecting") || "Reconnecting…"}
            </p>
          )}
          {vr.audioBlocked && (
            <button type="button" className="vr-banner vr-banner--action" data-testid="voice-room-enable-sound" onClick={() => vr.startAudio()}>
              <Volume2 size={16} /> {t("voiceRooms.room.enableSound") || "Tap to turn on the room's sound"}
            </button>
          )}
          {vr.micProblem && (
            <p className="vr-banner vr-banner--warn" role="alert" data-testid="voice-room-mic-problem">
              {vr.micProblem === "denied"
                ? t("voiceRooms.room.micDenied") ||
                  "Your browser is blocking the microphone. Allow the microphone for banatalk.com in the address bar, then try again. You can keep listening."
                : vr.micProblem === "unavailable"
                ? t("voiceRooms.room.micUnavailable") || "No microphone was found (or another app is using it). You can keep listening."
                : t("voiceRooms.room.micError") || "Couldn't turn on the microphone. Try again."}
            </p>
          )}
          <ul className="vr-members">
            {vr.members.map((m) => {
              const avatar = photoUrl(m.images);
              const cls = ["vr-member", m.isSpeaking ? "is-speaking" : "", m.isMuted ? "is-muted" : ""].join(" ").trim();
              return (
                <li key={m.userId} className={cls} data-testid={`voice-room-member-${m.userId}`}>
                  <span className="vr-member__avatar">
                    {avatar ? <img src={avatar} alt="" /> : <span className="vr-avatar-fallback" aria-hidden />}
                    {m.handRaised && <Hand className="vr-member__hand" size={16} aria-label={t("voiceRooms.room.handUp") || "Hand raised"} />}
                  </span>
                  <span className="vr-member__name">
                    {m.userId === vr.hostId && <Crown size={12} aria-label={t("voiceRooms.room.host") || "Host"} />} {m.name}
                    {m.userId === myId ? ` (${t("voiceRooms.room.you") || "you"})` : ""}
                  </span>
                  {m.isMuted ? <MicOff size={14} aria-hidden /> : <Mic size={14} aria-hidden />}
                </li>
              );
            })}
          </ul>
          <div className="vr-controls">
            <button
              type="button"
              className={`vr-btn ${vr.micOn ? "vr-btn--ghost" : "vr-btn--primary"}`}
              data-testid="voice-room-mic"
              onClick={() => vr.setMic(!vr.micOn)}
            >
              {vr.micOn ? <MicOff size={16} /> : <Mic size={16} />}{" "}
              {vr.micOn ? t("voiceRooms.room.mute") || "Mute" : t("voiceRooms.room.takeMic") || "Take the mic"}
            </button>
            {!vr.micOn && (
              <button
                type="button"
                className={`vr-btn ${vr.handRaised ? "vr-btn--primary" : "vr-btn--ghost"}`}
                data-testid="voice-room-hand"
                aria-pressed={vr.handRaised}
                onClick={() => vr.raiseHand(!vr.handRaised)}
              >
                <Hand size={16} /> {vr.handRaised ? t("voiceRooms.room.lowerHand") || "Lower hand" : t("voiceRooms.room.raiseHand") || "Raise hand"}
              </button>
            )}
            <button type="button" className="vr-btn vr-btn--danger" data-testid="voice-room-leave" onClick={leave}>
              <LogOut size={16} /> {t("voiceRooms.room.leave") || "Leave"}
            </button>
          </div>
          <VoiceRoomHostPanel
            members={vr.members}
            myId={myId}
            hostId={vr.hostId}
            isHost={isHost}
            canEnd={canEnd}
            onMuteAll={vr.muteAll}
            onPromote={(userId) => vr.promote(userId)}
            onEnd={endRoom}
          />
          <VoiceRoomChat lines={vr.chat} onSend={vr.sendChat} disabled={vr.phase !== "live"} />
        </>
      )}
    </section>
  );
};

export default VoiceRoomPage;
