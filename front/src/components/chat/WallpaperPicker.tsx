import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Check } from "lucide-react";
import DialogShell from "../../design/DialogShell";
import notify from "../../design/notify";
import {
  DEFAULT_WALLPAPER,
  GRADIENT_WALLPAPERS,
  SOLID_WALLPAPERS,
  themePayload,
  ChatWallpaper,
  isPremiumWallpaper,
} from "../../design/chatWallpapers";
import { useSetConversationThemeMutation } from "../../store/slices/chatSlice";

export interface WallpaperPickerProps {
  /** The conversation the wallpaper belongs to. Empty until one exists. */
  conversationId: string;
  /** The preset currently saved on it. */
  currentPreset: string;
  onClose: () => void;
}

const SWATCH = [
  "group flex flex-col items-center gap-1 rounded-chip border-2 border-transparent p-1",
  "transition-colors hover:border-line focus-visible:border-brand",
].join(" ");

const SWATCH_SELECTED = "border-brand";

const SECTION = "pt-4 text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400";

/**
 * The conversation wallpaper, shared by both people in it.
 *
 * The theme is a preset NAME on the conversation document
 * (`PUT /conversations/:id/theme`), which the server pushes to the other
 * participant as `themeChanged` — so this is not a personal display setting:
 * choosing one changes the room for both of you, exactly as it does in the
 * app.
 *
 * Nothing here spells a colour. Every swatch carries `data-chat-theme` and
 * paints itself from `--chat-bg`, which is the same mechanism the chat pane
 * uses (src/index.css owns the rules), so a preset can only ever look one way
 * in both places. The PUT body does carry the colours — see
 * `design/chatWallpapers.ts` — because the app reads them back off the saved
 * theme.
 *
 * The coin-gated `premium_*` pack the app sells is not offered: it is out of
 * this plan's scope, and an unknown preset falls back to the default surface
 * rather than breaking.
 */
const WallpaperPicker: React.FC<WallpaperPickerProps> = ({
  conversationId,
  currentPreset,
  onClose,
}) => {
  const { t } = useTranslation();
  const [selected, setSelected] = useState<string>(currentPreset || DEFAULT_WALLPAPER);
  const [setConversationTheme, { isLoading }] = useSetConversationThemeMutation();

  const apply = async (): Promise<void> => {
    if (!conversationId) return;
    try {
      await setConversationTheme({
        conversationId: conversationId,
        theme: themePayload(selected),
      }).unwrap();
      notify.success(t("chatPage.wallpaper.saved") || "Wallpaper updated");
      onClose();
    } catch (error) {
      const data: any = error && (error as any).data;
      notify.error(
        (data && (data.message || data.error)) ||
          t("chatPage.wallpaper.failed") ||
          "Couldn't change the wallpaper"
      );
    }
  };

  const renderSwatch = (name: string, label: string) => {
    const isSelected = selected === name;
    return (
      <button
        key={name}
        type="button"
        data-testid={`wallpaper-${name}`}
        aria-pressed={isSelected}
        onClick={() => setSelected(name)}
        className={`${SWATCH}${isSelected ? ` ${SWATCH_SELECTED}` : ""}`}
      >
        <span className="relative block h-14 w-full overflow-hidden rounded-chip border border-line dark:border-line-dark">
          <span
            className="chat-wallpaper-swatch absolute inset-0 block"
            data-chat-theme={name}
          />
          {isSelected ? (
            <Check
              className="absolute right-1 top-1 h-4 w-4 text-white drop-shadow"
              aria-hidden
            />
          ) : null}
        </span>
        <span className="block w-full truncate text-[11px] text-ink-600 dark:text-ink-300">
          {label}
        </span>
      </button>
    );
  };

  const renderGroup = (wallpapers: ChatWallpaper[]) => (
    <div className="grid grid-cols-3 gap-2 pt-2 sm:grid-cols-4">
      {wallpapers.map((wallpaper) =>
        renderSwatch(
          wallpaper.name,
          t(`chatPage.wallpaper.${wallpaper.name}`) || wallpaper.label
        )
      )}
    </div>
  );

  return (
    <DialogShell
      labelledBy="chat-wallpaper-title"
      onClose={onClose}
      testId="chat-wallpaper-dialog"
      backdropTestId="chat-wallpaper-backdrop"
      dismissible={!isLoading}
      panelClassName={[
        "relative flex max-h-[85vh] w-full max-w-lg flex-col overflow-y-auto rounded-card border border-line",
        "bg-surface p-5 shadow-lg",
        "dark:border-line-dark dark:bg-cardbg-dark",
      ].join(" ")}
    >
      <h2
        id="chat-wallpaper-title"
        className="font-display text-base text-ink-900 dark:text-ink-50"
      >
        {t("chatPage.wallpaper.title") || "Wallpaper"}
      </h2>
      <p className="pt-1 text-sm text-ink-600 dark:text-ink-300">
        {t("chatPage.wallpaper.shared") ||
          "Both of you see the wallpaper you choose."}
      </p>

      {/* The chosen preset, at the size a background is actually read at.
          Same class and same attribute as the pane itself. */}
      <div
        data-testid="wallpaper-preview"
        data-chat-theme={selected}
        className="chat-wallpaper-swatch mt-4 h-20 w-full rounded-card border border-line dark:border-line-dark"
      />
      {isPremiumWallpaper(currentPreset) ? (
        <p
          data-testid="wallpaper-premium-hint"
          className="pt-2 text-xs text-ink-500 dark:text-ink-400"
        >
          {t("chatPage.wallpaper.premiumInUse") ||
            "This chat uses a Premium wallpaper from the app. Choosing another one changes it for both of you."}
        </p>
      ) : null}

      <h3 className={SECTION}>{t("chatPage.wallpaper.plain") || "Plain"}</h3>
      <div className="grid grid-cols-3 gap-2 pt-2 sm:grid-cols-4">
        {renderSwatch(
          DEFAULT_WALLPAPER,
          t("chatPage.wallpaper.default") || "Default"
        )}
        {SOLID_WALLPAPERS.map((wallpaper) =>
          renderSwatch(
            wallpaper.name,
            t(`chatPage.wallpaper.${wallpaper.name}`) || wallpaper.label
          )
        )}
      </div>

      <h3 className={SECTION}>{t("chatPage.wallpaper.gradients") || "Gradients"}</h3>
      {renderGroup(GRADIENT_WALLPAPERS)}

      <div className="mt-5 flex justify-end gap-2">
        <button
          type="button"
          data-testid="wallpaper-cancel"
          onClick={onClose}
          disabled={isLoading}
          className="rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
        >
          {t("chatPage.wallpaper.cancel") || "Cancel"}
        </button>
        <button
          type="button"
          data-testid="wallpaper-apply"
          onClick={apply}
          disabled={isLoading || !conversationId}
          aria-busy={isLoading}
          className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white hover:bg-brand-deepest disabled:opacity-50"
        >
          {t("chatPage.wallpaper.apply") || "Apply"}
        </button>
      </div>
    </DialogShell>
  );
};

export default WallpaperPicker;
