import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Send } from "lucide-react";
import { VoiceRoomChatLine } from "./voiceRoomState";

const VoiceRoomChat: React.FC<{ lines: VoiceRoomChatLine[]; onSend(text: string): void; disabled?: boolean }> = ({
  lines,
  onSend,
  disabled,
}) => {
  const { t } = useTranslation();
  const [text, setText] = useState("");
  const send = () => {
    if (!text.trim()) return;
    onSend(text);
    setText("");
  };
  return (
    <aside className="vr-chat" aria-label={t("voiceRooms.room.chat") || "Room chat"}>
      <ol className="vr-chat__lines">
        {lines.map((l) => (
          <li key={l.id} data-testid="voice-room-chat-line">
            <strong>{l.name}</strong> <span>{l.message}</span>
          </li>
        ))}
      </ol>
      <div className="vr-chat__compose">
        <input
          data-testid="voice-room-chat-input"
          value={text}
          maxLength={500}
          disabled={disabled}
          placeholder={t("voiceRooms.room.chatPlaceholder") || "Say something…"}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") send();
          }}
        />
        <button type="button" data-testid="voice-room-chat-send" disabled={disabled} onClick={send} aria-label={t("voiceRooms.room.send") || "Send"}>
          <Send size={16} />
        </button>
      </div>
    </aside>
  );
};

export default VoiceRoomChat;
