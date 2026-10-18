// Copy for the two landing pages, as key + English pairs.
//
// The repo's idiom is `t("key") || "English"`. Spread across JSX that idiom
// leaves the English inventory scattered through the markup, and the locale
// pass (task B7, scripts/i18n/merge-keys.js) then has to go looking for it.
// Here each line is written once, next to the key it will eventually be
// translated under, and the page reads it through `sayWith(t)`.
//
// Until that pass lands, `t` misses and the English below is what renders --
// which is exactly the behaviour the idiom promises.

export interface CopyLine {
  /** i18n key, under the page's namespace (`meet.*` / `learnKorean.*`). */
  key: string;
  /** English, and the fallback until every locale carries the key. */
  en: string;
}

const line = (key: string, en: string): CopyLine => ({ key, en });

export type Say = (copy: CopyLine) => string;

/** Binds a `t` to the fallback idiom: a translation if there is one, else English. */
export function sayWith(t: (key: string) => string): Say {
  return (copy: CopyLine) => t(copy.key) || copy.en;
}

export interface DemoLineCopy {
  text: CopyLine;
  translation: CopyLine;
}

export interface LandingCopy {
  hero: {
    title: CopyLine;
    titleAccent: CopyLine;
    subtitle: CopyLine;
    trust: CopyLine;
    messages: DemoLineCopy[];
    noteLabel: CopyLine;
    noteBody: CopyLine;
  };
  howItWorks: {
    title: CopyLine;
    steps: { title: CopyLine; body: CopyLine }[];
  };
  featuresTitle: CopyLine;
  cta: {
    title: CopyLine;
    subtitle: CopyLine;
  };
}

// --- /meet -----------------------------------------------------------------
//
// The page is about friendship across borders, and the spec is explicit that
// it is not a dating page: the word "date" appears nowhere here, and a test
// in MeetLanding.test.tsx keeps it that way.
export const MEET_COPY: LandingCopy = {
  hero: {
    title: line("meet.hero.title", "Meet people from other countries"),
    titleAccent: line("meet.hero.titleAccent", "who actually write back."),
    subtitle: line(
      "meet.hero.subtitle",
      "BananaTalk is where you make international friends by talking to native speakers. Pick a language, say hi, and every message arrives translated — so neither of you has to be fluent first."
    ),
    trust: line("meet.hero.trust", "Free forever tier · 137 languages · Every message translated both ways"),
    messages: [
      {
        text: line("meet.hero.demo.1.text", "Bora ver o pôr do sol no sábado?"),
        translation: line("meet.hero.demo.1.translation", "Want to watch the sunset on Saturday?"),
      },
      {
        text: line("meet.hero.demo.2.text", "Yes! Is it still warm there in September?"),
        translation: line("meet.hero.demo.2.translation", "Sim! Ainda faz calor aí em setembro?"),
      },
    ],
    noteLabel: line("meet.hero.note.label", "✦ TRANSLATED BOTH WAYS"),
    noteBody: line(
      "meet.hero.note.body",
      "She wrote Portuguese and you read English. You wrote English and she read Portuguese. Neither of you had to switch languages."
    ),
  },
  howItWorks: {
    title: line("meet.howItWorks.title", "Making a friend here takes three steps"),
    steps: [
      {
        title: line("meet.howItWorks.steps.1.title", "Pick a language, not a profile"),
        body: line(
          "meet.howItWorks.steps.1.body",
          "Choose the language or the country you are curious about. We show you the people already learning yours — it is a language exchange, so you both get something."
        ),
      },
      {
        title: line("meet.howItWorks.steps.2.title", "Say hi in your own words"),
        body: line(
          "meet.howItWorks.steps.2.body",
          "Write in the language you think in. It lands in theirs, instantly, so the first message is never the hard part."
        ),
      },
      {
        title: line("meet.howItWorks.steps.3.title", "Keep talking"),
        body: line(
          "meet.howItWorks.steps.3.body",
          "Voice notes, photos, Moments, calls. The conversations that stick are the ones that outlive the practice."
        ),
      },
    ],
  },
  featuresTitle: line("meet.features.title", "Built for conversations that keep going"),
  cta: {
    title: line("meet.cta.title", "Someone in another country is awake right now"),
    subtitle: line("meet.cta.subtitle", "Free to start. No card, no trial countdown."),
  },
};

