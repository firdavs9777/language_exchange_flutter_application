import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import notify from "../../design/notify";
import { Club, ClubMember, useRemoveClubMemberMutation, useSetClubMemberRoleMutation } from "../../store/slices/gatheringsSlice";
import { gatheringErrorText, personName } from "./lib/gatheringFormat";
import ConfirmDialog from "./ConfirmDialog";
import { photoUrl } from "../../utils/photoUrl";

const RANK: { [role: string]: number } = { owner: 0, organizer: 1, member: 2 };

/**
 * Who runs the club, then who is in it (the server's preview: owner,
 * organizers, the 12 newest -- lib/clubMembers.js). Management follows the
 * server's rules: owner or organizer removes, only the owner removes an
 * organizer or changes roles, nobody touches the owner.
 */
const ClubPeople: React.FC<{ club: Club }> = ({ club }) => {
  const { t } = useTranslation();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user._id);
  const [removeMember] = useRemoveClubMemberMutation();
  const [setRole] = useSetClubMemberRoleMutation();
  const [menu, setMenu] = useState("");
  const [removing, setRemoving] = useState<ClubMember | null>(null);
  const [busy, setBusy] = useState(false);

  const members = (club.members || []).slice().sort((a, b) => (RANK[a.role] ?? 2) - (RANK[b.role] ?? 2));
  const canManage = (m: ClubMember) => {
    if (!club.viewerCanManage || m.role === "owner" || String(m._id) === String(me)) return false;
    if (m.role === "organizer" && !club.viewerIsOwner) return false;
    return true;
  };
  const roleText = (role: string) =>
    role === "owner"
      ? t("clubs.people.owner") || "Owner"
      : role === "organizer"
      ? t("clubs.people.organizer") || "Organizer"
      : "";

  const act = async (fn: () => Promise<any>) => {
    setBusy(true);
    try {
      await fn();
      setMenu("");
      setRemoving(null);
    } catch (err) {
      notify.error(gatheringErrorText(err, t));
    } finally {
      setBusy(false);
    }
  };

  return (
    <section data-testid="club-people" className="mt-6">
      <h2 className="text-sm font-extrabold">
        {t("clubs.people.title", { count: club.memberCount || members.length }) || `Members · ${club.memberCount || members.length}`}
      </h2>
      <ul className="mt-2 grid gap-2">
        {members.map((m) => {
          const src = photoUrl(m.images);
          return (
            <li key={m._id} data-testid={`club-member-${m._id}`} className="relative flex items-center gap-2">
              {src ? <img src={src} alt="" className="h-8 w-8 rounded-full object-cover" /> : <span className="h-8 w-8 rounded-full bg-gray-200" />}
              <span className="flex-1 truncate text-sm font-bold">{personName(m) || t("gatherings.detail.someone") || "A BananaTalk member"}</span>
              <span data-testid={`club-member-role-${m._id}`} className="text-xs text-gray-500">{roleText(m.role)}</span>
              {canManage(m) && (
                <button type="button" data-testid={`club-member-menu-${m._id}`} aria-label={t("gatherings.safety.more") || "More"}
                  className="px-2 text-lg leading-none" onClick={() => setMenu(menu === m._id ? "" : m._id)}>
                  ⋯
                </button>
              )}
              {menu === m._id && (
                <div role="menu" className="absolute end-0 top-8 z-10 w-48 rounded-xl border border-gray-200 bg-white py-1 shadow-lg dark:border-gray-700 dark:bg-gray-900">
                  {club.viewerIsOwner && m.role === "member" && (
                    <button type="button" role="menuitem" data-testid={`club-make-organizer-${m._id}`} disabled={busy}
                      className="block w-full px-4 py-2 text-start text-sm"
                      onClick={() => act(() => setRole({ id: club._id, userId: m._id, role: "organizer" }).unwrap())}>
                      {t("clubs.people.makeOrganizer") || "Make organizer"}
                    </button>
                  )}
                  {club.viewerIsOwner && m.role === "organizer" && (
                    <button type="button" role="menuitem" data-testid={`club-make-member-${m._id}`} disabled={busy}
                      className="block w-full px-4 py-2 text-start text-sm"
                      onClick={() => act(() => setRole({ id: club._id, userId: m._id, role: "member" }).unwrap())}>
                      {t("clubs.people.makeMember") || "Remove organizer role"}
                    </button>
                  )}
                  <button type="button" role="menuitem" data-testid={`club-remove-${m._id}`} disabled={busy}
                    className="block w-full px-4 py-2 text-start text-sm text-red-700"
                    onClick={() => { setMenu(""); setRemoving(m); }}>
                    {t("clubs.people.remove") || "Remove from club"}
                  </button>
                </div>
              )}
            </li>
          );
        })}
      </ul>
      {removing && (
        <ConfirmDialog
          title={t("clubs.people.removeTitle", { name: personName(removing) }) || `Remove ${personName(removing) || "this member"}?`}
          confirmLabel={t("clubs.people.remove") || "Remove from club"}
          danger
          busy={busy}
          onConfirm={() => act(() => removeMember({ id: club._id, userId: removing._id }).unwrap())}
          onCancel={() => setRemoving(null)}
        />
      )}
    </section>
  );
};

export default ClubPeople;
