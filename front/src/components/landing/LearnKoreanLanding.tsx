import React from "react";
import { useTranslation } from "react-i18next";
import HeroDemo from "../home/parts/HeroDemo";
import HowItWorks from "../home/parts/HowItWorks";
import FeatureShowcase from "../home/parts/FeatureShowcase";
import LanguageMarquee from "../home/parts/LanguageMarquee";
import FinalCta from "../home/parts/FinalCta";
import { LEARN_KOREAN_COPY, LEARN_KOREAN_FEATURES, sayWith } from "./copy";

// /learn-korean: for someone who wants Korean and found us searching for it.
//
// Same sections as the homepage with the copy retargeted, because the argument
// is the same one: the hero plays a real Korean exchange -- Hangul as people
// actually type it, the translation under it, and the tutor note on 존댓말 vs
// 반말 that every learner needs before their second message.
const LearnKoreanLanding: React.FC = () => {
  const { t } = useTranslation();
  const say = sayWith((key: string) => (t(key) as string) || "");
  const c = LEARN_KOREAN_COPY;

  return (
    <div data-testid="learn-korean-landing" className="bg-surface dark:bg-canvas-dark">
      <HeroDemo
        headline={say(c.hero.title)}
        headlineAccent={say(c.hero.titleAccent)}
        subtitle={say(c.hero.subtitle)}
        trust={say(c.hero.trust)}
        placement="learn-korean"
        messages={c.hero.messages.map((m) => ({
          text: say(m.text),
          translation: say(m.translation),
        }))}
        noteLabel={say(c.hero.noteLabel)}
        note={say(c.hero.noteBody)}
      />
      <HowItWorks
        title={say(c.howItWorks.title)}
        steps={c.howItWorks.steps.map((s, i) => ({
          n: String(i + 1),
          title: say(s.title),
          body: say(s.body),
        }))}
      />
      <FeatureShowcase title={say(c.featuresTitle)} only={LEARN_KOREAN_FEATURES} />
      <LanguageMarquee />
      <FinalCta title={say(c.cta.title)} subtitle={say(c.cta.subtitle)} placement="learn-korean" />
    </div>
  );
};

export default LearnKoreanLanding;
