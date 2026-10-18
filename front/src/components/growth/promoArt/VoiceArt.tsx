import React from "react";
import { BANANA, BRAND, INK_100, INK_200, PromoArtProps, WHITE } from "./paint";

// The waveform, as data: x offset and height, laid out on one baseline so the
// bars cannot drift apart when one of them is tuned. The two tallest are the
// banana ones -- the peak of the sentence, and the only warm thing in the
// drawing.
const BASELINE = 158;
const BARS: { x: number; h: number; loud?: boolean }[] = [
  { x: 124, h: 34 },
  { x: 146, h: 66 },
  { x: 168, h: 100 },
  { x: 190, h: 116, loud: true },
  { x: 212, h: 78 },
  { x: 234, h: 96, loud: true },
  { x: 256, h: 50 },
  { x: 278, h: 72 },
  { x: 298, h: 30 },
];

/**
 * Voice notes and rooms: a microphone with the waveform of what was just said
 * sweeping away from it, and the shared-location card tucked in behind.
 */
const VoiceArt: React.FC<PromoArtProps> = ({ title, titleId, className }) => (
  <svg
    viewBox="0 0 320 240"
    role="img"
    aria-labelledby={titleId}
    focusable="false"
    className={className}
  >
    <title id={titleId}>{title}</title>

    <ellipse cx="160" cy="128" rx="148" ry="96" fill={BRAND} opacity="0.12" />

    {/* The location card, behind everything the waveform does. */}
    <g transform="rotate(8 250 56)">
      <rect x="206" y="24" width="104" height="76" rx="18" fill={BRAND} opacity="0.26" />
      <rect x="198" y="16" width="104" height="76" rx="18" fill={WHITE} />
      <path d="M228 30c-10 0-18 8-18 18 0 13 18 30 18 30s18-17 18-30c0-10-8-18-18-18z" fill={BRAND} />
      <circle cx="228" cy="48" r="6" fill={WHITE} />
      <rect x="256" y="38" width="34" height="9" rx="4.5" fill={INK_200} />
      <rect x="256" y="55" width="24" height="9" rx="4.5" fill={INK_100} />
    </g>

    {/* The microphone. */}
    <ellipse cx="68" cy="214" rx="46" ry="8" fill={BRAND} opacity="0.25" />
    <rect x="40" y="40" width="56" height="96" rx="28" fill={BRAND} />
    <rect x="56" y="60" width="24" height="7" rx="3.5" fill={WHITE} opacity="0.85" />
    <rect x="56" y="76" width="24" height="7" rx="3.5" fill={WHITE} opacity="0.85" />
    <rect x="56" y="92" width="24" height="7" rx="3.5" fill={WHITE} opacity="0.85" />
    <path
      d="M28 118a40 40 0 0080 0"
      stroke={WHITE}
      strokeWidth="10"
      strokeLinecap="round"
      fill="none"
    />
    <path d="M68 158v36" stroke={WHITE} strokeWidth="10" strokeLinecap="round" />
    <path d="M44 202h48" stroke={WHITE} strokeWidth="10" strokeLinecap="round" />

    {BARS.map((bar) => (
      <rect
        key={bar.x}
        x={bar.x}
        y={BASELINE - bar.h / 2}
        width="12"
        height={bar.h}
        rx="6"
        fill={bar.loud ? BANANA : WHITE}
      />
    ))}
  </svg>
);

export default VoiceArt;
