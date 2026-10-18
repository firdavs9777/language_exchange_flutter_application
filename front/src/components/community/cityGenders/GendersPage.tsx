import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import MemberCard, { CommunityMemberCard } from "../MemberCard";
import WaveSheet from "../WaveSheet";
import { useGetCommunityCountQuery } from "../../../store/slices/communitySlice";
import { useMemberPages, languageMatchParams } from "./useMemberPages";
import "./cityGenders.scss";

type Gender = "female" | "male";

const GendersPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user);
  const [gender, setGender] = useState<Gender>("female");
  const [waveTarget, setWaveTarget] = useState<CommunityMemberCard | null>(null);
  const lang = languageMatchParams(me);
  const { members, isLoading, isError, hasMore, loadMore } = useMemberPages(Object.assign({ gender }, lang));
  const female = useGetCommunityCountQuery(Object.assign({ gender: "female" }, lang));
  const male = useGetCommunityCountQuery(Object.assign({ gender: "male" }, lang));
  const count = (q: any) => (q && q.data && q.data.data && typeof q.data.data.count === "number" ? q.data.data.count : null);

  const tab = (g: Gender, label: string, q: any) => (
    <button
      type="button"
      role="tab"
      aria-selected={gender === g}
      data-testid={`genders-${g}`}
      className={gender === g ? "cg-chip is-active" : "cg-chip"}
      onClick={() => setGender(g)}
    >
      {label} <span data-testid={`genders-count-${g}`}>{count(q) === null ? "" : count(q)}</span>
    </button>
  );

  return (
    <section className="cg-page" data-testid="genders-page">
      <header className="cg-head">
        <Link to="/communities" className="vr-link">
          {t("communityGenders.back") || "Community"}
        </Link>
        <h1>{t("communityGenders.title") || "Browse by gender"}</h1>
      </header>
      <div className="cg-chips" role="tablist">
        {tab("female", t("communityGenders.female") || "Women", female)}
        {tab("male", t("communityGenders.male") || "Men", male)}
      </div>
      {isError && <p className="vr-error">{t("communityGenders.error") || "Couldn't load people. Try again."}</p>}
      {!isLoading && !isError && members.length === 0 && <p className="vr-empty">{t("communityGenders.empty") || "No one matches yet."}</p>}
      <div className="cg-grid" data-testid="genders-results">
        {members.map((m: any) => (
          <MemberCard key={m._id} user={m} onWave={(u) => setWaveTarget(u)} onOpen={(u) => navigate(`/community/${u._id}`)} />
        ))}
      </div>
      {hasMore && (
        <button type="button" className="vr-btn vr-btn--ghost cg-more" data-testid="member-pages-more" onClick={loadMore}>
          {t("communityGenders.more") || "Show more"}
        </button>
      )}
      <WaveSheet
        open={!!waveTarget}
        targetUser={waveTarget ? { _id: waveTarget._id, name: waveTarget.name, imageUrls: waveTarget.imageUrls } : null}
        onClose={() => setWaveTarget(null)}
      />
    </section>
  );
};

export default GendersPage;
