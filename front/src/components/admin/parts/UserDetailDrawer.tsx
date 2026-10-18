import React, { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  useGetAdminUserQuery,
  useBanAdminUserMutation,
  useUnbanAdminUserMutation,
  useChangeAdminUserRoleMutation,
  useHardDeleteAdminUserMutation,
} from "../../../store/slices/adminSlice";
import { Pencil, X } from "lucide-react";
import { Avatar, Badge, LanguageExchangePill } from "../../../design";
import ConfirmDialog from "./ConfirmDialog";
import EditUserDialog from "./EditUserDialog";

export interface UserDetailDrawerProps {
  userId: string;
  onClose: () => void;
}

/** Which confirm dialog is open, if any. */
type Pending = "ban" | "unban" | "role" | "delete" | null;

const formatWhen = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleString();
};

/** Day only: a subscription's end date has no meaningful time of day. */
const formatDate = (value: any): string => {
  if (!value) return "—";
  const date = new Date(value);
  return isNaN(date.getTime()) ? String(value) : date.toLocaleDateString();
};

const num = (value: any): string =>
  typeof value === "number" && isFinite(value) ? value.toLocaleString() : "—";

/** The server's message when it has one; never a raw status object. */
const errorText = (error: any, fallback: string): string | undefined => {
  if (!error) return undefined;
  return (
    (error.data && (error.data.message || error.data.error)) ||
    error.message ||
    fallback
  );
};

/**
 * Everything the backend knows about one user, and the four things a moderator
 * can do to them.
 *
 * `GET /admin/users/:id` spreads the user's own fields at the top level of
 * `data` alongside `recentActions` and `activitySummary`; a `data.user`
 * wrapper is read too so a future reshape of the controller doesn't blank the
 * panel. Every action goes through `ConfirmDialog`, which holds the reason the
 * backend requires, and a failure stays inside that dialog rather than
 * dismissing the moderator's work.
 */
