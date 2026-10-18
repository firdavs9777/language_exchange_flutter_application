import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { X, Loader2, PartyPopper, Hand } from "lucide-react";
import { Bounce, toast } from "react-toastify";
import { useSendWaveMutation } from "../../store/slices/communitySlice";
import ConfirmDialog from "../../design/ConfirmDialog";

/** Body code of the daily wave-cap 429 (checkLimitations.js checkWaveLimit). */
const WAVE_CAP_CODE = "wave_cap";
const VIP_PAGE = "/settings/vip";

/** Minimal shape needed to send + render a wave target — matches
 * `CommunityMemberCard` (MemberCard.tsx) but kept loose so this sheet can be
 * opened from any surface (list card, profile detail, etc). */
export interface WaveTargetUser {
  _id: string;
  name: string;
  imageUrls?: string[];
}

export interface WaveSheetProps {
  open: boolean;
  targetUser: WaveTargetUser | null;
  onClose: () => void;
  /**
   * The server now holds a wave from the viewer to this person: fired after a
   * sent wave, and after ALREADY_WAVED (an earlier one). Today's cards use it
   * to stop offering a second wave.
   */
  onWaved?: (targetUserId: string, isMutual: boolean) => void;
}

const MESSAGE_MAX_LENGTH = 100;

// Copy lives in eng.json under waves.sheet.chips.<id>.{label,message}; the
// English here is the fallback. The message is what the wave carries, so it
// is sent in the waver's language, as typed text would be.
const EMOJI_CHIPS: { id: string; emoji: string; label: string; message: string }[] = [
  { id: "hi", emoji: "👋", label: "Hi", message: "👋 Hi!" },
  { id: "cool", emoji: "❤️", label: "Cool", message: "❤️ Cool profile!" },
  { id: "hey", emoji: "😊", label: "Hey", message: "😊 Hey there!" },
  { id: "chat", emoji: "🎉", label: "Chat", message: "🎉 Let's chat!" },
  { id: "hello", emoji: "✋", label: "Hello", message: "✋ Hello!" },
  { id: "nice", emoji: "🌟", label: "Nice", message: "🌟 Nice to meet you!" },
];

const ICEBREAKER_PROMPTS: string[] = [
  "Hi! Want to practice languages together?",
  "I noticed we're learning similar languages — hi!",
  "Your profile caught my eye, how's it going?",
  "Hey! What made you start learning a new language?",
];

