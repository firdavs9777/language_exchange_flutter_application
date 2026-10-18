import React from "react";
import { CommentMention } from "./types";

/**
 * The comment text with each @mention highlighted, the way the app draws
 * them (comments_main.dart _buildCommentText: primary colour, semibold, not
 * a link). Mentions that point outside the text, have no length, or overlap
 * an earlier one are skipped; the text itself is never dropped.
 */
export const renderWithMentions = (text: string, mentions?: CommentMention[]): React.ReactNode[] => {
  const source = text || "";
  const valid = (Array.isArray(mentions) ? mentions : [])
    .filter(
      (m) =>
        m &&
        typeof m.offset === "number" && typeof m.length === "number" &&
        m.offset >= 0 && m.length > 0 && m.offset < source.length
    )
    .slice()
    .sort((a, b) => (a.offset as number) - (b.offset as number));

  const out: React.ReactNode[] = [];
  let cursor = 0;
  valid.forEach((m, i) => {
    const start = m.offset as number;
    if (start < cursor) return; // overlaps the previous mention
    const end = Math.min(source.length, start + (m.length as number));
    if (start > cursor) out.push(source.slice(cursor, start));
    out.push(
      <span key={`m${i}`} data-testid="comment-mention" className="font-semibold text-brand">
        {source.slice(start, end)}
      </span>
    );
    cursor = end;
  });
  if (cursor < source.length) out.push(source.slice(cursor));
  return out;
};
