// The "get the app" carousel, as data. Four slides, each one a thing the app
// does that the web cannot: the copy on the left is the argument and the
// illustration on the right is the picture of it.
//
// The strings here are the English source. The component resolves each one
// through `t("growth.promo.<key>.<field>")` and falls back to the value below,
// so a locale that has not been translated yet renders English instead of a
// raw key (src/utils/i18n.ts returns "" for a missing key on purpose). The key
// list for the translators lives at .superpowers/sdd/promo-keys.json.
//
// Each slide's art is an inline SVG component from
// src/components/growth/promoArt/, not a file under public/: the band is
// prerendered and above the fold, so the drawings ship in the markup rather
// than as four more round trips, and they inherit the page's colours instead
// of baking a background into a bitmap. They replaced cropped screenshots of
// the app, which read as four unrelated photographs of a phone.
import React from "react";
import TutorArt from "../components/growth/promoArt/TutorArt";
import VoiceArt from "../components/growth/promoArt/VoiceArt";
import MomentsArt from "../components/growth/promoArt/MomentsArt";
import InboxArt from "../components/growth/promoArt/InboxArt";
import { PromoArtProps } from "../components/growth/promoArt/paint";

export interface PromoSlide {
  /** Stable id: the React key, the dot's id, and the i18n key segment. */
  key: string;
  /** The illustration for this slide, inlined as an <svg role="img">. */
  art: React.ComponentType<PromoArtProps>;
  /** What the illustration shows, for a reader who cannot see it. */
  alt: string;
  eyebrow: string;
  title: string;
  body: string;
  /** Label on the single "get the app" button shown below 640px. */
  cta: string;
}

export const PROMO_SLIDES: PromoSlide[] = [
  {
    key: "tutor",
    art: TutorArt,
    alt: "An illustration of a chat bubble with one word crossed out and the correction floating above it, next to a check mark",
    eyebrow: "AI tutor",
    title: "Fix your Korean as you type",
    body: "Private corrections on every message, plus quizzes and grammar drills between chats.",
    cta: "Get the app",
  },
  {
    key: "voice",
    art: VoiceArt,
    alt: "An illustration of a microphone with a sound wave sweeping across it and a shared location card behind",
    eyebrow: "Voice notes & rooms",
    title: "Hear how it really sounds",
    body: "Send voice notes, share where you are, and join live voice rooms with native speakers.",
    cta: "Get the app",
  },
  {
    key: "moments",
    art: MomentsArt,
    alt: "An illustration of three overlapping photo cards with a heart and a translation mark reading A to 가",
    eyebrow: "Moments & stories",
    title: "Share your week in two languages",
    body: "Post photos and thoughts; friends read them translated and correct you kindly.",
    cta: "Get the app",
  },
  {
    key: "inbox",
    art: InboxArt,
    alt: "An illustration of three conversations stacked in an inbox, one of them unread, with a hand waving hello",
    eyebrow: "Real conversations",
    title: "People who actually write back",
    body: "Your chats, waves and reactions in one inbox — read, translated, answered.",
    cta: "Get the app",
  },
];

/** The i18n path for one field of one slide. */
export function promoKey(slideKey: string, field: string): string {
  return `growth.promo.${slideKey}.${field}`;
}