/** Feature keys from FeatureShowcase's FEATURES: the social half of the app. */
export const MEET_FEATURES = ["findPartner", "moments", "voiceRooms", "gatherings"];

// --- /learn-korean ---------------------------------------------------------
//
// Hangul as it is actually typed, plus the one correction every learner needs
// first: 존댓말 against 반말 (spec §5.4).
export const LEARN_KOREAN_COPY: LandingCopy = {
  hero: {
    title: line("learnKorean.hero.title", "Learn Korean by chatting"),
    titleAccent: line("learnKorean.hero.titleAccent", "with actual Koreans."),
    // translator note: "your language" means the reader's own language, whatever
    // it is. Never render it as "English" -- a Spanish reader writes Spanish here.
    subtitle: line(
      "learnKorean.hero.subtitle",
      "Trade languages with Korean native speakers who want yours in return. You try it in 한국어, they answer in the Korean people really use, and the AI tutor fixes what you got wrong — privately."
    ),
    trust: line("learnKorean.hero.trust", "Free forever tier · Korean native speakers · AI tutor 24/7"),
    messages: [
      {
        text: line("learnKorean.hero.demo.1.text", "주말에 뭐 했어요?"),
        translation: line("learnKorean.hero.demo.1.translation", "What did you do this weekend?"),
      },
      {
        text: line("learnKorean.hero.demo.2.text", "친구 만났다! 진짜 재미있었어"),
        translation: line("learnKorean.hero.demo.2.translation", "I met a friend! It was really fun"),
      },
    ],
    noteLabel: line("learnKorean.hero.note.label", "✦ AI TUTOR"),
    noteBody: line(
      "learnKorean.hero.note.body",
      "존댓말 vs 반말: she asked with 했어요, the polite form. You answered in 반말, which is for close friends. Match her for now: 친구 만났어요! 진짜 재미있었어요."
    ),
  },
  howItWorks: {
    title: line("learnKorean.howItWorks.title", "Why Korean sticks when you chat"),
    steps: [
      {
        title: line("learnKorean.howItWorks.steps.1.title", "The Korean that shows up in real chats"),
        body: line(
          "learnKorean.howItWorks.steps.1.body",
          "Your textbook teaches 합니다. Your partner types 했어요, ㅋㅋ and 헐 — the Korean waiting for you in a real conversation."
        ),
      },
      {
        title: line("learnKorean.howItWorks.steps.2.title", "존댓말 and 반말, felt rather than memorised"),
        body: line(
          "learnKorean.howItWorks.steps.2.body",
          "Politeness is a choice you make in every sentence. Reading a native speaker's choices teaches it faster than a table of endings ever will."
        ),
      },
      {
        title: line("learnKorean.howItWorks.steps.3.title", "Corrected without the embarrassment"),
        body: line(
          "learnKorean.howItWorks.steps.3.body",
          "The AI tutor marks up your Korean where only you can see it, so a language exchange never turns into a test. Your partner just sees you trying, which is the part that keeps them replying."
        ),
      },
    ],
  },
  featuresTitle: line("learnKorean.features.title", "Three things a textbook cannot give you"),
  cta: {
    title: line("learnKorean.cta.title", "Korean speakers are learning your language right now"),
    subtitle: line("learnKorean.cta.subtitle", "Free to start. No card, no trial countdown."),
  },
};

/** Translation, the tutor, and someone to talk to: the Korean learner's path. */
export const LEARN_KOREAN_FEATURES = ["chatTranslate", "aiTutor", "findPartner"];
