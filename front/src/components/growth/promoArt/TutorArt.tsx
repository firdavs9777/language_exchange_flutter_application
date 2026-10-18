import React from "react";
import { BANANA, BRAND, INK_100, INK_200, INK_500, INK_900, PromoArtProps, WHITE } from "./paint";

/**
 * AI tutor: a chat bubble whose sentence has one word struck through, with the
 * correction floating above it in banana yellow and a teal check badge below.
 *
 * Inlined rather than fetched: the band is prerendered, and an <img> to a file
 * would be a round trip and a layout risk on the one surface that is supposed
 * to be instant. Everything is a path on a transparent ground, so the art
 * carries no background of its own and cannot fight the band behind it.
 */
const TutorArt: React.FC<PromoArtProps> = ({ title, titleId, className }) => (
  <svg
    viewBox="0 0 320 240"
    role="img"
    aria-labelledby={titleId}
    focusable="false"
    className={className}
  >
    <title id={titleId}>{title}</title>

    {/* Soft one-tone ground, so the white bubble has something to sit on. */}
    <ellipse cx="160" cy="132" rx="146" ry="96" fill={BRAND} opacity="0.12" />

    {/* The shadow is the bubble again, offset and tinted -- one tone, no blur:
        a gradient here would cost bytes the band cannot spare. */}
    <rect x="36" y="76" width="264" height="128" rx="32" fill={BRAND} opacity="0.26" />

    <path d="M60 176h40l-32 44z" fill={WHITE} />
    <rect x="26" y="62" width="264" height="128" rx="32" fill={WHITE} />

    {/* The sentence. Third bar on the first line is the word being corrected. */}
    <rect x="56" y="94" width="52" height="12" rx="6" fill={INK_200} />
    <rect x="118" y="94" width="38" height="12" rx="6" fill={INK_200} />
    <rect x="166" y="94" width="74" height="12" rx="6" fill={INK_200} />
    <path d="M158 100h90" stroke={INK_500} strokeWidth="5" strokeLinecap="round" />
    <rect x="56" y="126" width="96" height="12" rx="6" fill={INK_100} />
    <rect x="162" y="126" width="60" height="12" rx="6" fill={INK_100} />
    <rect x="56" y="158" width="78" height="12" rx="6" fill={INK_100} />

    {/* The correction, pointing at the word it replaces. */}
    <path d="M194 46h28l-22 26z" fill={BANANA} />
    <rect x="152" y="8" width="104" height="40" rx="20" fill={BANANA} />
    <rect x="170" y="24" width="68" height="9" rx="4.5" fill={INK_900} opacity="0.55" />

    {/* Marked correct. */}
    <circle cx="258" cy="188" r="34" fill={WHITE} />
    <circle cx="258" cy="188" r="27" fill={BRAND} />
    <path
      d="M245 188l9 10 18-21"
      stroke={WHITE}
      strokeWidth="6"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill="none"
    />
  </svg>
);

export default TutorArt;
