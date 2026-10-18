import React, { useCallback, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { ChevronLeft, ChevronRight, X } from "lucide-react";
import { PROMO_SLIDES, PromoSlide, promoKey } from "../../data/promoSlides";
import { trackEvent } from "../../analytics/track";
import { gaEvent } from "../../analytics/ga";
import StoreLink from "./StoreLink";
import { isSuppressed, recordDismissal } from "./growthGate";

const ROTATE_MS = 6000;
const PLACEMENT = "promo-carousel";

/**
 * One slide: the argument on the left, the picture of it on the right.
 *
 * All four are mounted at once, stacked in a single grid cell, and the ones
 * that are not showing are `invisible` -- which takes them out of the tab
 * order and the accessibility tree without changing the band's height.
 */
const Slide: React.FC<{ slide: PromoSlide; active: boolean }> = ({ slide, active }) => {
  const { t } = useTranslation();
  const label = (field: string, fallback: string) =>
    t(promoKey(slide.key, field)) || fallback;

  // The illustration is a component, not a URL: nothing to fetch, nothing to
  // decode, and the first slide is painted by the prerendered HTML itself.
  const Art = slide.art;

  const onCtaTap = () => {
    // Measurement is never worth a lost install: both trackers are optional.
    try {
      trackEvent("cta_tap", { placement: PLACEMENT, platform: "web" });
    } catch {
      /* ignored */
    }
    try {
      gaEvent("cta_tap", { placement: PLACEMENT, platform: "web" });
    } catch {
      /* ignored */
    }
  };

  return (
    <div
      data-testid="promo-slide"
      data-active={active ? "true" : "false"}
      id={`promo-panel-${slide.key}`}
      role="tabpanel"
      aria-labelledby={`promo-tab-${slide.key}`}
      aria-hidden={active ? undefined : true}
      className={
        "col-start-1 row-start-1 flex flex-col-reverse transition-opacity duration-500 " +
        "motion-reduce:transition-none sm:grid sm:grid-cols-[minmax(0,1fr)_14rem] " +
        "sm:items-center sm:gap-x-[2rem] lg:grid-cols-[minmax(0,1fr)_17rem] " +
        (active ? "opacity-100" : "pointer-events-none opacity-0 invisible")
      }
    >
      <div className="pb-[2.25rem] pt-[0.5rem] sm:py-[1.75rem]">
        <p className="bt-eyebrow text-brand-light">{label("eyebrow", slide.eyebrow)}</p>
        <p className="mt-[0.5rem] font-display text-xl font-extrabold leading-tight tracking-tight text-white sm:text-2xl">
          {label("title", slide.title)}
        </p>
        <p className="mt-[0.5rem] max-w-md text-sm leading-relaxed text-ink-300">
          {label("body", slide.body)}
        </p>

        <div className="mt-[1.125rem] flex flex-wrap items-center gap-x-[0.625rem] gap-y-[0.5rem]">
          {/* Below 640px the store is a coin flip we do not have to call:
              /download?go=1 reads the user agent after the hop. Above it,
              there is room to offer both and skip the interstitial. */}
          <a
            href="/download?go=1"
            data-testid="promo-cta"
            onClick={onCtaTap}
            tabIndex={active ? undefined : -1}
            className="inline-flex items-center justify-center rounded-full bg-brand px-[1.125rem] py-[0.5rem] text-sm font-extrabold text-ink-950 sm:hidden"
          >
            {label("cta", slide.cta)}
          </a>
          <span className="hidden gap-x-[0.625rem] sm:flex">
            <StoreLink
              store="ios"
              placement={PLACEMENT}
              variant="button"
              className="rounded-full bg-white px-[1rem] py-[0.5rem] text-sm font-extrabold text-ink-950"
            />
            <StoreLink
              store="android"
              placement={PLACEMENT}
              variant="button"
              className="rounded-full border-[1px] border-white/30 px-[1rem] py-[0.5rem] text-sm font-extrabold text-white"
            />
          </span>
        </div>
      </div>

      {/* Fixed aspect box, same 4:3 for all four drawings: the slot has its
          final size before the art is in it, so nothing moves when a slide
          advances and nothing moves on the way to interactive. */}
      <div className="relative mx-auto aspect-[320/240] w-[9.5rem] sm:mx-0 sm:w-full">
        <Art
          title={label("alt", slide.alt)}
          titleId={`promo-art-${slide.key}`}
          className="absolute inset-0 h-full w-full"
        />
      </div>
    </div>
  );
};

interface PromoBandProps {
  index: number;
  onSelect: (i: number) => void;
  onStep: (delta: number) => void;
  onDismiss: () => void;
  onKeyDown: (event: React.KeyboardEvent) => void;
  onPauseChange: (paused: boolean) => void;
}

/**
 * The band itself, split from the gate above it on purpose: PromoCarousel
 * renders nothing at all until it has a DOM to measure, and a component that
 * returns null must not have called useTranslation on the way there -- the
 * prerender would pay for an i18n subscription it never uses.
 */
const PromoBand: React.FC<PromoBandProps> = ({
  index,
  onSelect,
  onStep,
  onDismiss,
  onKeyDown,
  onPauseChange,
}) => {
  const { t } = useTranslation();
  const label = t("growth.promo.label") || "What the BananaTalk app does";

  // Both arrows, one set of classes: round, translucent over the ink band, and
  // positioned twice. Below 640px they sit on the dots' row, to the right of
  // them -- there is no edge to put them on that a thumb would not cover, and
  // the band's bottom padding is already reserved for that row. From 640px up
  // they move to the middle of the band's left and right edges, inside the
  // max-w-5xl column so they hug the content instead of the viewport; the
  // column gains its own horizontal padding at that breakpoint so an arrow
  // never lands on the copy, and the dismiss button is a corner away.
  const arrow =
    "absolute bottom-[0.125rem] z-20 flex h-[2rem] w-[2rem] items-center justify-center " +
    "rounded-full border-[1px] border-white/20 bg-white/10 text-white " +
    "hover:bg-white/20 sm:bottom-auto sm:top-1/2 sm:h-[2.25rem] sm:w-[2.25rem] " +
    "sm:-translate-y-1/2";

  // A visitor steering by hand outranks the timer: stepping pauses the
  // rotation the same way hovering the band does, and the same mouseleave or
  // focusout starts it again.
  const step = (delta: number) => {
    onPauseChange(true);
    onStep(delta);
  };

  return (
    <section
      data-testid="promo-carousel"
      aria-roledescription="carousel"
      aria-label={label}
      onKeyDown={onKeyDown}
      onMouseEnter={() => onPauseChange(true)}
      onMouseLeave={() => onPauseChange(false)}
      onFocus={() => onPauseChange(true)}
      onBlur={() => onPauseChange(false)}
      className="relative overflow-hidden bg-ink-950 text-white"
    >
      {/* One soft teal light source behind the art, so the band reads as a
          surface rather than as a black rectangle. Decorative, no hit area. */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-y-0 right-0 w-2/3 bg-gradient-to-l from-brand/25 to-transparent"
      />

      <button
        type="button"
        data-testid="promo-dismiss"
        onClick={onDismiss}
        aria-label={t("growth.promo.dismiss") || "Dismiss app promotion"}
        className="absolute right-[0.5rem] top-[0.5rem] z-20 rounded-full p-[0.375rem] text-ink-300 hover:bg-white/10 hover:text-white"
      >
        <X className="h-4 w-4" />
      </button>

      <div className="relative mx-auto max-w-5xl px-[1rem] sm:px-[3.5rem]">
        <div className="grid">
          {PROMO_SLIDES.map((slide, i) => (
            <Slide key={slide.key} slide={slide} active={i === index} />
          ))}
        </div>

        <button
          type="button"
          data-testid="promo-prev"
          onClick={() => step(-1)}
          aria-label={t("growth.promo.prev") || "Previous slide"}
          className={`${arrow} left-[8.5rem] sm:left-[0.25rem]`}
        >
          <ChevronLeft className="h-4 w-4" />
        </button>
        <button
          type="button"
          data-testid="promo-next"
          onClick={() => step(1)}
          aria-label={t("growth.promo.next") || "Next slide"}
          className={`${arrow} left-[11.25rem] sm:left-auto sm:right-[0.25rem]`}
        >
          <ChevronRight className="h-4 w-4" />
        </button>

        <div
          role="tablist"
          aria-label={label}
          className="absolute bottom-[1rem] left-[1rem] flex gap-x-[0.375rem] sm:left-[3.5rem]"
        >
          {PROMO_SLIDES.map((slide, i) => (
            <button
              key={slide.key}
              type="button"
              role="tab"
              id={`promo-tab-${slide.key}`}
              data-testid="promo-dot"
              onClick={() => onSelect(i)}
              aria-controls={`promo-panel-${slide.key}`}
              aria-selected={i === index}
              aria-current={i === index ? "true" : undefined}
              aria-label={t(promoKey(slide.key, "eyebrow")) || slide.eyebrow}
              tabIndex={i === index ? 0 : -1}
              className={`h-[0.25rem] w-[1.5rem] rounded-full ${
                i === index ? "bg-brand" : "bg-white/30"
              }`}
            />
          ))}
        </div>
      </div>
    </section>
  );
};

const PromoCarousel: React.FC = () => {
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const [reduceMotion, setReduceMotion] = useState(false);
  // Hidden until mounted. Suppression depends on viewport, referrer and
  // stored dismissals, none of which exist at prerender time; deciding in an
  // effect keeps the prerendered HTML and the first client render identical.
  const [dismissed, setDismissed] = useState(true);

  useEffect(() => {
    setDismissed(
      isSuppressed(PLACEMENT, {
        pathname: window.location.pathname,
        referrer: document.referrer,
        viewportWidth: window.innerWidth,
      })
    );
    // jsdom has no matchMedia, and neither does every embedded browser.
    try {
      if (typeof window.matchMedia === "function") {
        setReduceMotion(window.matchMedia("(prefers-reduced-motion: reduce)").matches);
      }
    } catch {
      /* no preference we can read: rotate as usual */
    }
  }, []);

  useEffect(() => {
    if (paused || dismissed || reduceMotion) return;
    const id = window.setInterval(
      () => setIndex((i) => (i + 1) % PROMO_SLIDES.length),
      ROTATE_MS
    );
    return () => window.clearInterval(id);
  }, [paused, dismissed, reduceMotion]);

  const dismiss = useCallback(() => {
    recordDismissal(PLACEMENT);
    setDismissed(true);
  }, []);

  const step = useCallback((delta: number) => {
    setIndex((i) => (i + delta + PROMO_SLIDES.length) % PROMO_SLIDES.length);
  }, []);

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent) => {
      if (event.key === "ArrowRight") {
        event.preventDefault();
        step(1);
      } else if (event.key === "ArrowLeft") {
        event.preventDefault();
        step(-1);
      }
    },
    [step]
  );

  if (dismissed) return null;

  return (
    <PromoBand
      index={index}
      onSelect={setIndex}
      onStep={step}
      onDismiss={dismiss}
      onKeyDown={onKeyDown}
      onPauseChange={setPaused}
    />
  );
};

export default PromoCarousel;