const UserDetailDrawer: React.FC<UserDetailDrawerProps> = ({ userId, onClose }) => {
  const { t } = useTranslation();
  const detail = useGetAdminUserQuery(userId);
  const [banUser, banState] = useBanAdminUserMutation();
  const [unbanUser, unbanState] = useUnbanAdminUserMutation();
  const [changeRole, roleState] = useChangeAdminUserRoleMutation();
  const [deleteUser, deleteState] = useHardDeleteAdminUserMutation();
  const [pending, setPending] = useState<Pending>(null);
  const [editing, setEditing] = useState(false);
  const panelRef = useRef<HTMLDivElement | null>(null);

  const payload: any = detail.data || {};
  const user: any = payload.user || payload;
  const recentActions: any[] = Array.isArray(payload.recentActions) ? payload.recentActions : [];
  const activity: any = payload.activitySummary || {};
  const isBanned = !!user.isBanned;
  const isAdmin = user.role === "admin";
  const isVip = user.userMode === "vip" || !!(user.vipSubscription && user.vipSubscription.isActive);
  const nextRole: "admin" | "user" = isAdmin ? "user" : "admin";

  // Escape closes the drawer — unless a dialog is open on top of it, which
  // owns Escape while it is up.
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" && !pending && !editing) onClose();
    };
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [onClose, pending, editing]);

  // Focus moves into the panel on open so the keyboard follows the eye.
  useEffect(() => {
    if (panelRef.current) panelRef.current.focus();
  }, []);

  /**
   * Open one action's dialog, clearing that mutation's previous failure first.
   *
   * RTK Query keeps `error` on the hook result until something resets it, so a
   * dialog reopened after a failed attempt would otherwise greet the moderator
   * with a message describing something that is no longer happening. Reset runs
   * in the click handler rather than an effect so it batches with `setPending`
   * and the dialog never renders the stale error, not even for a frame.
   */
  const openDialog = (next: Exclude<Pending, null>) => {
    const state: any =
      next === "ban"
        ? banState
        : next === "unban"
        ? unbanState
        : next === "role"
        ? roleState
        : deleteState;
    if (typeof state.reset === "function") state.reset();
    setPending(next);
  };

  const run = useCallback(
    async (call: () => any, after?: () => void) => {
      try {
        await call().unwrap();
        setPending(null);
        if (after) after();
      } catch (e) {
        // Left open: the dialog renders the error and the moderator decides.
        // Nothing is retried automatically.
      }
    },
    []
  );

  const failed = t("admin.users.actionFailed") || "That didn't work. Nothing was changed.";
  const busy =
    banState.isLoading || unbanState.isLoading || roleState.isLoading || deleteState.isLoading;

  const sectionTitle = "font-display text-sm text-ink-900 dark:text-ink-50";
  const fieldLabel =
    "text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400";
  const fieldValue = "text-sm text-ink-800 dark:text-ink-100 break-words";
  const actionButton =
    "rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800";

  const field = (label: string, value: React.ReactNode, testId?: string) => (
    <div>
      <div className={fieldLabel}>{label}</div>
      <div className={fieldValue} data-testid={testId}>
        {value}
      </div>
    </div>
  );

  return (
    <>
      <div
        data-testid="drawer-backdrop"
        onClick={onClose}
        className="fixed inset-0 z-[60] bg-ink-900/40"
      />
      <div
        ref={panelRef}
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        aria-label={t("admin.users.detailTitle") || "User detail"}
        data-testid="user-detail-drawer"
        className={[
          "fixed inset-y-0 right-0 z-[61] w-full max-w-md overflow-y-auto",
          "border-l border-line bg-surface p-5 shadow-float outline-none",
          "dark:border-line-dark dark:bg-cardbg-dark",
        ].join(" ")}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-center gap-3">
            <Avatar
              name={user.name || "?"}
              src={Array.isArray(user.imageUrls) ? user.imageUrls[0] : undefined}
              size={54}
            />
            <div>
              <div className="font-display text-base text-ink-900 dark:text-ink-50">
                {user.name || "—"}
              </div>
              <div className="text-sm text-ink-500 dark:text-ink-400">
                {user.username ? `@${user.username}` : "—"}
              </div>
            </div>
          </div>
          <button
            type="button"
            data-testid="drawer-close"
            onClick={onClose}
            aria-label={t("admin.common.close") || "Close"}
            className="rounded-chip border border-line px-2 py-1 text-sm text-ink-600 hover:bg-ink-100 dark:border-line-dark dark:text-ink-300 dark:hover:bg-ink-800"
          >
            <X size={16} aria-hidden="true" />
          </button>
        </div>

        {detail.isError ? (
          <div
            data-testid="drawer-error"
            role="status"
            className="mt-4 rounded-card border border-line px-3 py-2 text-sm text-ink-600 dark:border-line-dark dark:text-ink-300"
          >
            {t("admin.common.loadError") || "Couldn't load this section."}
          </div>
        ) : detail.isLoading ? (
          <div
            data-testid="drawer-loading"
            className="mt-4 animate-pulse rounded-card border border-line px-3 py-2 text-sm text-ink-400 dark:border-line-dark"
          >
            {t("admin.common.loading") || "Loading…"}
          </div>
        ) : (
          <>
            <div className="mt-5 grid grid-cols-2 gap-4">
              {field(t("admin.users.email") || "Email", user.email || "—")}
              {field(
                t("admin.users.role") || "Role",
                <Badge tone={isAdmin ? "brand" : "banana"}>{user.role || "user"}</Badge>
              )}
              {field(
                t("admin.users.status") || "Status",
                isBanned
                  ? t("admin.users.banned") || "Banned"
                  : t("admin.users.active") || "Active"
              )}
              {field(t("admin.users.joined") || "Joined", formatWhen(user.createdAt))}
              {field(t("admin.users.lastActive") || "Last active", formatWhen(user.lastActive))}
              {field(
                t("admin.users.languages") || "Languages",
                user.native_language && user.language_to_learn ? (
                  <LanguageExchangePill
                    nativeLanguage={user.native_language}
                    learningLanguage={user.language_to_learn}
                    dense
                  />
                ) : (
                  "—"
                )
              )}
              {field(
                t("admin.users.mode") || "Mode",
                isVip ? (
                  <span className="inline-flex items-center gap-2">
                    <Badge tone="banana">{t("admin.users.vip") || "VIP"}</Badge>
                    <span className="text-xs text-ink-500 dark:text-ink-400">
                      {user.vipSubscription && user.vipSubscription.endDate
                        ? `${t("admin.users.vipUntil") || "until"} ${formatDate(
                            user.vipSubscription.endDate
                          )}`
                        : ""}
                    </span>
                  </span>
                ) : (
                  t("admin.users.regular") || "Regular"
                ),
                "drawer-vip"
              )}
              {field(
                t("admin.users.verified") || "Verified",
                user.isEmailVerified
                  ? t("admin.users.yes") || "Yes"
                  : t("admin.users.no") || "No",
                "drawer-verified"
              )}
            </div>

            {isBanned ? (
              <div className="mt-4 rounded-card border border-line px-3 py-2 text-sm dark:border-line-dark">
                <div className={fieldLabel}>{t("admin.users.banReason") || "Ban reason"}</div>
                <div className={fieldValue}>{user.banReason || "—"}</div>
                <div className="pt-1 text-xs text-ink-500 dark:text-ink-400">
                  {formatWhen(user.bannedAt)}
                </div>
              </div>
            ) : null}

            <h3 className={`mt-6 ${sectionTitle}`}>
              {t("admin.users.activity") || "Activity"}
            </h3>
            <div data-testid="drawer-activity" className="mt-2 grid grid-cols-2 gap-4">
              {field(
                t("admin.users.lastMessage") || "Last message",
                formatWhen(activity.lastMessageAt)
              )}
              {field(
                t("admin.users.messages30d") || "Messages (30d)",
                num(activity.messagesLast30d ?? activity.messages30d)
              )}
              {field(
                t("admin.users.lastMoment") || "Last moment",
                formatWhen(activity.lastMomentAt)
              )}
              {field(
                t("admin.users.moments30d") || "Moments (30d)",
                num(activity.momentsLast30d ?? activity.moments30d)
              )}
            </div>

            <h3 className={`mt-6 ${sectionTitle}`}>
              {t("admin.users.recentActions") || "Recent admin actions"}
            </h3>
            <ul data-testid="drawer-recent-actions" className="mt-2 text-sm">
              {recentActions.length === 0 ? (
                <li className="py-2 text-ink-500 dark:text-ink-400">
                  {t("admin.users.noActions") || "No admin actions against this account."}
                </li>
              ) : (
                recentActions.map((action: any, index: number) => (
                  <li
                    key={String(action?._id ?? index)}
                    className="border-b border-line/70 py-2 last:border-0 dark:border-line-dark/70"
                  >
                    <div className="flex items-baseline justify-between gap-2">
                      <span className="font-medium text-ink-800 dark:text-ink-100">
                        {action?.action || "—"}
                      </span>
                      <span className="whitespace-nowrap text-xs tabular-nums text-ink-500 dark:text-ink-400">
                        {formatWhen(action?.timestamp)}
                      </span>
                    </div>
                    <div className="text-xs text-ink-500 dark:text-ink-400">
                      {(action?.moderator && (action.moderator.name || action.moderator.email)) ||
                        t("admin.users.unknownModerator") ||
                        "Unknown moderator"}
                      {action?.reason ? ` — ${action.reason}` : ""}
                    </div>
                  </li>
                ))
              )}
            </ul>

            <div className="mt-6 flex flex-wrap gap-2 border-t border-line pt-4 dark:border-line-dark">
              <button
                type="button"
                data-testid="drawer-edit"
                disabled={busy}
                onClick={() => setEditing(true)}
                className={`${actionButton} inline-flex items-center gap-1.5`}
              >
                <Pencil className="h-4 w-4" aria-hidden />
                {t("admin.users.edit") || "Edit"}
              </button>
              {isBanned ? (
                <button
                  type="button"
                  data-testid="drawer-unban"
                  disabled={busy}
                  onClick={() => openDialog("unban")}
                  className={actionButton}
                >
                  {t("admin.users.unban") || "Unban"}
                </button>
              ) : (
                <button
                  type="button"
                  data-testid="drawer-ban"
                  disabled={busy}
                  onClick={() => openDialog("ban")}
                  className={actionButton}
                >
                  {t("admin.users.ban") || "Ban"}
                </button>
              )}
              <button
                type="button"
                data-testid="drawer-role"
                disabled={busy}
                onClick={() => openDialog("role")}
                className={actionButton}
              >
                {isAdmin
                  ? t("admin.users.revokeAdmin") || "Revoke admin"
                  : t("admin.users.makeAdmin") || "Make admin"}
              </button>
              <button
                type="button"
                data-testid="drawer-delete"
                disabled={busy}
                onClick={() => openDialog("delete")}
                className={`${actionButton} border-red-300 text-red-700 hover:bg-red-50 dark:border-red-500/40 dark:text-red-300 dark:hover:bg-red-500/10`}
              >
                {t("admin.users.delete") || "Delete"}
              </button>
            </div>
          </>
        )}
      </div>

      {editing ? (
        <EditUserDialog user={user} onClose={() => setEditing(false)} />
      ) : null}

      <ConfirmDialog
        open={pending === "ban"}
        title={t("admin.users.banTitle") || "Ban this user?"}
        body={`${user.name || ""} ${user.email ? `(${user.email})` : ""} ${
          t("admin.users.banBody") || "loses access immediately. The reason is recorded in the audit log."
        }`}
        confirmLabel={t("admin.users.ban") || "Ban"}
        requireReason
        danger
        busy={banState.isLoading}
        error={errorText(banState.error, failed)}
        onCancel={() => setPending(null)}
        onConfirm={(reason) => run(() => banUser({ id: userId, reason }))}
      />

      <ConfirmDialog
        open={pending === "unban"}
        title={t("admin.users.unbanTitle") || "Unban this user?"}
        body={
          t("admin.users.unbanBody") ||
          "They regain access immediately. The reason is recorded in the audit log."
        }
        confirmLabel={t("admin.users.unban") || "Unban"}
        requireReason
        busy={unbanState.isLoading}
        error={errorText(unbanState.error, failed)}
        onCancel={() => setPending(null)}
        onConfirm={(reason) => run(() => unbanUser({ id: userId, reason }))}
      />

      <ConfirmDialog
        open={pending === "role"}
        title={
          isAdmin
            ? t("admin.users.revokeAdminTitle") || "Revoke admin?"
            : t("admin.users.makeAdminTitle") || "Make admin?"
        }
        body={
          isAdmin
            ? t("admin.users.revokeAdminBody") ||
              "They lose the console and every admin route. You cannot revoke your own admin role."
            : t("admin.users.makeAdminBody") ||
              "They gain the console and every admin route, including bans and deletions."
        }
        confirmLabel={
          isAdmin
            ? t("admin.users.revokeAdmin") || "Revoke admin"
            : t("admin.users.makeAdmin") || "Make admin"
        }
        requireReason
        danger={isAdmin}
        busy={roleState.isLoading}
        error={errorText(roleState.error, failed)}
        onCancel={() => setPending(null)}
        onConfirm={(reason) => run(() => changeRole({ id: userId, role: nextRole, reason }))}
      />

      <ConfirmDialog
        open={pending === "delete"}
        title={t("admin.users.deleteTitle") || "Permanently delete this account?"}
        body={
          t("admin.users.deleteBody") ||
          "This erases the account and its content. It cannot be undone."
        }
        confirmLabel={t("admin.users.delete") || "Delete"}
        requireReason
        requireTypedValue={user.email || undefined}
        typedLabel={`${t("admin.users.typeEmail") || "Type the user's email to confirm"}: ${
          user.email || ""
        }`}
        danger
        busy={deleteState.isLoading}
        error={errorText(deleteState.error, failed)}
        onCancel={() => setPending(null)}
        // The user is gone: the drawer has nothing left to show.
        onConfirm={(reason) => run(() => deleteUser({ id: userId, reason }), onClose)}
      />
    </>
  );
};

export default UserDetailDrawer;
