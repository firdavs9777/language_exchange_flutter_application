import React from "react";
import { useTranslation } from "react-i18next";
import { languageFlag } from "../../../utils/languages";
import { MARQUEE_LANGUAGES } from "../../../data/marqueeLanguages";
import StoreLink, { StorePlacement } from "../../growth/StoreLink";

// The 14s hero cycle, as slot offsets. One set of keyframes (tailwind.config.js)
// serves all three bubbles; the delay is what makes it a conversation. A JS
// timer would be the obvious alternative and the wrong one: this page is
// prerendered with renderToString and hydrated, so anything that moved with
// state would either change the server markup or desync on the first paint.
const SLOT_STEP_MS = 2800;
const TRANSLATION_OFFSET_MS = 700;

// Eight flags from the head of the marquee's curated list, drifting behind the
// hero. Fixed table rather than Math.random(): a random position would differ
// between the prerendered HTML and the first client render.
const HERO_FLAGS = [
  { left: "4%", top: "14%", delay: "0s", duration: "22s" },
  { left: "17%", top: "70%", delay: "3.5s", duration: "27s" },
  { left: "29%", top: "6%", delay: "1.2s", duration: "19s" },
  { left: "41%", top: "84%", delay: "5s", duration: "30s" },
  { left: "57%", top: "18%", delay: "2.1s", duration: "24s" },
  { left: "69%", top: "76%", delay: "6.4s", duration: "18s" },
  { left: "83%", top: "28%", delay: "4.2s", duration: "28s" },
  { left: "93%", top: "60%", delay: "7.8s", duration: "21s" },
];

// An opaque overlay, not a decoration: bg-inherit takes the bubble's own
// background (either theme), so while it is up the bubble reads as empty and
// the text behind it looks typed rather than merely faded in. It clears at
// 8.5% of the cycle and never returns until the cycle restarts.
//
// motion-reduce:hidden because reduced motion runs no keyframes at all: the
// overlay would otherwise sit over the text forever.
const TypingDots: React.FC<{ delayMs: number; dotClassName: string }> = ({
  delayMs,
  dotClassName,
}) => (
  <span
    aria-hidden
    data-testid="demo-typing"
    style={{ animationDelay: `${delayMs}ms` }}
    className="absolute inset-0 z-10 flex items-center gap-1.5 rounded-card bg-inherit p-3 motion-safe:animate-bt-type-dots motion-reduce:hidden"
  >
    {[0, 160, 320].map((stagger) => (
      <span
        key={stagger}
        style={{ animationDelay: `${stagger}ms` }}
        className={`h-2 w-2 rounded-full motion-safe:animate-pulse ${dotClassName}`}
      />
    ))}
  </span>
);

export interface HeroDemoMessage {
  /** What the bubble says, in the language it was written in. */
  text: string;
  /** The line under it: the same thing in the reader's language. */
  translation: string;
}

/**
 * Props exist so the landing pages (/meet, /learn-korean) can reuse this hero
 * with their own headline, conversation and store placement. Every one of them
 * defaults to the homepage's copy, which is still resolved here through i18n --
 * so the homepage renders exactly what it rendered before this file grew props.
 */
export interface HeroDemoProps {
  headline?: string;
  headlineAccent?: string;
  subtitle?: string;
  trust?: string;
  /** utm_campaign on both store links. */
  placement?: StorePlacement;
  /** Bubbles, alternating sides from the left. Two on every page so far. */
  messages?: HeroDemoMessage[];
  /** The small caps label on the note card under the conversation. */
  noteLabel?: string;
  /** The note itself; a node, because the homepage's carries emphasis. */
  note?: React.ReactNode;
}

const DEFAULT_MESSAGES: HeroDemoMessage[] = [
  { text: "안녕하세요! 오늘 시간 있어요?", translation: "Hi! Do you have time today?" },
  { text: "Yes! I want practice Korean 😅", translation: "네! 한국어 연습하고 싶어요" },
];

const DEFAULT_NOTE = (
  <>
    "I want to practice" — <b>practice</b> takes <i>to</i>. Try:{" "}
    <i>I want to practice Korean.</i>
  </>
);