const WaveSheet: React.FC<WaveSheetProps> = ({ open, targetUser, onClose, onWaved }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [message, setMessage] = useState("");
  const [alreadyWaved, setAlreadyWaved] = useState(false);
  // The daily cap was hit: the sheet turns into the VIP dialog.
  const [capReached, setCapReached] = useState(false);
  const [sendWave, { isLoading }] = useSendWaveMutation();

  // Reset local state every time the sheet opens for a (possibly new) target.
  useEffect(() => {
    if (open) {
      setMessage("");
      setAlreadyWaved(false);
      setCapReached(false);
    }
  }, [open, targetUser?._id]);

  if (!open || !targetUser) return null;

  const avatar = targetUser.imageUrls?.[0];
  const chips = EMOJI_CHIPS.map((chip) => ({
    ...chip,
    label: t(`waves.sheet.chips.${chip.id}.label`) || chip.label,
    message: t(`waves.sheet.chips.${chip.id}.message`) || chip.message,
  }));
  const icebreakers = ICEBREAKER_PROMPTS.map(
    (fallback, i) => t(`waves.sheet.icebreakers.${i}`) || fallback
  );
  if (capReached) {
    return (
      <ConfirmDialog
        open
        title={t("waves.cap.title") || "Daily wave limit reached"}
        body={
          t("waves.cap.body") ||
          "You've used today's free waves. VIP members can wave without a daily limit, or try again tomorrow."
        }
        confirmLabel={t("waves.cap.seeVip") || "See VIP"}
        cancelLabel={t("waves.cap.notNow") || "Not now"}
        onConfirm={() => {
          onClose();
          navigate(VIP_PAGE);
        }}
        onCancel={onClose}
      />
    );
  }

  const handleChipClick = (chipMessage: string) => {
    setMessage(chipMessage.slice(0, MESSAGE_MAX_LENGTH));
  };

  const handleSend = async () => {
    if (alreadyWaved || isLoading) return;
    try {
      const result = await sendWave({
        targetUserId: targetUser._id,
        message: message.trim() || undefined,
      }).unwrap();

      const isMutual = !!result?.data?.isMutual;
      if (onWaved) onWaved(targetUser._id, isMutual);
      if (isMutual) {
        toast.success(
          t("waves.sheet.match", { name: targetUser.name }) ||
            `🎉 It's a match! You and ${targetUser.name} both waved at each other.`,
          { position: "top-right", autoClose: 3500, theme: "dark", transition: Bounce }
        );
      } else {
        toast.success(
          t("waves.sheet.sent", { name: targetUser.name }) ||
            `Wave sent to ${targetUser.name}!`,
          { position: "top-right", autoClose: 2000, theme: "dark", transition: Bounce }
        );
      }
      onClose();
    } catch (err: any) {
      const code = err?.data?.code;
      if (code === "ALREADY_WAVED") {
        setAlreadyWaved(true);
        if (onWaved) onWaved(targetUser._id, false);
        return;
      }
      // The daily cap. The server answers 429 with this code only while
      // WAVE_CAP_ENABLED is on; the route's rate limiter sends a 429 with no
      // code and keeps the plain toast below (the app's waveErrorAction).
      if (err?.status === 429 && code === WAVE_CAP_CODE) {
        setCapReached(true);
        return;
      }
      toast.error(
        err?.data?.error ||
          err?.data?.message ||
          t("waves.sheet.sendError") ||
          "Failed to send wave",
        { position: "top-right", autoClose: 3000, theme: "dark", transition: Bounce }
      );
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center"
      role="dialog"
      aria-modal="true"
      aria-label={t("waves.sheet.title", { name: targetUser.name }) || `Send a wave to ${targetUser.name}`}
    >
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />

      <div
        data-testid="wave-sheet"
        className="relative w-full sm:max-w-md max-h-[90vh] bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl flex flex-col overflow-hidden"
      >
        {/* Header */}
        <div className="bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] text-white px-5 py-4 flex items-center gap-3">
          <div className="w-11 h-11 rounded-full overflow-hidden bg-white/20 shrink-0 flex items-center justify-center">
            {avatar ? (
              <img src={avatar} alt={targetUser.name} className="w-full h-full object-cover" />
            ) : (
              <span className="text-lg font-semibold">
                {targetUser.name?.[0]?.toUpperCase() || "?"}
              </span>
            )}
          </div>
          <div className="flex-1 min-w-0">
            <h2 className="text-base font-semibold truncate">
              {t("waves.sheet.title", { name: targetUser.name }) || `Send a wave to ${targetUser.name}`}
            </h2>
            <p className="text-xs text-teal-50">{t("waves.sheet.subtitle") || "Say hi and break the ice 👋"}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t("waves.sheet.close") || "Close"}
            className="p-2 hover:bg-white/10 rounded-full transition-colors shrink-0"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-5 py-4 space-y-5">
          {alreadyWaved ? (
            <div className="flex flex-col items-center text-center py-6 gap-3">
              <div className="p-4 rounded-full bg-teal-50">
                <Hand className="w-8 h-8 text-teal-500" />
              </div>
              <p className="text-gray-700 font-medium">
                {t("waves.sheet.alreadyTitle", { name: targetUser.name }) || `You already waved at ${targetUser.name}`}
              </p>
              <p className="text-sm text-gray-500">
                {t("waves.sheet.alreadyBody") ||
                  "You can only wave once per person — send them a message instead to keep the conversation going."}
              </p>
            </div>
          ) : (
            <>
              {/* Emoji quick-reply chips */}
              <section>
                <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
                  {t("waves.sheet.quickReplies") || "Quick replies"}
                </h3>
                <div className="flex flex-wrap gap-2">
                  {chips.map((chip) => (
                    <button
                      key={chip.id}
                      type="button"
                      onClick={() => handleChipClick(chip.message)}
                      className={`flex items-center gap-1.5 px-3 py-2 rounded-full text-sm font-medium transition-all ${
                        message === chip.message
                          ? "bg-teal-500 text-white"
                          : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                      }`}
                    >
                      <span aria-hidden>{chip.emoji}</span>
                      {chip.label}
                    </button>
                  ))}
                </div>
              </section>

              {/* Icebreaker prompts */}
              <section>
                <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
                  {t("waves.sheet.icebreakersTitle") || "Icebreakers"}
                </h3>
                <div className="flex flex-col gap-2">
                  {icebreakers.map((prompt) => (
                    <button
                      key={prompt}
                      type="button"
                      onClick={() => handleChipClick(prompt)}
                      className={`text-start px-3 py-2 rounded-xl text-sm transition-all border ${
                        message === prompt
                          ? "bg-teal-50 border-teal-300 text-teal-700"
                          : "bg-white border-gray-200 text-gray-600 hover:bg-gray-50"
                      }`}
                    >
                      {prompt}
                    </button>
                  ))}
                </div>
              </section>

              {/* Custom message */}
              <section>
                <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
                  {t("waves.sheet.yourMessage") || "Your message"}
                </h3>
                <textarea
                  value={message}
                  onChange={(e) => setMessage(e.target.value.slice(0, MESSAGE_MAX_LENGTH))}
                  placeholder={t("waves.sheet.placeholder") || "Write a custom message (optional)…"}
                  rows={3}
                  maxLength={MESSAGE_MAX_LENGTH}
                  className="w-full rounded-xl border border-gray-200 px-3 py-2 text-sm text-gray-800 focus:outline-none focus:ring-2 focus:ring-teal-400 resize-none"
                />
                <div className="text-end text-xs text-gray-400 mt-1">
                  {message.length}/{MESSAGE_MAX_LENGTH}
                </div>
              </section>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="px-5 py-4 border-t border-gray-100 flex items-center gap-3">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 py-3 rounded-xl font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 transition-colors"
          >
            {alreadyWaved ? t("waves.sheet.close") || "Close" : t("waves.sheet.cancel") || "Cancel"}
          </button>
          <button
            type="button"
            data-testid="wave-sheet-send"
            onClick={handleSend}
            disabled={alreadyWaved || isLoading}
            className="flex-[2] py-3 rounded-xl font-semibold text-white bg-gradient-to-r from-[#00BFA5] to-[#00ACC1] hover:shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {isLoading ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <PartyPopper className="w-4 h-4" />
            )}
            {alreadyWaved ? t("waves.sheet.already") || "Already waved" : t("waves.sheet.send") || "Send wave"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default WaveSheet;
