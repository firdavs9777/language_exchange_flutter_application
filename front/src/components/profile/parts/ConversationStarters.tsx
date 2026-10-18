import React from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Lightbulb, Send } from "lucide-react";
import SurfaceCard from "../../../design/SurfaceCard";
import { matchTypeFor } from "./LanguageMatchCard";
import { sharedTopics } from "./MutualInterests";

/** How many starters the card offers, as in the app (max 3). */
const HOW_MANY = 3;

export interface Starter {
  /** The i18n key, which doubles as the React key and the test handle. */
  key: string;
  text: string;
}

type Translate = (key: string, options?: any) => string;

/**
 * Three openers, chosen the same way every time.
 *
 * Nothing here is random: the app shuffles nothing either, and a suggestion
 * that changes on every render is a suggestion nobody trusts. The candidates
 * are appended in priority order — what the two language pairs have to say
 * first, then a shared interest, then what the profile is learning — and the
 * last three are always available, so the card is never short of three.
 *
 * Each line is a complete message rather than a hint about one: it is what
 * the Send button puts in the chat box, so the viewer sends exactly what they
 * read.
 */
export function buildStarters(
  viewer: any,
  user: any,
  name: string,
  t: Translate
): Starter[] {
  // First name only: "Hi Ada Lovelace!" reads like a form letter. The
  // suggestion strip already greets people this way.
  const who = name.trim().split(" ")[0] || "there";
  const theirNative = String((user && user.native_language) || "").trim();
  const theirLearning = String((user && user.language_to_learn) || "").trim();
  const myNative = String((viewer && viewer.native_language) || "").trim();
  const matchType = matchTypeFor(viewer, user);
  const topics = sharedTopics(viewer, user);
  const candidates: Starter[] = [];

  const add = (key: string, fallback: string, options: any): void => {
    candidates.push({ key, text: t(`communityDetail.starters.${key}`, options) || fallback });
  };

  if (matchType === "perfect") {
    add("perfect", `Hi ${who}! We're a perfect language match — want to swap practice?`, {
      name: who,
    });
  }
  if (matchType === "youLearnTheirs" && theirNative) {
    add("language", `Hi ${who}! I'm learning ${theirNative} — any tips for getting better?`, {
      name: who,
      language: theirNative,
    });
  }
  if (matchType === "theyLearnYours" && myNative) {
    add(
      "teach",
      `Hi ${who}! I saw you're learning ${myNative}. Happy to help if you ever have questions.`,
      { name: who, language: myNative }
    );
  }
  if (matchType === "sameNative") {
    add("sameNative", `Hi ${who}! We share a native language — how's your learning going?`, {
      name: who,
    });
  }
  if (topics.length > 0) {
    add("topic", `Hi ${who}! I saw you're into ${topics[0]} too. What got you started?`, {
      name: who,
      topic: topics[0],
    });
  }
  if (theirLearning) {
    add("targetLearning", `Hi ${who}! How long have you been learning ${theirLearning}?`, {
      name: who,
      language: theirLearning,
    });
  }
  add("generic", `Hi ${who}! I'd love to practise languages together. How's your week going?`, {
    name: who,
  });
  add("practice", `Hi ${who}! What has helped you most with your learning so far?`, {
    name: who,
  });
  add("hello", `Hi ${who}! Your profile caught my eye — how is your day going?`, {
    name: who,
  });

  return candidates.slice(0, HOW_MANY);
}

export interface ConversationStartersProps {
  /** The profile being viewed. */
  userId: string;
  /** The signed-in user's document. Absent means signed out. */
  viewer?: any;
  user?: any;
  name?: string;
}

/**
 * The opener card, above the moments.
 *
 * "Send" does what the message button does — pre-create the room, then open
 * the chat — and carries the line along in `?draft=`, which ChatContent reads
 * into the message box once and then strips from the URL. The pre-create is
 * best-effort for the same reason it is in `ProfileActions`: the chat screen
 * creates the room on the first send anyway, so a failed round trip must not
 * strand the viewer on the profile.
 */
const ConversationStarters: React.FC<ConversationStartersProps> = ({
  userId,
  viewer,
  user,
  name,
}) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  if (!viewer || !userId) return null;

  const starters = buildStarters(viewer, user, String(name || ""), t as Translate);

  const handleSend = (text: string): void => {
    // Into the composer, not sent: the viewer reads it and presses Send.
    navigate(`/chat/${userId}?draft=${encodeURIComponent(text)}`);
  };

  return (
    <SurfaceCard padding="lg">
      <div data-testid="conversation-starters">
        <div className="flex items-center gap-2">
          <Lightbulb className="h-4 w-4 text-brand" aria-hidden />
          <h2 className="text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
            {t("communityDetail.starters.title") || "Conversation starters"}
          </h2>
        </div>

        <ul className="mt-3 space-y-2">
          {starters.map((starter) => (
            <li
              key={starter.key}
              data-testid="conversation-starter"
              data-starter={starter.key}
              className="flex items-start gap-3 rounded-chip border border-line px-3 py-2.5 dark:border-line-dark"
            >
              <p
                id={`starter-${starter.key}`}
                className="flex-1 text-sm text-ink-700 dark:text-ink-200"
              >
                {starter.text}
              </p>
              {/* Three buttons all called "Send" are three identical rows to a
                  screen reader; the description names which line each one
                  sends. */}
              <button
                type="button"
                data-testid="conversation-starter-send"
                aria-describedby={`starter-${starter.key}`}
                onClick={() => handleSend(starter.text)}
                className="inline-flex shrink-0 items-center gap-1.5 rounded-chip bg-brand-deep px-3 py-1.5 text-xs font-semibold text-white transition-colors hover:bg-brand-dark disabled:opacity-60"
              >
                <Send className="h-3.5 w-3.5" aria-hidden />
                {t("communityDetail.starters.send") || "Send"}
              </button>
            </li>
          ))}
        </ul>
      </div>
    </SurfaceCard>
  );
};

export default ConversationStarters;