const HeroDemo: React.FC<HeroDemoProps> = ({
  headline,
  headlineAccent,
  subtitle,
  trust,
  placement = "hero",
  messages = DEFAULT_MESSAGES,
  noteLabel = "✦ AI TUTOR",
  note = DEFAULT_NOTE,
}) => {
  const { t } = useTranslation();
  const tutorSlotMs = messages.length * SLOT_STEP_MS;

  return (
    <section
      data-testid="hero-demo"
      className="relative overflow-hidden px-4 py-14 sm:py-20 bg-gradient-to-b from-white to-canvas dark:from-canvas-dark dark:to-canvas-dark"
    >
      <div
        aria-hidden
        data-testid="hero-flags"
        className="pointer-events-none absolute inset-0 select-none overflow-hidden"
      >
        {HERO_FLAGS.map((flag, i) => (
          <span
            key={MARQUEE_LANGUAGES[i]}
            style={{
              left: flag.left,
              top: flag.top,
              animationDelay: flag.delay,
              animationDuration: flag.duration,
            }}
            className="absolute text-2xl opacity-[0.16] sm:text-3xl motion-safe:animate-bt-drift dark:opacity-[0.12]"
          >
            {languageFlag(MARQUEE_LANGUAGES[i])}
          </span>
        ))}
      </div>

      <div className="relative z-10 mx-auto grid max-w-5xl items-center gap-10 lg:grid-cols-[1.1fr_.9fr]">
        <div>
          <h1
            data-testid="hero-headline"
            className="text-4xl font-extrabold leading-[1.08] tracking-tight text-gray-900 sm:text-5xl dark:text-gray-50"
          >
            {headline || t("home.hero.title") || "Say it badly."}{" "}
            <span className="text-brand">
              {headlineAccent || t("home.hero.titleAccent") || "We'll translate."}
            </span>
          </h1>
          <p className="mt-4 max-w-md text-base leading-relaxed text-gray-600 dark:text-gray-300">
            {subtitle ||
              t("home.hero.subtitle") ||
              "Free language exchange with native speakers. Write in your language, they read it in theirs, and you learn from the difference."}
          </p>

          <div className="mt-7 flex flex-wrap gap-3">
            <StoreLink
              store="ios"
              placement={placement}
              className="min-w-[11rem] rounded-xl bg-gray-900 px-5 py-3 text-sm font-bold text-white"
            />
            <StoreLink
              store="android"
              placement={placement}
              className="min-w-[11rem] rounded-xl bg-gray-900 px-5 py-3 text-sm font-bold text-white"
            />
          </div>

          <p className="mt-5 text-xs font-medium text-gray-400">
            {trust || t("home.hero.trust") || "Free forever tier · 137 languages · AI tutor 24/7"}
          </p>
        </div>

        {/* The mechanic, shown rather than claimed -- and now played out. */}
        <div className="rounded-card bg-gradient-to-br from-brand/[0.08] to-banana/[0.14] p-5 motion-safe:animate-bt-float">
          <div className="flex flex-col gap-3">
            {messages.map((message, i) => {
              // Even bubbles are the other person's, odd ones are yours: the
              // side, the colour and the dashed rule under the translation all
              // follow from that one fact.
              const mine = i % 2 === 1;
              const slotMs = i * SLOT_STEP_MS;
              return (
                <div
                  key={i}
                  data-testid="demo-message"
                  style={{ animationDelay: `${slotMs}ms` }}
                  className={
                    mine
                      ? "relative max-w-[86%] self-end rounded-card bg-brand p-3 text-white shadow-card motion-safe:animate-bt-msg-in"
                      : "relative max-w-[86%] self-start rounded-card bg-surface p-3 shadow-card motion-safe:animate-bt-msg-in dark:bg-cardbg-dark"
                  }
                >
                  <TypingDots delayMs={slotMs} dotClassName={mine ? "bg-white/70" : "bg-gray-400"} />
                  <p className={mine ? "text-sm" : "text-sm text-gray-900 dark:text-gray-50"}>
                    {message.text}
                  </p>
                  <p
                    style={{ animationDelay: `${slotMs + TRANSLATION_OFFSET_MS}ms` }}
                    className={
                      mine
                        ? "mt-1.5 overflow-hidden border-t border-dashed border-white/40 pt-1.5 text-xs opacity-90 motion-safe:animate-bt-line-in"
                        : "mt-1.5 overflow-hidden border-t border-dashed border-gray-200 pt-1.5 text-xs text-brand motion-safe:animate-bt-line-in dark:border-gray-600"
                    }
                  >
                    {message.translation}
                  </p>
                </div>
              );
            })}

            <div
              data-testid="demo-note"
              style={{ animationDelay: `${tutorSlotMs}ms` }}
              className="relative max-w-[94%] self-start rounded-card border-2 border-banana bg-surface p-3 shadow-card motion-safe:animate-bt-msg-in dark:bg-cardbg-dark"
            >
              <TypingDots delayMs={tutorSlotMs} dotClassName="bg-banana-dark" />
              <p className="text-[10px] font-extrabold tracking-wide text-banana-dark">{noteLabel}</p>
              <p className="mt-1 text-xs text-gray-700 dark:text-gray-200">{note}</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroDemo;
