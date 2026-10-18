import React from "react";
import {
  ART_FONT,
  BANANA,
  BRAND,
  BRAND_DEEP,
  BRAND_LIGHT,
  INK_100,
  INK_200,
  INK_900,
  PromoArtProps,
  WHITE,
} from "./paint";

/**
 * Moments: three photo cards fanned out, a liked one on top, and the mark that
 * says the post is read in two languages at once.
 *
 * The `A -> 가` pill is the one place in the four drawings that uses real text.
 * Two letters, one of them Hangul: drawing them as paths would mean shipping
 * outlines of somebody's typeface, and the point of the mark is that it is
 * letters. Everything else here is geometry.
 */
const MomentsArt: React.FC<PromoArtProps> = ({ title, titleId, className }) => {
  // Scoped to this instance so two illustrations on one page cannot share a
  // clip path -- ids are global, and `titleId` is already unique per slide.
  const photoClip = `${titleId}-photo`;

  return (
    <svg
      viewBox="0 0 320 240"
      role="img"
      aria-labelledby={titleId}
      focusable="false"
      className={className}
    >
      <title id={titleId}>{title}</title>
      <defs>
        <clipPath id={photoClip}>
          <rect x="106" y="68" width="116" height="94" rx="14" />
        </clipPath>
      </defs>

      <ellipse cx="160" cy="124" rx="146" ry="96" fill={BRAND} opacity="0.12" />

      {/* The two cards underneath: same card, further away. */}
      <rect
        x="48"
        y="46"
        width="128"
        height="140"
        rx="20"
        fill={WHITE}
        opacity="0.45"
        transform="rotate(-12 112 116)"
      />
      <rect
        x="152"
        y="42"
        width="128"
        height="140"
        rx="20"
        fill={WHITE}
        opacity="0.7"
        transform="rotate(9 216 112)"
      />

      {/* The card on top, with its photo. */}
      <rect x="104" y="68" width="140" height="148" rx="22" fill={BRAND} opacity="0.26" />
      <rect x="94" y="56" width="140" height="148" rx="22" fill={WHITE} />
      <rect x="106" y="68" width="116" height="94" rx="14" fill={BRAND_LIGHT} />
      <g clipPath={`url(#${photoClip})`}>
        <circle cx="196" cy="92" r="12" fill={WHITE} />
        <path d="M100 162l42-52 30 38 20-24 34 38z" fill={BRAND_DEEP} />
      </g>
      <rect x="106" y="172" width="74" height="9" rx="4.5" fill={INK_200} />
      <rect x="106" y="187" width="46" height="9" rx="4.5" fill={INK_100} />

      {/* Liked. */}
      <circle cx="226" cy="150" r="19" fill={WHITE} />
      <path
        d="M226 160c-9-6-13-11-13-15a6.8 6.8 0 0113-3.4 6.8 6.8 0 0113 3.4c0 4-4 9-13 15z"
        fill={BANANA}
      />

      {/* Read in both languages. */}
      <rect x="32" y="172" width="118" height="46" rx="23" fill={BRAND} opacity="0.26" />
      <rect x="24" y="164" width="118" height="46" rx="23" fill={WHITE} />
      <text
        x="49"
        y="196"
        textAnchor="middle"
        fontFamily={ART_FONT}
        fontSize="23"
        fontWeight="800"
        fill={INK_900}
      >
        A
      </text>
      <path
        d="M72 182h20m-6-5 6 5-6 5"
        stroke={BRAND}
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />
      <path
        d="M94 194H74m6-5-6 5 6 5"
        stroke={BRAND}
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />
      <text
        x="118"
        y="196"
        textAnchor="middle"
        fontFamily={ART_FONT}
        fontSize="23"
        fontWeight="800"
        fill={BRAND_DEEP}
      >
        가
      </text>
    </svg>
  );
};

export default MomentsArt;
