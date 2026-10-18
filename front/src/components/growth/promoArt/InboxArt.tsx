import React from "react";
import { BANANA, BRAND, BRAND_DEEP, BRAND_LIGHT, INK_100, INK_200, PromoArtProps, WHITE } from "./paint";

// Three rows, one shape. Written as data so the stack cannot go crooked when
// a spacing is tuned: the avatar tint is the only thing that differs.
const ROWS = [
  { y: 32, avatar: BRAND },
  { y: 96, avatar: BRAND_LIGHT },
  { y: 160, avatar: BRAND_DEEP },
];

/**
 * The inbox: three conversations waiting, the first one unread, and a hand
 * waving hello over the stack.
 */
const InboxArt: React.FC<PromoArtProps> = ({ title, titleId, className }) => (
  <svg
    viewBox="0 0 320 240"
    role="img"
    aria-labelledby={titleId}
    focusable="false"
    className={className}
  >
    <title id={titleId}>{title}</title>

    <ellipse cx="160" cy="126" rx="146" ry="98" fill={BRAND} opacity="0.12" />

    {ROWS.map((row) => (
      <g key={row.y}>
        <rect x="30" y={row.y + 8} width="228" height="52" rx="26" fill={BRAND} opacity="0.26" />
        <rect x="22" y={row.y} width="228" height="52" rx="26" fill={WHITE} />
        <circle cx="56" cy={row.y + 26} r="18" fill={row.avatar} />
        <rect x="86" y={row.y + 13} width="98" height="10" rx="5" fill={INK_200} />
        <rect x="86" y={row.y + 29} width="66" height="10" rx="5" fill={INK_100} />
      </g>
    ))}

    {/* One of them has not been read yet. */}
    <circle cx="224" cy="58" r="9" fill={BANANA} />

    {/* Someone waved. */}
    <g transform="translate(206 128) rotate(-16)">
      <rect x="2" y="6" width="14" height="44" rx="7" fill={BANANA} />
      <rect x="17" y="-2" width="14" height="52" rx="7" fill={BANANA} />
      <rect x="32" y="0" width="14" height="50" rx="7" fill={BANANA} />
      <rect x="46" y="12" width="14" height="40" rx="7" fill={BANANA} />
      <rect x="0" y="26" width="60" height="56" rx="24" fill={BANANA} />
      <rect x="-13" y="44" width="28" height="16" rx="8" fill={BANANA} transform="rotate(-28 1 52)" />
      <path d="M68 34a20 20 0 010 38" stroke={BANANA} strokeWidth="5" strokeLinecap="round" fill="none" opacity="0.55" />
      <path d="M80 26a30 30 0 010 54" stroke={BANANA} strokeWidth="5" strokeLinecap="round" fill="none" opacity="0.3" />
    </g>
  </svg>
);

export default InboxArt;
