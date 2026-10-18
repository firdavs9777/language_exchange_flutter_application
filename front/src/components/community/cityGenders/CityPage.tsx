import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Search } from "lucide-react";
import MemberCard, { CommunityMemberCard } from "../MemberCard";
import WaveSheet from "../WaveSheet";
import { COUNTRY_PINS, countryLabel } from "./countryPins";
import { useMemberPages, languageMatchParams } from "./useMemberPages";
import "./cityGenders.scss";

const CityPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const me = useSelector((s: any) => s.auth && s.auth.userInfo && s.auth.userInfo.user);
  const [country, setCountry] = useState<string | null>(null);
  const [cityInput, setCityInput] = useState("");
  const [city, setCity] = useState("");
  const [waveTarget, setWaveTarget] = useState<CommunityMemberCard | null>(null);

  const params = country
    ? Object.assign({ country }, languageMatchParams(me))
    : city
    ? Object.assign({ search: city }, languageMatchParams(me))
    : null;
  const { members, isLoading, isError, hasMore, loadMore } = useMemberPages(params);
  const searchCity = () => {
    const value = cityInput.trim();
    if (!value) return;
    setCountry(null);
    setCity(value);
  };

  return (
    <section className="cg-page" data-testid="city-page">
      <header className="cg-head">
        <Link to="/communities" className="vr-link">
          {t("communityCity.back") || "Community"}
        </Link>
        <h1>{t("communityCity.title") || "People by place"}</h1>
      </header>
      <div className="cg-search">
        <Search size={16} aria-hidden />
        <input
          data-testid="city-search"
          value={cityInput}
          placeholder={t("communityCity.searchPlaceholder") || "Search a city"}
          onChange={(e) => setCityInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") searchCity();
          }}
        />
        <button type="button" className="vr-btn vr-btn--primary" data-testid="city-search-go" onClick={searchCity}>
          {t("communityCity.search") || "Search"}
        </button>
      </div>
      <ul className="cg-chips" aria-label={t("communityCity.countries") || "Countries"}>
        {COUNTRY_PINS.map((pin) => (
          <li key={pin.name}>
            <button
              type="button"
              data-testid={`city-country-${pin.name}`}
              className={country === pin.name ? "cg-chip is-active" : "cg-chip"}
              aria-pressed={country === pin.name}
              onClick={() => {
                setCity("");
                setCountry(pin.name);
              }}
            >
              <span aria-hidden>{pin.flag}</span> {countryLabel(pin, i18n.language)}
            </button>
          </li>
        ))}
      </ul>
      {params && (
        <>
          <h2 className="cg-results-title">
            {country
              ? countryLabel(COUNTRY_PINS.filter((p) => p.name === country)[0], i18n.language)
              : (t("communityCity.searchTitle", { query: city }) as string) || `People in “${city}”`}
          </h2>
          {isError && <p className="vr-error">{t("communityCity.error") || "Couldn't load people. Try again."}</p>}
          {!isLoading && !isError && members.length === 0 && (
            <p className="vr-empty" data-testid="city-empty">
              {t("communityCity.empty") || "No one here matches yet. Try another place."}
            </p>
          )}
          <div className="cg-grid" data-testid="city-results">
            {members.map((m: any) => (
              <MemberCard key={m._id} user={m} onWave={(u) => setWaveTarget(u)} onOpen={(u) => navigate(`/community/${u._id}`)} />
            ))}
          </div>
          {hasMore && (
            <button type="button" className="vr-btn vr-btn--ghost cg-more" data-testid="member-pages-more" onClick={loadMore}>
              {t("communityCity.more") || "Show more"}
            </button>
          )}
        </>
      )}
      <WaveSheet
        open={!!waveTarget}
        targetUser={waveTarget ? { _id: waveTarget._id, name: waveTarget.name, imageUrls: waveTarget.imageUrls } : null}
        onClose={() => setWaveTarget(null)}
      />
    </section>
  );
};

export default CityPage;
