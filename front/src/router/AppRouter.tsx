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
import PublicProfile from "../components/profile/PublicProfile";
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
import CreateStory from "../components/stories/CreateStory";
import StoryViewer from "../components/stories/StoryViewer";

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
      {/* Public, read-only profile route for shared links. Must stay public
          (no auth guard) so logged-out visitors can view it; react-router v6
          ranks the static "profile/edit" segment above this dynamic
          "profile/:userId" segment regardless of declaration order, so
          there's no conflict between the two. */}
      <Route path="profile/:userId" element={<PublicProfile />} />
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
      <Route path="create-story" element={<CreateStory />} />
      <Route path="stories/:userId" element={<StoryViewer />} />
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
