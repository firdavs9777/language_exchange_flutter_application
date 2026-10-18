import React from "react";
import { Navigate, useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { useGetPublicAnnouncementQuery } from "../../store/slices/announcementsSlice";
import { useAnnouncementActions } from "./AnnouncementActions";
import Loader from "../Loader";

const Body: React.FC<{ a: any }> = ({ a }) => {
  const { primary } = useAnnouncementActions(a);
  return (
    <article className="mx-auto my-8 max-w-2xl overflow-hidden rounded-3xl bg-surface shadow-card dark:bg-cardbg-dark">
      {a.imageUrl ? <img src={a.imageUrl} alt="" className="max-h-80 w-full object-cover" /> : (
        <div className="grid h-40 place-items-center bg-gradient-to-br from-brand-deepest via-brand to-brand-light">
          <span aria-hidden="true" className="text-6xl">{a.emoji || "📢"}</span>
        </div>
      )}
      <div className="p-6 sm:p-8">
        <h1 className="text-2xl font-bold text-ink-900 dark:text-ink-50">{a.title}</h1>
        <p data-testid="ann-page-body" className="mt-4 whitespace-pre-line text-base leading-relaxed text-ink-700 dark:text-ink-200">{a.body}</p>
        {primary && a.buttonLabel ? (
          <button type="button" onClick={primary}
            className="mt-6 rounded-xl bg-brand-deep px-5 py-3 font-bold text-white hover:bg-brand-deepest">{a.buttonLabel}</button>
        ) : null}
      </div>
    </article>
  );
};

const AnnouncementPage: React.FC = () => {
  const { id = "" } = useParams();
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const loggedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo));
  const { currentData, error, isFetching } = useGetPublicAnnouncementQuery({ id, lang: i18n.language }, { skip: !loggedIn });
  // Only ever render the announcement that belongs to this route.
  const data = currentData && currentData.id === id ? currentData : undefined;
  const goBack = () => {
    const idx = (window.history.state as any)?.idx;
    if (typeof idx === "number" && idx > 0) navigate(-1);
    else navigate("/");
  };

  if (!loggedIn) return <Navigate to={`/login?redirect=${encodeURIComponent(`/announcement/${id}`)}`} replace />;
  if (isFetching && !data) return <Loader />;
  if (error || !data) {
    return (
      <div className="mx-auto my-16 max-w-md text-center">
        <p className="text-ink-600 dark:text-ink-300">{t("announcements.ended")}</p>
        <button type="button" onClick={goBack} className="mt-4 text-sm font-semibold text-brand-deep">{t("announcements.back")}</button>
      </div>
    );
  }
  return <Body a={data} />;
};

export default AnnouncementPage;
