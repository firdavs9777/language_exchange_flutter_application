import React from "react";
import { useTranslation } from "react-i18next";
import { Phone, PhoneIncoming, PhoneMissed, PhoneOutgoing, Video } from "lucide-react";
import { callLabel, CallData } from "../lib/callLabel";

interface CallMessageCardProps {
  callData: CallData | null | undefined;
  viewerId: string;
  isSent: boolean;
  otherName: string;
}

/**
 * A call-history message (messageType 'call'), drawn the way the app's
 * CallHistoryBubble draws it: kind icon, the viewer-side label, the duration
 * of a completed call, a direction icon; red for missed or declined.
 */
const CallMessageCard: React.FC<CallMessageCardProps> = ({ callData, viewerId, isSent, otherName }) => {
  const { t } = useTranslation();
  const label = callLabel(callData, viewerId, isSent, otherName);
  const text = t(label.key, label.params) || label.fallback;
  const KindIcon = label.isVideo ? Video : Phone;
  const DirectionIcon = label.missed
    ? PhoneMissed
    : label.direction === "outgoing"
    ? PhoneOutgoing
    : PhoneIncoming;

  return (
    <div
      className={`call-card${label.negative ? " call-card--negative" : ""}`}
      data-testid="call-card"
      data-outcome={label.outcome}
    >
      <KindIcon size={18} className="call-card-kind" aria-hidden="true" />
      <div className="call-card-body">
        <span className="call-card-label">{text}</span>
        {label.duration ? <span className="call-card-duration">{label.duration}</span> : null}
      </div>
      <DirectionIcon size={16} className="call-card-direction" aria-hidden="true" />
    </div>
  );
};

export default CallMessageCard;
