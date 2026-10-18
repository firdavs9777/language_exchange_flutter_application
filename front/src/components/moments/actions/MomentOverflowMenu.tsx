import React, { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useTranslation } from "react-i18next";
import { useSelector } from "react-redux";
import { HiDotsHorizontal } from "react-icons/hi";
import ReportMomentDialog from "./ReportMomentDialog";
import BlockAuthorDialog from "./BlockAuthorDialog";

interface Props {
  momentId: string;
  /** The author as the API returns it: an id, or a populated user. */
  author: any;
  className?: string;
}

export const authorIdOf = (author: any): string =>
  (author && (typeof author === "string" ? author : author._id)) || "";

/**
 * The "⋯" menu on someone else's moment. Signed-out readers and the author
 * get nothing: there is nothing in it they could use.
 */
const MomentOverflowMenu: React.FC<Props> = ({ momentId, author, className }) => {
  const { t } = useTranslation();
  const viewerId = useSelector((state: any) => state.auth.userInfo?.user?._id);
  const [open, setOpen] = useState(false);
  const [reporting, setReporting] = useState(false);
  const [blocking, setBlocking] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const authorId = authorIdOf(author);

  useEffect(() => {
    if (!open) return;
    const close = (event: MouseEvent) => {
      if (ref.current && !ref.current.contains(event.target as Node)) setOpen(false);
    };
    const escape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setOpen(false);
    };
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", escape);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", escape);
    };
  }, [open]);

  if (!viewerId || !authorId || authorId === viewerId) return null;

  // The menu sits inside a card that links to the moment: its own clicks
  // must neither follow the link nor reach the card's handlers.
  const stop = (event: React.SyntheticEvent) => {
    event.preventDefault();
    event.stopPropagation();
  };

  return (
    <div ref={ref} className="relative flex-shrink-0">
      <button
        type="button"
        aria-label={t("moments_section.report.menu") || "More options"}
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={(event) => {
          stop(event);
          setOpen((v) => !v);
        }}
        className={
          className ||
          "p-1 xs:p-2 -mr-1 xs:-mr-2 rounded-full hover:bg-gray-100 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-200"
        }
      >
        <HiDotsHorizontal className="w-4 h-4 xs:w-5 xs:h-5 text-gray-500" />
      </button>
      {open && (
        <div role="menu" className="absolute end-0 z-20 mt-1 min-w-[10rem] rounded-xl border border-gray-200 bg-white py-1 shadow-lg">
          <button
            type="button"
            role="menuitem"
            onClick={(event) => {
              stop(event);
              setOpen(false);
              setReporting(true);
            }}
            className="block w-full px-4 py-2 text-start text-sm text-red-600 hover:bg-red-50"
          >
            {t("moments_section.report.report") || "Report"}
          </button>
          <button
            type="button"
            role="menuitem"
            onClick={(event) => {
              stop(event);
              setOpen(false);
              setBlocking(true);
            }}
            className="block w-full px-4 py-2 text-start text-sm text-red-600 hover:bg-red-50"
          >
            {t("profile.actions.block") || "Block"}
          </button>
        </div>
      )}
      {/* Portalled out of the card's <a>, and React events stopped short of
          the card's Link, so nothing typed or clicked in it navigates. */}
      {reporting &&
        createPortal(
          <div onClick={(event) => event.stopPropagation()}>
            <ReportMomentDialog type="moment" targetId={momentId} authorId={authorId} onClose={() => setReporting(false)} />
          </div>,
          document.body
        )}
      {blocking &&
        createPortal(
          <div onClick={(event) => event.stopPropagation()}>
            <BlockAuthorDialog
              authorId={authorId}
              authorName={author && typeof author === "object" ? author.name : undefined}
              onClose={() => setBlocking(false)}
            />
          </div>,
          document.body
        )}
    </div>
  );
};

export default MomentOverflowMenu;
