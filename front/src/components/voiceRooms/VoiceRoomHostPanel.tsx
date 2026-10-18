import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Hand, MicOff, Power, ShieldPlus } from "lucide-react";
import { VoiceRoomMember } from "./voiceRoomState";

interface Props {
  members: VoiceRoomMember[];
  myId: string;
  hostId: string;
  isHost: boolean;
  canEnd: boolean;
  onMuteAll(): void;
  onPromote(userId: string): void;
  onEnd(): void;
}

const VoiceRoomHostPanel: React.FC<Props> = ({ members, myId, hostId, isHost, canEnd, onMuteAll, onPromote, onEnd }) => {
  const { t } = useTranslation();
  const [confirming, setConfirming] = useState(false);
  if (!isHost && !canEnd) return null;
  const hands = members.filter((m) => m.handRaised && m.userId !== myId);

  return (
    <section className="vr-host" data-testid="vr-host-panel" aria-label={t("voiceRooms.host.title") || "Host tools"}>
      <h2 className="vr-host__title">{t("voiceRooms.host.title") || "Host tools"}</h2>
      <h3 className="vr-host__sub">
        <Hand size={14} /> {t("voiceRooms.host.hands") || "Raised hands"}
      </h3>
      {hands.length === 0 ? (
        <p className="vr-host__empty">{t("voiceRooms.host.noHands") || "No one has raised a hand."}</p>
      ) : (
        <ul className="vr-host__hands">
          {hands.map((m) => (
            <li key={m.userId} data-testid={`vr-host-hand-${m.userId}`}>
              <span>{m.name}</span>
              {isHost && m.role !== "cohost" && m.userId !== hostId && (
                <button
                  type="button"
                  className="vr-btn vr-btn--ghost"
                  data-testid={`vr-host-promote-${m.userId}`}
                  onClick={() => onPromote(m.userId)}
                >
                  <ShieldPlus size={14} /> {t("voiceRooms.host.makeCohost") || "Make co-host"}
                </button>
              )}
            </li>
          ))}
        </ul>
      )}
      <p className="vr-host__note">
        {t("voiceRooms.host.speakNote") || "Anyone in the room can take the mic. A raised hand asks you for a turn."}
      </p>
      <div className="vr-host__actions">
        {isHost && (
          <button type="button" className="vr-btn vr-btn--ghost" data-testid="vr-host-mute-all" onClick={onMuteAll}>
            <MicOff size={14} /> {t("voiceRooms.host.muteAll") || "Mute everyone"}
          </button>
        )}
        {canEnd && !confirming && (
          <button type="button" className="vr-btn vr-btn--danger" data-testid="vr-host-end" onClick={() => setConfirming(true)}>
            <Power size={14} /> {t("voiceRooms.host.end") || "End room"}
          </button>
        )}
        {canEnd && confirming && (
          <span className="vr-host__confirm" role="group">
            <span>{t("voiceRooms.host.endConfirm") || "End the room for everyone?"}</span>
            <button type="button" className="vr-btn vr-btn--danger" data-testid="vr-host-end-confirm" onClick={onEnd}>
              {t("voiceRooms.host.endYes") || "End room"}
            </button>
            <button type="button" className="vr-btn vr-btn--ghost" data-testid="vr-host-end-cancel" onClick={() => setConfirming(false)}>
              {t("common.cancel") || "Cancel"}
            </button>
          </span>
        )}
      </div>
    </section>
  );
};

export default VoiceRoomHostPanel;
