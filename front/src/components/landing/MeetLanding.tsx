import React from "react";
import { useTranslation } from "react-i18next";
import HeroDemo from "../home/parts/HeroDemo";
import HowItWorks from "../home/parts/HowItWorks";
import FeatureShowcase from "../home/parts/FeatureShowcase";
import LanguageMarquee from "../home/parts/LanguageMarquee";
import FinalCta from "../home/parts/FinalCta";
import { MEET_COPY, MEET_FEATURES, sayWith } from "./copy";

// /meet: the social half of BananaTalk, argued on its own page.
//
// No new visual components -- the homepage's sections already say this well,
// and a landing page that looks like a different product is a landing page
// nobody trusts. What changes is the copy: the headline, the conversation the
// hero plays out (two people making weekend plans across a language, not a
// grammar drill), the three steps, and which four features are shown.
const MeetLanding: React.FC = () => {
  const { t } = useTranslation();
  const say = sayWith((key: string) => (t(key) as string) || "");
  const c = MEET_COPY;

  return (
    <div data-testid="meet-landing" className="bg-surface dark:bg-canvas-dark">
      <HeroDemo
        headline={say(c.hero.title)}
        headlineAccent={say(c.hero.titleAccent)}
        subtitle={say(c.hero.subtitle)}
        trust={say(c.hero.trust)}
        placement="meet"
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
      <FeatureShowcase title={say(c.featuresTitle)} only={MEET_FEATURES} />
      <LanguageMarquee />
      <FinalCta title={say(c.cta.title)} subtitle={say(c.cta.subtitle)} placement="meet" />
    </div>
  );
};

export default MeetLanding;
