import React from "react";
import { Link, Navigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { useGetIndividualStoryQuery, useGetUserStoriesQuery } from "../../store/slices/storiesSlice";
import OpenInApp from "../linking/OpenInApp";
import Loader from "../Loader";

// /story/<storyId>: where story share links land (the app's share sheet from
// 2.7.0, the web chat's story cards). The viewer is keyed by the AUTHOR
// (/stories/<userId>), so this page looks the story up, then hands over to
// the viewer positioned on it. GET /stories/:id needs a session: signed-out
// visitors get a card instead of a blank page.

const OBJECT_ID = /^[0-9a-fA-F]{24}$/;

const idOf = (ref: any): string =>
  ref && typeof ref === "object" ? String(ref._id || "") : String(ref || "");

const listOf = (resp: any): any[] =>
  Array.isArray(resp) ? resp : resp && Array.isArray(resp.data) ? resp.data : [];

/** Index of the story in its author's list; 0 when it is not there. */
export function storyIndexIn(stories: any[], storyId: string): number {
  const i = stories.findIndex((s) => s && s._id === storyId);
  return i < 0 ? 0 : i;
}

const Card: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="mx-auto my-16 max-w-md rounded-3xl bg-surface p-8 text-center shadow-card dark:bg-cardbg-dark">
    {children}
  </div>
);

const LINK_BTN =
  "inline-block rounded-xl bg-brand-deep px-5 py-3 font-bold text-white hover:bg-brand-deepest";
const SECONDARY_BTN =
  "rounded-xl border border-brand-deep px-5 py-3 font-bold text-brand-deep hover:bg-brand-deep/10";

const StoryLinkPage: React.FC = () => {
  const { id = "" } = useParams();
  const { t } = useTranslation();
  const loggedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo));
  const valid = OBJECT_ID.test(id);

  const story = useGetIndividualStoryQuery(id, { skip: !loggedIn || !valid });
  const storyData = story.currentData && (story.currentData.data || story.currentData);
  // Only ever follow the story that belongs to this route.
  const authorId = storyData && storyData._id === id ? idOf(storyData.user) : "";
  const author = useGetUserStoriesQuery(authorId, { skip: !authorId });

  const expired = (
    <Card>
      <p className="text-ink-700 dark:text-ink-200">
        {t("stories.linkPage.expired") || "This story has expired or was deleted. Stories disappear after 24 hours."}
      </p>
      <Link to="/stories" className={`mt-6 ${LINK_BTN}`}>
        {t("stories.linkPage.browse") || "See current stories"}
      </Link>
    </Card>
  );

  if (!valid) return expired;

  if (!loggedIn) {
    return (
      <Card>
        <h1 className="text-xl font-bold text-ink-900 dark:text-ink-50">
          {t("stories.linkPage.sign_in_title") || "Someone shared a story with you"}
        </h1>
        <p className="mt-3 text-ink-700 dark:text-ink-200">
          {t("stories.linkPage.sign_in_body") || "Sign in to watch it, or open it in the BananaTalk app."}
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          <Link to={`/login?redirect=${encodeURIComponent(`/story/${id}`)}`} className={LINK_BTN}>
            {t("stories.linkPage.sign_in") || "Sign in"}
          </Link>
          <OpenInApp type="story" id={id} className={SECONDARY_BTN} />
        </div>
      </Card>
    );
  }

  if (story.error) {
    const status = (story.error as any).status;
    if (status === 404) return expired;
    if (status === 403) {
      return (
        <Card>
          <p className="text-ink-700 dark:text-ink-200">
            {t("stories.linkPage.unavailable") || "This story isn't available to you."}
          </p>
          <Link to="/stories" className={`mt-6 ${LINK_BTN}`}>
            {t("stories.linkPage.browse") || "See current stories"}
          </Link>
        </Card>
      );
    }
    return (
      <Card>
        <p className="text-ink-700 dark:text-ink-200">
          {t("stories.linkPage.failed") || "We couldn't load this story."}
        </p>
        <button type="button" onClick={() => story.refetch && story.refetch()} className={`mt-6 ${LINK_BTN}`}>
          {t("stories.linkPage.retry") || "Try again"}
        </button>
      </Card>
    );
  }

  if (authorId && (author.currentData || author.error)) {
    const startIndex = author.currentData ? storyIndexIn(listOf(author.currentData), id) : 0;
    return <Navigate to={`/stories/${authorId}`} replace state={{ startIndex }} />;
  }

  return <Loader />;
};

export default StoryLinkPage;
