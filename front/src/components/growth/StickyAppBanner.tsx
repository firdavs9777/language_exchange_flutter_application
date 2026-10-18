import React, { useCallback, useEffect, useState } from "react";
import { X } from "lucide-react";
import { isSuppressed, recordDismissal } from "./growthGate";
import StoreLink, { StoreId } from "./StoreLink";
import { useSurfaceOpen } from "./surfaceRegistry";
import brandLogo from "../../assets/logo.png";

const StickyAppBanner: React.FC = () => {
  // Hidden until mounted, for the same reason as PromoCarousel.
  const [hidden, setHidden] = useState(true);
  // Take turns with the announcement banner.
  const annBanner = useSurfaceOpen("announcement-banner");

  // "ios" until the user agent says otherwise, and it only says so after
  // mount: reading navigator during render would bake one store into the
  // prerendered HTML, and React 18 does not patch a mismatched attribute
  // while hydrating (the bug PricingSection documents at length).
  const [platform, setPlatform] = useState<StoreId>("ios");

  useEffect(() => {
    setHidden(
      isSuppressed("sticky-banner", {
        pathname: window.location.pathname,
        referrer: document.referrer,
        viewportWidth: window.innerWidth,
      })
    );
    if (/Android/i.test(navigator.userAgent)) setPlatform("android");
  }, []);

  const dismiss = useCallback(() => {
    recordDismissal("sticky-banner");
    setHidden(true);
  }, []);

  if (hidden || annBanner) return null;

  return (
    // `line`/`ink` rather than `gray-*`: Tailwind's gray is cool-blue and
    // reads cheap beside the teal brand, which is why the palette carries its
    // own warmer neutral. The extra bottom padding clears the iOS home
    // indicator -- this bar is pinned to the bottom edge on phones, which is
    // exactly where the indicator sits.
    //
    // `sticky`, not `fixed`. It pins to the bottom edge identically for the
    // whole homepage, but a fixed bar is out of the flow and so sat on top of
    // whatever the document ended with -- the footer's store buttons and
    // legal links, which no amount of scrolling could bring out from under
    // it. Sticky reserves its own height at the foot of the page instead.
    <div
      data-testid="sticky-app-banner"
      className="sticky bottom-0 z-40 flex items-center gap-3 border-t border-line bg-surface px-4 py-2.5 pb-[calc(0.625rem+env(safe-area-inset-bottom))] shadow-float dark:border-line-dark dark:bg-cardbg-dark"
    >
      <img src={brandLogo} alt="" aria-hidden className="h-9 w-9 rounded-lg" />
      {/* Wrapping, not truncating: at 360px `truncate` turned the title into
          "BanaTalk is bet...". The Install and dismiss controls stay shrink-0
          so the copy is the only thing that reflows. */}
      <div className="min-w-0 flex-1">
        <p className="text-xs font-bold leading-snug text-ink-900 dark:text-ink-50">
          BananaTalk is better in the app
        </p>
        <p className="text-[11px] leading-snug text-ink-500 dark:text-ink-300">
          AI tutor, voice rooms, reels
        </p>
      </div>
      <StoreLink
        store={platform}
        placement="sticky-banner"
        // No `shadow-brand` here: it is a wide teal glow tuned for large
        // CTAs, and on a pill this size it renders as a halo around the
        // button rather than elevation under it.
        className="shrink-0 whitespace-nowrap rounded-full bg-brand-deep px-4 py-1.5 text-xs font-extrabold text-white transition-colors hover:bg-brand-deepest focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-deep"
      >
        Install
      </StoreLink>
      <button
        type="button"
        data-testid="sticky-banner-dismiss"
        onClick={dismiss}
        aria-label="Dismiss"
        // A 40x40 box rather than the 16px glyph plus `p-1` it used to be:
        // this is the control that makes the bar go away, and 26px of it was
        // not enough to hit on a phone. Sized rather than padded because
        // Bootstrap's `.p-N` utilities ship `!important` and win over
        // Tailwind's -- see the note at the top of src/index.css.
        className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-ink-400 transition-colors hover:bg-ink-100 hover:text-ink-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-deep dark:hover:bg-ink-800 dark:hover:text-ink-100"
      >
        <X className="h-4 w-4" aria-hidden />
      </button>
    </div>
  );
};

export default StickyAppBanner;
