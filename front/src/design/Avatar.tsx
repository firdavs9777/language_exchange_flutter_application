import React from "react";

export interface AvatarProps {
  src?: string;
  /** Drives the initials fallback. */
  name: string;
  size?: 40 | 54 | 72 | 80;
  /**
   * Explicit, never derived from a user object: Community and Profile get
   * this field from controllers/users.js and Moments from
   * controllers/moments.js, so a primitive that reached into a user shape
   * would have to know which one it was holding.
   */
  hasStory?: boolean;
  isOnline?: boolean;
  /** Native-language flag, rendered bottom-left. */
  flag?: string;
  /**
   * Makes the avatar a real button. Opt-in: in a list row the avatar is
   * decoration and a button there would be noise, but a profile picture people
   * tap to see the photo is a control and has to behave like one.
   */
  onClick?: () => void;
  /** The button's accessible name. Required whenever `onClick` is given. */
  label?: string;
  /**
   * Load eagerly instead of lazily. For the one avatar that IS the page --
   * a profile header -- where deferring the main subject is the wrong trade.
   * Everywhere else this component appears in a list, so lazy is the default.
   */
  priority?: boolean;
}

const Avatar: React.FC<AvatarProps> = ({
  src,
  name,
  size = 54,
  hasStory = false,
  isOnline = false,
  flag,
  onClick,
  label,
  priority = false,
}) => {
  const initial = (name || "").trim().charAt(0).toUpperCase() || "?";
  const dot = size >= 72 ? "h-4 w-4" : "h-3 w-3";

  const face = src ? (
    <img
      data-testid="avatar-image"
      src={src}
      alt={name}
      /* The component already knows its size, so the box can always be
         reserved -- an unsized avatar in a list shifts every row below it
         as the faces arrive. */
      width={size}
      height={size}
      loading={priority ? "eager" : "lazy"}
      decoding="async"
      className="h-full w-full rounded-full object-cover"
    />
  ) : (
    <div
      data-testid="avatar-initials"
      role="img"
      aria-label={name || "Unknown user"}
      className="flex h-full w-full items-center justify-center rounded-full bg-gradient-to-br from-brand-light to-banana-light font-bold text-brand-dark"
      style={{ fontSize: Math.round(size / 2.7) }}
    >
      {initial}
    </div>
  );

  const Box: any = onClick ? "button" : "div";

  return (
    <Box
      data-testid="avatar"
      type={onClick ? "button" : undefined}
      onClick={onClick}
      aria-label={onClick ? label || name : undefined}
      className={`relative shrink-0${onClick ? " cursor-pointer" : ""}`}
      style={{ width: size, height: size }}
    >
      {hasStory ? (
        <div
          data-testid="avatar-story-ring"
          className="h-full w-full rounded-full bg-gradient-to-tr from-brand via-banana to-brand-light p-[3px]"
        >
          <div className="h-full w-full rounded-full bg-surface p-[2px] dark:bg-cardbg-dark">
            {face}
          </div>
        </div>
      ) : (
        face
      )}

      {flag && (
        <span
          data-testid="avatar-flag"
          aria-hidden
          className="absolute -bottom-0.5 -left-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-surface text-[11px] leading-none shadow-card dark:bg-cardbg-dark"
        >
          {flag}
        </span>
      )}

      {isOnline && (
        <span
          data-testid="avatar-online-dot"
          role="img"
          aria-label="Online"
          className={`absolute -bottom-0.5 -right-0.5 ${dot} rounded-full border-2 border-surface bg-[#4CAF50] dark:border-cardbg-dark`}
        />
      )}
    </Box>
  );
};

export default Avatar;
