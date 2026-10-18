import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Check, X, UserMinus } from "lucide-react";
import {
  useGetLanguageRoomRequestsQuery,
  useGetLanguageRoomMembersQuery,
  useDecideLanguageRoomRequestMutation,
  useRemoveLanguageRoomMemberMutation,
  languageRoomErrorText,
} from "../../store/slices/languageRoomsSlice";

const LanguageRoomOwnerPanel: React.FC<{ roomId: string }> = ({ roomId }) => {
  const { t } = useTranslation();
  const { data: requestsData } = useGetLanguageRoomRequestsQuery(roomId);
  const { data: membersData } = useGetLanguageRoomMembersQuery(roomId);
  const [decide] = useDecideLanguageRoomRequestMutation();
  const [remove] = useRemoveLanguageRoomMemberMutation();
  const [confirming, setConfirming] = useState<string | null>(null);
  const [error, setError] = useState("");

  const requests: any[] = (requestsData && requestsData.data) || [];
  const members: any[] = (membersData && membersData.data) || [];

  const run = async (fn: () => Promise<any>) => {
    setError("");
    try {
      await fn();
    } catch (err) {
      setError(languageRoomErrorText(err, t));
    }
  };

  return (
    <section className="lr-owner" data-testid="lr-owner-panel">
      <h2 className="vr-host__title">{t("languageRooms.owner.requests") || "Join requests"}</h2>
      {requests.length === 0 ? (
        <p className="vr-host__empty">{t("languageRooms.owner.noRequests") || "No one is waiting."}</p>
      ) : (
        <ul className="vr-host__hands">
          {requests.map((r) => {
            const uid = String((r.user && r.user._id) || r.user);
            return (
              <li key={uid} data-testid={`lr-request-${uid}`}>
                <span>{(r.user && r.user.name) || ""}</span>
                <span>
                  <button type="button" className="vr-btn vr-btn--primary" data-testid={`lr-approve-${uid}`} onClick={() => run(() => decide({ roomId, userId: uid, approve: true }).unwrap())} aria-label={t("languageRooms.owner.approve") || "Let in"}>
                    <Check size={14} />
                  </button>{" "}
                  <button type="button" className="vr-btn vr-btn--ghost" data-testid={`lr-deny-${uid}`} onClick={() => run(() => decide({ roomId, userId: uid, approve: false }).unwrap())} aria-label={t("languageRooms.owner.deny") || "Decline"}>
                    <X size={14} />
                  </button>
                </span>
              </li>
            );
          })}
        </ul>
      )}
      <h2 className="vr-host__title">{t("languageRooms.owner.members") || "Members"}</h2>
      <ul className="vr-host__hands">
        {members.map((m) => (
          <li key={m._id} data-testid={`lr-member-${m._id}`}>
            <span>
              {m.name}
              {m.role !== "member" ? ` · ${m.role === "owner" ? t("languageRooms.owner.owner") || "owner" : t("languageRooms.owner.admin") || "admin"}` : ""}
            </span>
            {m.role === "member" &&
              (confirming === m._id ? (
                <span className="vr-host__confirm">
                  <button type="button" className="vr-btn vr-btn--danger" data-testid={`lr-remove-confirm-${m._id}`} onClick={() => run(async () => {
                    await remove({ roomId, userId: m._id }).unwrap();
                    setConfirming(null);
                  })}>
                    {t("languageRooms.owner.removeYes") || "Remove"}
                  </button>
                  <button type="button" className="vr-btn vr-btn--ghost" onClick={() => setConfirming(null)}>
                    {t("common.cancel") || "Cancel"}
                  </button>
                </span>
              ) : (
                <button type="button" className="vr-btn vr-btn--ghost" data-testid={`lr-remove-${m._id}`} onClick={() => setConfirming(m._id)} aria-label={t("languageRooms.owner.remove") || "Remove from room"}>
                  <UserMinus size={14} />
                </button>
              ))}
          </li>
        ))}
      </ul>
      <p className="vr-host__note">{t("languageRooms.owner.removeNote") || "Removed members can ask to come back; you decide."}</p>
      {error && (
        <p className="vr-error" role="alert" data-testid="lr-owner-error">
          {error}
        </p>
      )}
    </section>
  );
};

export default LanguageRoomOwnerPanel;
