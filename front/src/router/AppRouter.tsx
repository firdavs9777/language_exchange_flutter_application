import {
  createBrowserRouter,
  createRoutesFromElements,
  Route,
  useParams,
} from "react-router-dom";
import App from "../App";
import HomeScreen from "../components/home/HomeMain";

import MainCommnity from "../components/community/MainCommunity";
import Login from "../components/auth/Login";
import MainMoments from "../components/moments/MainMoments";
import Register from "../components/auth/Register";
import MomentDetail from "../components/moments/MomentDetail";
import CreateMoment from "../components/moments/CreateMoment";
import ProfileScreen from "../components/profile/Profile";
import CoursesMain from "../components/courses/CoursesMain";
import CommunityDetail from "../components/community/CommunityDetail";
import UserFollowersList from "../components/profile/UserFollowers";
import UserFollowingList from "../components/profile/UserFollowing";
import UserVisitorsList from "../components/profile/UserVisitors";
import MyMoments from "../components/profile/MyMoments";
import EditProfile from "../components/profile/EditProfile";
import MainChat from "../components/chat/MainChat";
import ForgetPassword from "../components/auth/ForgetPassword";
import AuthCallback from "../components/auth/AuthCallback";
import EditMyMoment from "../components/profile/EditMyMoment";
import MainStories from "../components/stories/MainStories";
import PrivacyPolicy from "../components/navbar/PrivacyPolicy";
import DataDeletion from "../components/navbar/DataDeletion";
import SupportPage from "../components/support/SupportMain";
import TermsOfUse from "../components/navbar/TermsOfUse";
import DownloadApp from "../components/download/DownloadApp";

// Settings
import Settings from "../components/settings/Settings";
import PrivacySettings from "../components/settings/PrivacySettings";
import NotificationSettings from "../components/settings/NotificationSettings";
import VipSettings from "../components/settings/VipSettings";
import LanguageSettings from "../components/settings/LanguageSettings";
import BlockedUsers from "../components/settings/BlockedUsers";
import CloseFriends from "../components/settings/CloseFriends";

// Learning
import LearningDashboard from "../components/learning/LearningDashboard";
import Vocabulary from "../components/learning/Vocabulary";
import VocabularyReview from "../components/learning/VocabularyReview";
import Lessons from "../components/learning/Lessons";
import LessonDetail from "../components/learning/LessonDetail";
import Quizzes from "../components/learning/Quizzes";
import Leaderboard from "../components/learning/Leaderboard";
import Achievements from "../components/learning/Achievements";
import Challenges from "../components/learning/Challenges";

// Community
import NearbyUsers from "../components/community/NearbyUsers";
import Waves from "../components/community/Waves";
import Topics from "../components/community/Topics";

// Chat
import NewChat from "../components/chat/NewChat";
import ChatSettings from "../components/chat/ChatSettings";
import MediaGallery from "../components/chat/MediaGallery";

// Stories
import Highlights from "../components/stories/Highlights";

// Moments
import SavedMoments from "../components/moments/SavedMoments";

const MainChatWrapper = () => {
  const { userId } = useParams();
  return <MainChat key={userId || "no-user"} />;
};

const AppRouter = createBrowserRouter(
  createRoutesFromElements(
    <Route path="/" element={<App />}>
      <Route index element={<HomeScreen />} />
      <Route path="login" element={<Login />} />
      <Route path="auth/callback" element={<AuthCallback />} />

      <Route path="data-deletion/" element={<DataDeletion />} />
      <Route path="register" element={<Register />} />
      <Route path="forgot-password" element={<ForgetPassword />} />
      <Route path="communities" element={<MainCommnity />} />
      <Route path="community/:id" element={<CommunityDetail />} />
      <Route path="moments" element={<MainMoments />} />
      <Route path="moment/:id" element={<MomentDetail />} />
      <Route path="add-moment" element={<CreateMoment />} />
      <Route path="edit-moment/:id" element={<EditMyMoment />} />
      <Route path="my-moments" element={<MyMoments />} />
      <Route path="profile" element={<ProfileScreen />} />
      <Route path="profile/edit" element={<EditProfile />} />
      <Route path="followersList" element={<UserFollowersList />} />
      <Route path="followingsList" element={<UserFollowingList />} />
      <Route path="visitors" element={<UserVisitorsList />} />
      <Route path="chat/new" element={<NewChat />} />
      <Route path="chat/:conversationId/settings" element={<ChatSettings />} />
      <Route path="chat/:conversationId/media" element={<MediaGallery />} />
      <Route path="chat/:userId?" element={<MainChatWrapper />} />
      <Route path="courses" element={<CoursesMain />} />
      <Route path="support/" element={<SupportPage />} />
      <Route path="stories/" element={<MainStories />} />
      <Route path="highlights" element={<Highlights />} />
      <Route path="privacy-policy/" element={<PrivacyPolicy />} />
      <Route path="terms-of-use/" element={<TermsOfUse />} />
      <Route path="download" element={<DownloadApp />} />

      {/* Settings */}
      <Route path="settings" element={<Settings />} />
      <Route path="settings/privacy" element={<PrivacySettings />} />
      <Route path="settings/notifications" element={<NotificationSettings />} />
      <Route path="settings/vip" element={<VipSettings />} />
      <Route path="settings/language" element={<LanguageSettings />} />
      <Route path="settings/blocked" element={<BlockedUsers />} />
      <Route path="settings/close-friends" element={<CloseFriends />} />

      {/* Learning */}
      <Route path="learn" element={<LearningDashboard />} />
      <Route path="learn/vocabulary" element={<Vocabulary />} />
      <Route path="learn/review" element={<VocabularyReview />} />
      <Route path="learn/lessons" element={<Lessons />} />
      <Route path="learn/lessons/:lessonId" element={<LessonDetail />} />
      <Route path="learn/quizzes" element={<Quizzes />} />
      <Route path="learn/leaderboard" element={<Leaderboard />} />
      <Route path="learn/achievements" element={<Achievements />} />
      <Route path="learn/challenges" element={<Challenges />} />

      {/* Community */}
      <Route path="community/nearby" element={<NearbyUsers />} />
      <Route path="waves" element={<Waves />} />
      <Route path="topics" element={<Topics />} />

      {/* Moments */}
      <Route path="moments/saved" element={<SavedMoments />} />
    </Route>
  )
);

export default AppRouter;
