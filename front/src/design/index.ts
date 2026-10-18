// The shared design primitives. Community, Moments, Profile and Notifications
// import from here; nothing else in src/design is public API.
//
// VALUES ONLY — no type re-exports. This repo pins typescript@3.7.2, which
// cannot parse `export type { X } from "./Y"` (TS 3.8+), and a plain
// `export { X } from "./Y"` makes Babel emit a RUNTIME re-export, which webpack
// then cannot resolve because an interface has no runtime value. Either form
// breaks the production build the moment anything imports this barrel.
//
// Need a prop type? Import it straight from its component, which still exports
// it:  import type { BadgeProps } from "../../design/Badge";
export { default as LanguageExchangePill, dotsForLevel } from "./LanguageExchangePill";
export { default as Avatar } from "./Avatar";
export { default as SurfaceCard } from "./SurfaceCard";
export { default as Badge } from "./Badge";
export { default as FollowButton } from "./FollowButton";
export { default as ConfirmDialog } from "./ConfirmDialog";
export { default as notify, TOAST_MS } from "./notify";
