import React from "react";
import { NavLink, Outlet } from "react-router-dom";
import { useTranslation } from "react-i18next";
import RequireAdmin from "./RequireAdmin";

/**
 * The console's frame: a left rail of sections and a content pane.
 *
 * Under `md` (768px) the rail becomes a horizontal, scrollable tab row above
 * the content — the same links, reordered by the breakpoint rather than
 * duplicated, so there is exactly one NavLink per section in the DOM.
 *
 * This module is the entry point of the lazy `/admin` chunk: nothing here is
 * imported by the prerendered routes, and no admin page is ever prerendered.
 */

const SECTIONS: { to: string; key: string; label: string; end?: boolean }[] = [
  { to: "/admin", key: "admin.nav.overview", label: "Overview", end: true },
  { to: "/admin/reach", key: "admin.nav.reach", label: "Reach" },
  { to: "/admin/users", key: "admin.nav.users", label: "Users" },
  { to: "/admin/content", key: "admin.nav.content", label: "Content" },
  { to: "/admin/announcements", key: "admin.nav.announcements", label: "Announcements" },
  { to: "/admin/ai-usage", key: "admin.nav.aiUsage", label: "AI usage" },
  { to: "/admin/audit", key: "admin.nav.audit", label: "Audit log" },
];

const linkClass = ({ isActive }: { isActive: boolean }) =>
  [
    "whitespace-nowrap rounded-chip px-3 py-2 text-sm font-medium transition-colors",
    "md:w-full md:px-4",
    isActive
      ? "bg-brand-deep text-white shadow-card"
      : "text-ink-600 hover:bg-ink-100 dark:text-ink-300 dark:hover:bg-ink-800",
  ].join(" ");

const AdminLayout: React.FC = () => {
  const { t } = useTranslation();

  return (
    <RequireAdmin>
      <div className="min-h-screen bg-canvas dark:bg-canvas-dark">
        <div className="mx-auto w-full max-w-7xl px-4 py-6 md:flex md:gap-8">
          <nav
            aria-label={t("admin.nav.admin") || "Admin"}
            className="-mx-1 flex gap-1 overflow-x-auto px-1 pb-2 md:mx-0 md:w-52 md:shrink-0 md:flex-col md:gap-1 md:overflow-visible md:px-0 md:pb-0"
          >
            <div className="hidden px-4 pb-3 text-eyebrow uppercase text-ink-400 md:block">
              {t("admin.nav.admin") || "Admin"}
            </div>
            {SECTIONS.map((s) => (
              <NavLink key={s.to} to={s.to} end={s.end} className={linkClass}>
                {t(s.key) || s.label}
              </NavLink>
            ))}
          </nav>

          <main className="min-w-0 flex-1 pt-2 md:pt-0">
            <Outlet />
          </main>
        </div>
      </div>
    </RequireAdmin>
  );
};

export default AdminLayout;
