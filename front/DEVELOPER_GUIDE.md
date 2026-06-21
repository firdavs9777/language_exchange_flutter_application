# BananaTalk Web Frontend Developer Guide

## Table of Contents
1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Design System](#design-system)
4. [Authentication Screens](#authentication-screens)
5. [Home Screen](#home-screen)
6. [Community Screens](#community-screens)
7. [Chat Screens](#chat-screens)
8. [Moments Screens](#moments-screens)
9. [Stories Screens](#stories-screens)
10. [Profile Screens](#profile-screens)
11. [Learning Screens](#learning-screens)
12. [Settings Screens](#settings-screens)
13. [API Reference](#api-reference)

---

## Project Overview

BananaTalk is a language exchange social platform where users can:
- Connect with native speakers worldwide
- Practice languages through chat
- Share moments (posts) and stories
- Learn vocabulary with SRS (Spaced Repetition System)
- Take lessons and quizzes

**Repository:** `/Users/firdavsmutalipov/Desktop/BananaTalk/front`

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| React 18 | UI Framework |
| TypeScript | Type Safety |
| Redux Toolkit | State Management |
| RTK Query | API Data Fetching |
| React Router v6 | Navigation |
| Socket.IO | Real-time Chat |
| SCSS/CSS | Styling |
| Bootstrap 5 | UI Components |
| i18next | Internationalization |

---

## Design System

### Primary Colors (Teal/Banana Theme)

```scss
// Primary - Teal
$primary: #00BFA5;
$primary-light: #5DF2D6;
$primary-dark: #008E76;

// Secondary - Banana Yellow
$secondary: #FFD54F;
$secondary-light: #FFFF81;
$secondary-dark: #C9A415;

// Accent - Purple
$accent: #7C4DFF;
$accent-light: #B47CFF;
$accent-dark: #3F1DCB;

// Semantic
$success: #4CAF50;
$warning: #FF9800;
$error: #E53935;
$info: #2196F3;

// Gradients
$primary-gradient: linear-gradient(135deg, #00BFA5 0%, #008E76 100%);
$accent-gradient: linear-gradient(135deg, #7C4DFF 0%, #3F1DCB 100%);
```

### Typography

```scss
$font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
$font-size-base: 16px;
$font-size-sm: 14px;
$font-size-lg: 18px;
$font-size-xl: 24px;
$font-size-xxl: 32px;
```

### Spacing

```scss
$spacing-xs: 4px;
$spacing-sm: 8px;
$spacing-md: 16px;
$spacing-lg: 24px;
$spacing-xl: 32px;
$spacing-xxl: 48px;
```

---

## Authentication Screens

### 1. Login Screen (`/login`)

**File:** `src/components/auth/Login.tsx`

**Features:**
- Email/password login
- "Remember me" checkbox
- Forgot password link
- Social login buttons (Google, Apple, Facebook)
- Link to registration

**API Hooks:**
```typescript
import { useLoginUserMutation } from '../../store/slices/usersSlice';
```

**UI Components:**
- Email input with validation
- Password input with show/hide toggle
- Submit button with loading state
- Error message display

**State:**
```typescript
interface LoginState {
  email: string;
  password: string;
  rememberMe: boolean;
  showPassword: boolean;
  error: string | null;
}
```

**Validation:**
- Email: Required, valid email format
- Password: Required, minimum 6 characters

---

### 2. Register Screen (`/register`)

**File:** `src/components/auth/Register.tsx`

**Features:**
- Multi-step registration form
- Email verification with code
- Profile photo upload
- Language selection (native & learning)
- Terms of service agreement

**Steps:**
1. **Basic Info:** Name, email, password
2. **Verification:** Email code verification
3. **Profile:** Photo upload, bio
4. **Languages:** Select native & learning languages

**API Hooks:**
```typescript
import {
  useRegisterUserMutation,
  useRegisterCodeEmailMutation,
  useVerifyCodeEmailMutation
} from '../../store/slices/usersSlice';
```

**UI Components:**
- Step indicator/progress bar
- Form inputs with validation
- Image uploader with preview
- Language selector (multi-select)
- Country selector

**Validation:**
- Name: Required, 2-50 characters
- Email: Required, valid email, unique
- Password: Required, min 8 chars, 1 uppercase, 1 number
- Verification code: 6 digits

---

### 3. Forgot Password Screen (`/forgot-password`)

**File:** `src/components/auth/ForgotPassword.tsx`

**Features:**
- Email input for password reset
- Send verification code
- Success/error feedback

**API Hooks:**
```typescript
import { useSendCodeEmailMutation } from '../../store/slices/usersSlice';
```

---

### 4. Verify Code Screen (`/verify-code`)

**File:** `src/components/auth/VerifyCode.tsx`

**Features:**
- 6-digit code input
- Auto-focus next input
- Resend code option (with cooldown timer)
- Code expiration countdown

**API Hooks:**
```typescript
import { useVerifyCodeEmailMutation } from '../../store/slices/usersSlice';
```

---

### 5. Set New Password Screen (`/reset-password`)

**File:** `src/components/auth/SetNewPassword.tsx`

**Features:**
- New password input
- Confirm password input
- Password strength indicator
- Success redirect to login

**API Hooks:**
```typescript
import { useResetPasswordUserMutation } from '../../store/slices/usersSlice';
```

---

## Home Screen

### Landing Page (`/`)

**File:** `src/components/home/HomeMain.tsx`

**Features (Unauthenticated):**
- Hero section with app description
- Feature highlights
- How it works section
- Pricing/VIP section
- Call-to-action buttons
- Testimonials
- Footer with links

**Features (Authenticated):**
- Redirect to `/community` or `/chat`

**UI Sections:**

```
┌─────────────────────────────────────────┐
│             NAVBAR                      │
├─────────────────────────────────────────┤
│                                         │
│     🍌 BananaTalk                       │
│     Connect with native speakers        │
│     [Get Started] [Learn More]          │
│                                         │
├─────────────────────────────────────────┤
│     FEATURES                            │
│  ┌───────┐ ┌───────┐ ┌───────┐         │
│  │ Chat  │ │ Learn │ │ Share │         │
│  └───────┘ └───────┘ └───────┘         │
├─────────────────────────────────────────┤
│     HOW IT WORKS                        │
│  1. Sign Up → 2. Match → 3. Learn      │
├─────────────────────────────────────────┤
│     PRICING                             │
│  ┌─────────┐ ┌─────────┐               │
│  │  Free   │ │   VIP   │               │
│  └─────────┘ └─────────┘               │
├─────────────────────────────────────────┤
│             FOOTER                      │
└─────────────────────────────────────────┘
```

---

## Community Screens

### 1. Community List (`/community`)

**File:** `src/components/community/MainCommunity.tsx`

**Features:**
- Grid/list of community members
- Filter options (gender, age, country, language)
- Search functionality
- Pagination/infinite scroll
- Online status indicators
- Quick actions (wave, message, follow)

**API Hooks:**
```typescript
import {
  useGetCommunityMembersQuery,
  useGetOnlineUsersQuery,
  useGetNewUsersQuery,
  useSendWaveMutation
} from '../../store/slices/communitySlice';
```

**Filter Options:**
```typescript
interface CommunityFilters {
  gender?: 'male' | 'female' | 'other';
  ageMin?: number;
  ageMax?: number;
  country?: string;
  language?: string;
  onlineOnly?: boolean;
}
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  Community          [Filters] [Search]  │
├─────────────────────────────────────────┤
│  [All] [Online] [New] [Nearby]          │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  User   │ │  User   │ │  User   │   │
│  │  Card   │ │  Card   │ │  Card   │   │
│  │ 🟢 Online│ │ 🔴 Offline│ │ 🟢 Online│   │
│  │ [Wave]  │ │ [Wave]  │ │ [Wave]  │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  User   │ │  User   │ │  User   │   │
│  └─────────┘ └─────────┘ └─────────┘   │
├─────────────────────────────────────────┤
│           [Load More]                   │
└─────────────────────────────────────────┘
```

**User Card Component:**
```typescript
interface UserCardProps {
  user: {
    _id: string;
    name: string;
    photo: string;
    age: number;
    country: string;
    nativeLanguages: string[];
    learningLanguages: string[];
    isOnline: boolean;
    lastActive: Date;
    bio: string;
  };
  onWave: () => void;
  onMessage: () => void;
  onViewProfile: () => void;
}
```

---

### 2. Community User Detail (`/community/:userId`)

**File:** `src/components/community/CommunityDetail.tsx`

**Features:**
- User profile header with photos
- Photo gallery with carousel
- User info (bio, languages, location)
- Action buttons (message, follow, wave, block, report)
- User's moments preview
- Mutual connections

**API Hooks:**
```typescript
import {
  useGetCommunityDetailsQuery,
  useFollowUserMutation,
  useUnFollowUserMutation,
  useBlockUserMutation,
  useReportUserMutation,
  useRecordProfileVisitMutation
} from '../../store/slices/usersSlice';

import { useSendWaveMutation } from '../../store/slices/communitySlice';
import { useCreateChatRoomMutation } from '../../store/slices/chatSlice';
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  [←Back]              [⋮ More Options]  │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  │      Photo Gallery/Carousel     │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│  ○ ○ ● ○ ○ (pagination dots)            │
├─────────────────────────────────────────┤
│  John Doe, 25                🟢 Online  │
│  📍 Seoul, South Korea                  │
│  🗣️ Korean (Native) | Learning: English │
├─────────────────────────────────────────┤
│  [💬 Message] [👋 Wave] [➕ Follow]     │
├─────────────────────────────────────────┤
│  About Me                               │
│  "Hello! I'm looking for..."            │
├─────────────────────────────────────────┤
│  Recent Moments                         │
│  ┌─────┐ ┌─────┐ ┌─────┐               │
│  │     │ │     │ │     │               │
│  └─────┘ └─────┘ └─────┘               │
└─────────────────────────────────────────┘
```

**More Options Menu:**
- Block User
- Report User
- Copy Profile Link
- Share Profile

---

### 3. Nearby Users (`/community/nearby`)

**File:** `src/components/community/NearbyUsers.tsx`

**Features:**
- Location permission request
- Map view with user markers
- List view toggle
- Distance display
- Radius filter

**API Hooks:**
```typescript
import { useGetNearbyUsersQuery } from '../../store/slices/communitySlice';
```

**Required:**
- Browser Geolocation API
- Map library (Leaflet/Google Maps)

---

### 4. Waves Screen (`/waves`)

**File:** `src/components/community/Waves.tsx`

**Features:**
- Received waves list
- Sent waves list
- Wave notifications
- Accept/decline wave
- Quick reply

**API Hooks:**
```typescript
import {
  useGetReceivedWavesQuery,
  useGetSentWavesQuery,
  useRespondToWaveMutation,
  useMarkWaveReadMutation
} from '../../store/slices/communitySlice';
```

**Wave Item:**
```typescript
interface Wave {
  _id: string;
  sender: User;
  receiver: User;
  message?: string;
  status: 'pending' | 'accepted' | 'declined';
  createdAt: Date;
  isRead: boolean;
}
```

---

### 5. Topics Browser (`/topics`)

**File:** `src/components/community/Topics.tsx`

**Features:**
- Browse available topics
- View users by topic
- Update my topics
- Topic categories

**API Hooks:**
```typescript
import {
  useGetTopicsQuery,
  useGetUsersByTopicQuery,
  useUpdateMyTopicsMutation
} from '../../store/slices/communitySlice';
```

---

## Chat Screens

### 1. Conversations List (`/chat`)

**File:** `src/components/chat/MainChat.tsx`

**Features:**
- List of all conversations
- Unread message badges
- Last message preview
- Online status
- Search conversations
- Delete/archive conversation
- Mute notifications

**API Hooks:**
```typescript
import {
  useGetConversationsQuery,
  useGetUnreadCountQuery,
  useDeleteConversationMutation,
  useMuteConversationMutation
} from '../../store/slices/chatSlice';
```

**Socket Events:**
```typescript
// Listen for new messages
socket.on('newMessage', (message) => {});
socket.on('messageRead', (data) => {});
socket.on('userTyping', (data) => {});
socket.on('userOnline', (userId) => {});
socket.on('userOffline', (userId) => {});
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  Messages              [🔍] [New Chat]  │
├─────────────────────────────────────────┤
│  [Search conversations...]              │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ 🖼️ John        🟢    2m ago     │    │
│  │    Hey, how are you?       (2) │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ 🖼️ Sarah       🔴    1h ago     │    │
│  │    Thanks for the help!        │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ 🖼️ Mike        🟢    Just now   │    │
│  │    Typing...                   │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

---

### 2. Chat Room (`/chat/:conversationId`)

**File:** `src/components/chat/ChatContent.tsx`

**Features:**
- Message list with infinite scroll (load older)
- Send text messages
- Send images/files
- Voice messages (record & send)
- Message reactions (emoji)
- Reply to message
- Edit/delete message
- Language correction feature
- Translation feature
- Typing indicator
- Read receipts
- Online status

**API Hooks:**
```typescript
import {
  useGetConversationQuery,
  useCreateMessageMutation,
  useEditMessageMutation,
  useDeleteMessageMutation,
  useAddReactionMutation,
  useSendVoiceMessageMutation,
  useSendMediaMessageMutation,
  useTranslateMessageMutation,
  useMarkMessageReadMutation
} from '../../store/slices/chatSlice';

import { useSendCorrectionMutation } from '../../store/slices/learningSlice';
```

**Socket Events:**
```typescript
// Emit
socket.emit('joinRoom', conversationId);
socket.emit('sendMessage', messageData);
socket.emit('typing', { conversationId, isTyping: true });
socket.emit('markRead', { conversationId, messageId });

// Listen
socket.on('message', (message) => {});
socket.on('messageUpdated', (message) => {});
socket.on('messageDeleted', (messageId) => {});
socket.on('typing', (data) => {});
socket.on('reaction', (data) => {});
```

**Message Component:**
```typescript
interface Message {
  _id: string;
  sender: string;
  receiver: string;
  content: string;
  type: 'text' | 'image' | 'voice' | 'video' | 'file';
  mediaUrl?: string;
  duration?: number; // for voice
  replyTo?: Message;
  reactions: Array<{ userId: string; emoji: string }>;
  corrections?: Array<Correction>;
  translation?: string;
  isRead: boolean;
  readAt?: Date;
  isEdited: boolean;
  createdAt: Date;
  updatedAt: Date;
}
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  [←] John Doe              🟢 Online    │
├─────────────────────────────────────────┤
│                                         │
│       ┌──────────────────┐              │
│       │ Hello! 👋        │  10:30 AM    │
│       └──────────────────┘              │
│                                         │
│  ┌──────────────────┐                   │
│  │ Hi! How are you? │  10:31 AM  ✓✓     │
│  └──────────────────┘                   │
│                                         │
│       ┌──────────────────┐              │
│       │ 🎤 Voice (0:15)  │  10:32 AM    │
│       └──────────────────┘              │
│                                         │
│       John is typing...                 │
├─────────────────────────────────────────┤
│  [📎] [📷] [🎤] [____________] [Send]   │
└─────────────────────────────────────────┘
```

**Context Menu (Long Press/Right Click on Message):**
- Reply
- React (emoji picker)
- Copy
- Edit (own messages only)
- Delete (own messages only)
- Translate
- Correct (language correction)
- Report

---

### 3. New Chat (`/chat/new`)

**File:** `src/components/chat/NewChat.tsx`

**Features:**
- Search users
- Recent contacts
- Following list
- Create conversation

**API Hooks:**
```typescript
import { useSearchUsersQuery } from '../../store/slices/usersSlice';
import { useCreateChatRoomMutation } from '../../store/slices/chatSlice';
```

---

## Moments Screens

### 1. Moments Feed (`/moments`)

**File:** `src/components/moments/MainMoments.tsx`

**Features:**
- Infinite scroll feed
- Tabs: For You, Following, Trending, Explore
- Pull to refresh
- Quick actions (like, comment, save, share)

**API Hooks:**
```typescript
import {
  useGetMomentsQuery,
  useGetTrendingMomentsQuery,
  useGetExploreMomentsQuery,
  useLikeMomentMutation,
  useDislikeMomentMutation,
  useSaveMomentMutation
} from '../../store/slices/momentsSlice';
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  Moments                    [+ Create]  │
├─────────────────────────────────────────┤
│  [For You] [Following] [Trending]       │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ 🖼️ User Name            2h ago  │    │
│  ├─────────────────────────────────┤    │
│  │                                 │    │
│  │        [Image/Content]          │    │
│  │                                 │    │
│  ├─────────────────────────────────┤    │
│  │ ❤️ 123  💬 45  🔖 12  ↗️ Share  │    │
│  │ Caption text here...            │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 🖼️ Another User         5h ago  │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

---

### 2. Moment Detail (`/moments/:momentId`)

**File:** `src/components/moments/MomentDetail.tsx`

**Features:**
- Full moment view
- Image gallery
- Comments section
- Like/save/share actions
- User profile link
- Related moments

**API Hooks:**
```typescript
import {
  useGetMomentDetailsQuery,
  useGetMomentCommentsQuery,
  useAddMomentCommentMutation,
  useDeleteMomentCommentMutation,
  useLikeMomentMutation,
  useSaveMomentMutation,
  useTranslateMomentMutation,
  useReportMomentMutation
} from '../../store/slices/momentsSlice';
```

**Comment Component:**
```typescript
interface Comment {
  _id: string;
  user: User;
  content: string;
  parentId?: string; // for replies
  likes: number;
  createdAt: Date;
}
```

---

### 3. Create Moment (`/moments/create`)

**File:** `src/components/moments/CreateMoment.tsx`

**Features:**
- Photo upload (multiple)
- Caption input with character limit
- Location tagging
- Language selection
- Category/topic selection
- Preview before posting

**API Hooks:**
```typescript
import {
  useCreateMomentMutation,
  useUploadMomentPhotosMutation
} from '../../store/slices/momentsSlice';
```

**Form Data:**
```typescript
interface CreateMomentForm {
  caption: string;
  images: File[];
  location?: string;
  language?: string;
  category?: string;
}
```

---

### 4. Edit Moment (`/moments/:momentId/edit`)

**File:** `src/components/profile/EditMyMoment.tsx`

**Features:**
- Edit caption
- Remove/add photos
- Update location
- Update category

**API Hooks:**
```typescript
import { useUpdateMomentMutation } from '../../store/slices/momentsSlice';
```

---

### 5. Saved Moments (`/moments/saved`)

**File:** `src/components/moments/SavedMoments.tsx`

**Features:**
- Grid of saved moments
- Remove from saved
- Organize by collection (future)

**API Hooks:**
```typescript
import {
  useGetSavedMomentsQuery,
  useUnsaveMomentMutation
} from '../../store/slices/momentsSlice';
```

---

## Stories Screens

### 1. Stories Feed (`/stories`)

**File:** `src/components/stories/MainStories.tsx`

**Features:**
- Horizontal scroll of story circles
- Create story button
- My stories first
- Unviewed stories highlighted
- Story ring colors (normal, close friends)

**API Hooks:**
```typescript
import {
  useGetStoryFeedsQuery,
  useGetMyStoriesQuery
} from '../../store/slices/storiesSlice';
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  Stories                                │
├─────────────────────────────────────────┤
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐  │
│  │ + │ │🔵│ │🔵│ │⚪│ │🟢│ │🔵│  │
│  │You│ │   │ │   │ │   │ │   │ │   │  │
│  └───┘ └───┘ └───┘ └───┘ └───┘ └───┘  │
│   Add   User  User  User  User  User   │
└─────────────────────────────────────────┘
🔵 = Unviewed  ⚪ = Viewed  🟢 = Close Friend
```

---

### 2. Story Viewer (`/stories/:userId`)

**File:** `src/components/stories/StoryViewer.tsx`

**Features:**
- Full-screen story view
- Auto-progress timer bar
- Tap to next/previous
- Pause on hold
- React with emoji
- Reply to story
- View count (own stories)
- Poll voting
- Question answering

**API Hooks:**
```typescript
import {
  useGetUserStoriesQuery,
  useGetIndividualStoryQuery,
  useMarkIndividualStoryViewedMutation,
  useReactToStoryMutation,
  useReplyToStoryMutation,
  useVoteOnPollMutation,
  useAnswerQuestionMutation,
  useGetStoryViewersQuery
} from '../../store/slices/storiesSlice';
```

**Story Types:**
```typescript
type StoryType = 'image' | 'video' | 'text' | 'poll' | 'question';

interface Story {
  _id: string;
  user: User;
  type: StoryType;
  mediaUrl?: string;
  text?: string;
  backgroundColor?: string;
  poll?: {
    question: string;
    options: Array<{ text: string; votes: number }>;
    userVote?: number;
  };
  question?: {
    text: string;
    responses: Array<{ user: User; answer: string }>;
  };
  viewCount: number;
  reactions: Array<{ userId: string; emoji: string }>;
  expiresAt: Date;
  createdAt: Date;
}
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  ████████░░░░░░░░░░░░  (progress bar)   │
├─────────────────────────────────────────┤
│  🖼️ User Name              [X Close]    │
│                                         │
│                                         │
│                                         │
│           [Story Content]               │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  [Send a message...] [❤️] [😂] [😮]     │
└─────────────────────────────────────────┘
```

---

### 3. Create Story (`/stories/create`)

**File:** `src/components/stories/CreateStory.tsx`

**Features:**
- Photo upload
- Video upload (with trimming)
- Text story with backgrounds
- Add stickers/text overlay
- Create poll
- Ask question
- Close friends only option

**API Hooks:**
```typescript
import {
  useCreateStoryMutation,
  useCreateVideoStoryMutation
} from '../../store/slices/storiesSlice';
```

**Story Creation Options:**
```typescript
interface CreateStoryForm {
  type: 'image' | 'video' | 'text' | 'poll' | 'question';
  media?: File;
  text?: string;
  backgroundColor?: string;
  poll?: {
    question: string;
    options: string[];
  };
  question?: string;
  closeFriendsOnly: boolean;
}
```

---

### 4. My Stories (`/stories/my`)

**File:** `src/components/stories/MyStories.tsx`

**Features:**
- List of my active stories
- View count per story
- Delete story option
- Viewers list

**API Hooks:**
```typescript
import {
  useGetMyStoriesQuery,
  useDeleteIndividualStoryMutation,
  useGetStoryViewersQuery
} from '../../store/slices/storiesSlice';
```

---

### 5. Highlights (`/profile/highlights`)

**File:** `src/components/stories/Highlights.tsx`

**Features:**
- Create highlight collection
- Add stories to highlight
- Edit highlight cover/title
- Delete highlight

**API Hooks:**
```typescript
import {
  useGetHighlightsQuery,
  useCreateHighlightMutation,
  useDeleteHighlightMutation
} from '../../store/slices/storiesSlice';
```

---

### 6. Close Friends (`/settings/close-friends`)

**File:** `src/components/stories/CloseFriends.tsx`

**Features:**
- Manage close friends list
- Add/remove users
- Search following

**API Hooks:**
```typescript
import {
  useGetCloseFriendsQuery,
  useAddCloseFriendMutation,
  useRemoveCloseFriendMutation
} from '../../store/slices/storiesSlice';
```

---

## Profile Screens

### 1. My Profile (`/profile`)

**File:** `src/components/profile/Profile.tsx`

**Features:**
- Profile header with stats
- Photo gallery
- Edit profile button
- Settings access
- My moments grid
- Highlights
- Followers/following count

**API Hooks:**
```typescript
import {
  useGetUserProfileQuery,
  useGetFollowersQuery,
  useGetFollowingsQuery,
  useGetMyVisitorStatsQuery
} from '../../store/slices/usersSlice';

import { useGetMyMomentsQuery } from '../../store/slices/momentsSlice';
import { useGetHighlightsQuery } from '../../store/slices/storiesSlice';
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  Profile                    [⚙️ Settings]│
├─────────────────────────────────────────┤
│        ┌─────────────┐                  │
│        │             │                  │
│        │   Photo     │                  │
│        │             │                  │
│        └─────────────┘                  │
│           John Doe                      │
│           📍 Seoul, Korea               │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │   123   │ │   456   │ │   78    │   │
│  │Followers│ │Following│ │ Moments │   │
│  └─────────┘ └─────────┘ └─────────┘   │
├─────────────────────────────────────────┤
│  [Edit Profile]                         │
├─────────────────────────────────────────┤
│  Languages                              │
│  🗣️ Korean (Native) • Learning: English │
├─────────────────────────────────────────┤
│  Bio                                    │
│  "Hello! I love languages..."           │
├─────────────────────────────────────────┤
│  Highlights                             │
│  ○ ○ ○ ○ +                              │
├─────────────────────────────────────────┤
│  Moments            [Grid] [List]       │
│  ┌───┐ ┌───┐ ┌───┐                     │
│  │   │ │   │ │   │                     │
│  └───┘ └───┘ └───┘                     │
└─────────────────────────────────────────┘
```

---

### 2. Edit Profile (`/profile/edit`)

**File:** `src/components/profile/EditProfile.tsx`

**Features:**
- Update name
- Update bio
- Update photos (reorder, add, delete)
- Update location
- Update languages
- Update birthday
- Update gender

**API Hooks:**
```typescript
import {
  useUpdateUserInfoMutation,
  useUploadUserPhotoMutation,
  useDeleteUserPhotoMutation
} from '../../store/slices/usersSlice';
```

---

### 3. Followers List (`/profile/followers`)

**File:** `src/components/profile/UserFollowers.tsx`

**Features:**
- List of followers
- Follow back button
- Remove follower option
- Search followers

**API Hooks:**
```typescript
import {
  useGetFollowersQuery,
  useFollowUserMutation
} from '../../store/slices/usersSlice';
```

---

### 4. Following List (`/profile/following`)

**File:** `src/components/profile/UserFollowing.tsx`

**Features:**
- List of following
- Unfollow button
- Search following

**API Hooks:**
```typescript
import {
  useGetFollowingsQuery,
  useUnFollowUserMutation
} from '../../store/slices/usersSlice';
```

---

### 5. Profile Visitors (`/profile/visitors`)

**File:** `src/components/profile/UserVisitors.tsx`

**Features:**
- List of profile visitors
- Time of visit
- Clear visitors button
- VIP feature indicator

**API Hooks:**
```typescript
import {
  useGetProfileVisitorsQuery,
  useClearVisitorsMutation
} from '../../store/slices/usersSlice';
```

---

### 6. My Moments (`/profile/moments`)

**File:** `src/components/profile/MyMoments.tsx`

**Features:**
- Grid of user's moments
- Edit/delete options
- Draft moments (future)

**API Hooks:**
```typescript
import {
  useGetMyMomentsQuery,
  useDeleteMomentMutation
} from '../../store/slices/momentsSlice';
```

---

### 7. Blocked Users (`/settings/blocked`)

**File:** `src/components/profile/BlockedUsers.tsx`

**Features:**
- List of blocked users
- Unblock option

**API Hooks:**
```typescript
import {
  useGetBlockedUsersQuery,
  useUnblockUserMutation
} from '../../store/slices/usersSlice';
```

---

## Learning Screens

### 1. Learning Dashboard (`/learn`)

**File:** `src/components/learning/LearningDashboard.tsx`

**Features:**
- Daily progress
- Streak counter
- XP display
- Quick actions (review, lessons, quizzes)
- Recommended lessons
- Achievements preview

**API Hooks:**
```typescript
import {
  useGetLearningProgressQuery,
  useGetDailyGoalsQuery,
  useGetRecommendedLessonsQuery,
  useGetAchievementsQuery
} from '../../store/slices/learningSlice';
```

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  Learn                         [🏆 XP]  │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ 🔥 5 Day Streak!               │    │
│  │ ████████████░░░░ 80% Daily Goal│    │
│  └─────────────────────────────────┘    │
├─────────────────────────────────────────┤
│  Quick Actions                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ 📚      │ │ 📝      │ │ 🎯      │   │
│  │ Review  │ │ Lessons │ │ Quiz    │   │
│  │ (15 due)│ │         │ │         │   │
│  └─────────┘ └─────────┘ └─────────┘   │
├─────────────────────────────────────────┤
│  Recommended Lessons                    │
│  ┌─────────────────────────────────┐    │
│  │ Basic Greetings - Korean       │    │
│  └─────────────────────────────────┘    │
├─────────────────────────────────────────┤
│  Recent Achievements                    │
│  🏅 🏅 🏅                               │
└─────────────────────────────────────────┘
```

---

### 2. Vocabulary List (`/learn/vocabulary`)

**File:** `src/components/learning/Vocabulary.tsx`

**Features:**
- Word list with SRS levels
- Add new word
- Edit/delete words
- Filter by language/level
- Search words
- Import from conversation

**API Hooks:**
```typescript
import {
  useGetVocabularyQuery,
  useAddVocabularyMutation,
  useUpdateVocabularyMutation,
  useDeleteVocabularyMutation
} from '../../store/slices/learningSlice';
```

**Vocabulary Item:**
```typescript
interface VocabularyItem {
  _id: string;
  word: string;
  translation: string;
  language: string;
  pronunciation?: string;
  partOfSpeech?: string;
  exampleSentence?: string;
  exampleTranslation?: string;
  tags: string[];
  notes?: string;
  srsLevel: number; // 0-5 (Apprentice to Mastered)
  nextReviewDate: Date;
  correctCount: number;
  incorrectCount: number;
}
```

---

### 3. Vocabulary Review (`/learn/review`)

**File:** `src/components/learning/VocabularyReview.tsx`

**Features:**
- Flashcard-style review
- Show/hide answer
- Self-grade (correct/incorrect)
- Progress indicator
- Session stats

**API Hooks:**
```typescript
import {
  useGetDueReviewsQuery,
  useSubmitReviewMutation
} from '../../store/slices/learningSlice';
```

**UI Flow:**
```
┌─────────────────────────────────────────┐
│  Review           [15/20]    [X Close]  │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│              안녕하세요                  │
│                                         │
│        (Tap to reveal answer)           │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│        [Show Answer]                    │
└─────────────────────────────────────────┘

After reveal:

┌─────────────────────────────────────────┐
│  Review           [15/20]    [X Close]  │
├─────────────────────────────────────────┤
│                                         │
│              안녕하세요                  │
│              ─────────                  │
│              Hello                      │
│                                         │
│       "An-nyeong-ha-se-yo"              │
│                                         │
├─────────────────────────────────────────┤
│     [❌ Wrong]        [✅ Correct]       │
└─────────────────────────────────────────┘
```

---

### 4. Lessons List (`/learn/lessons`)

**File:** `src/components/learning/Lessons.tsx`

**Features:**
- Lesson categories
- Lesson progress
- Difficulty levels
- Language filter

**API Hooks:**
```typescript
import {
  useGetLessonsQuery,
  useGetRecommendedLessonsQuery
} from '../../store/slices/learningSlice';
```

---

### 5. Lesson Detail (`/learn/lessons/:lessonId`)

**File:** `src/components/learning/LessonDetail.tsx`

**Features:**
- Lesson content
- Interactive exercises
- Multiple choice questions
- Fill in the blank
- Matching exercises
- Progress tracking
- XP rewards

**API Hooks:**
```typescript
import {
  useGetLessonQuery,
  useStartLessonMutation,
  useSubmitLessonMutation
} from '../../store/slices/learningSlice';
```

---

### 6. Quizzes (`/learn/quizzes`)

**File:** `src/components/learning/Quizzes.tsx`

**Features:**
- Available quizzes
- Quiz history
- Timed quizzes
- Quiz categories

**API Hooks:**
```typescript
import {
  useGetQuizzesQuery,
  useGetQuizQuery,
  useSubmitQuizMutation
} from '../../store/slices/learningSlice';
```

---

### 7. Leaderboard (`/learn/leaderboard`)

**File:** `src/components/learning/Leaderboard.tsx`

**Features:**
- Weekly/monthly/all-time tabs
- User rankings
- XP display
- Language filter
- Current user highlight

**API Hooks:**
```typescript
import { useGetLeaderboardQuery } from '../../store/slices/learningSlice';
```

---

### 8. Achievements (`/learn/achievements`)

**File:** `src/components/learning/Achievements.tsx`

**Features:**
- Achievement categories
- Earned vs locked
- Progress indicators
- Share achievements

**API Hooks:**
```typescript
import { useGetAchievementsQuery } from '../../store/slices/learningSlice';
```

---

### 9. Challenges (`/learn/challenges`)

**File:** `src/components/learning/Challenges.tsx`

**Features:**
- Active challenges
- Join challenge
- Challenge progress
- Leaderboard per challenge

**API Hooks:**
```typescript
import {
  useGetChallengesQuery,
  useJoinChallengeMutation
} from '../../store/slices/learningSlice';
```

---

## Settings Screens

### 1. Settings Main (`/settings`)

**File:** `src/components/settings/Settings.tsx`

**Features:**
- Account settings link
- Privacy settings link
- Notification settings link
- Language & region
- Help & support
- About
- Logout

**Sections:**
```
┌─────────────────────────────────────────┐
│  Settings                               │
├─────────────────────────────────────────┤
│  Account                                │
│  ├─ Edit Profile                    >   │
│  ├─ Change Password                 >   │
│  └─ Email Settings                  >   │
├─────────────────────────────────────────┤
│  Privacy                                │
│  ├─ Profile Visibility              >   │
│  ├─ Blocked Users                   >   │
│  └─ Close Friends                   >   │
├─────────────────────────────────────────┤
│  Notifications                          │
│  ├─ Push Notifications              >   │
│  └─ Email Notifications             >   │
├─────────────────────────────────────────┤
│  VIP                                    │
│  └─ Manage Subscription             >   │
├─────────────────────────────────────────┤
│  Support                                │
│  ├─ Help Center                     >   │
│  ├─ Contact Us                      >   │
│  └─ Report a Problem                >   │
├─────────────────────────────────────────┤
│  [Logout]                               │
└─────────────────────────────────────────┘
```

---

### 2. VIP/Subscription (`/settings/vip`)

**File:** `src/components/settings/VipSettings.tsx`

**Features:**
- Current plan display
- Plan comparison
- Upgrade options
- Payment method
- Billing history
- Cancel subscription

**API Hooks:**
```typescript
import { useGetVipStatusQuery } from '../../store/slices/usersSlice';
```

**VIP Features Display:**
```typescript
interface VipFeatures {
  unlimitedMessages: boolean;
  seeProfileVisitors: boolean;
  advancedFilters: boolean;
  noAds: boolean;
  prioritySupport: boolean;
  exclusiveBadge: boolean;
}
```

---

### 3. Privacy Settings (`/settings/privacy`)

**File:** `src/components/settings/PrivacySettings.tsx`

**Features:**
- Profile visibility options
- Online status visibility
- Last seen visibility
- Read receipts toggle
- Who can message me

---

### 4. Notification Settings (`/settings/notifications`)

**File:** `src/components/settings/NotificationSettings.tsx`

**Features:**
- Message notifications toggle
- Like/comment notifications
- Follower notifications
- Wave notifications
- Email digest settings

---

### 5. Language Settings (`/settings/language`)

**File:** `src/components/settings/LanguageSettings.tsx`

**Features:**
- App language selection
- Update native languages
- Update learning languages

**API Hooks:**
```typescript
import {
  useGetLanguagesQuery,
  useUpdateMyLanguagesMutation
} from '../../store/slices/communitySlice';
```

---

## API Reference

### Base Configuration

**File:** `src/store/slices/apiSlice.ts`

```typescript
// Base URL Configuration
const BASE_URL = process.env.NODE_ENV === "development"
  ? "https://api.banatalk.com"
  : ""; // Production uses proxy

// Auto token refresh on 401
// Credentials included for cookies
```

### Available API Slices

| Slice | File | Description |
|-------|------|-------------|
| `usersApiSlice` | `usersSlice.ts` | User auth, profile, follow system |
| `momentsApiSlice` | `momentsSlice.ts` | Posts CRUD, likes, comments |
| `storiesApiSlice` | `storiesSlice.ts` | Stories, highlights, reactions |
| `communityApiSlice` | `communitySlice.ts` | Discovery, waves, topics |
| `chatApiSlice` | `chatSlice.ts` | Messages, conversations |
| `learningApiSlice` | `learningSlice.ts` | Vocabulary, lessons, quizzes |

### Socket.IO Events Reference

**Connection:**
```typescript
const socket = io(SOCKET_URL, {
  auth: { token: userToken },
  transports: ['websocket']
});
```

**Events to Emit:**
```typescript
// Chat
socket.emit('joinRoom', conversationId);
socket.emit('leaveRoom', conversationId);
socket.emit('sendMessage', { conversationId, content, type });
socket.emit('typing', { conversationId, isTyping });
socket.emit('markRead', { conversationId, messageId });

// Presence
socket.emit('online');
socket.emit('offline');
```

**Events to Listen:**
```typescript
// Chat
socket.on('message', (message) => {});
socket.on('messageUpdated', (message) => {});
socket.on('messageDeleted', (messageId) => {});
socket.on('typing', ({ conversationId, userId, isTyping }) => {});
socket.on('messagesRead', ({ conversationId, readBy }) => {});

// Presence
socket.on('userOnline', (userId) => {});
socket.on('userOffline', (userId) => {});

// Notifications
socket.on('notification', (notification) => {});
socket.on('newFollower', (user) => {});
socket.on('newWave', (wave) => {});
```

---

## File Structure

```
src/
├── components/
│   ├── auth/
│   │   ├── Login.tsx
│   │   ├── Login.scss
│   │   ├── Register.tsx
│   │   ├── Register.scss
│   │   ├── ForgotPassword.tsx
│   │   ├── VerifyCode.tsx
│   │   └── SetNewPassword.tsx
│   ├── home/
│   │   ├── HomeMain.tsx
│   │   └── HomeMain.scss
│   ├── community/
│   │   ├── MainCommunity.tsx
│   │   ├── CommunityDetail.tsx
│   │   ├── CommunityDetail.css
│   │   ├── NearbyUsers.tsx
│   │   ├── Waves.tsx
│   │   └── Topics.tsx
│   ├── chat/
│   │   ├── MainChat.tsx
│   │   ├── Chat.css
│   │   ├── ChatContent.tsx
│   │   ├── ChatContent.css
│   │   ├── MessageList.tsx
│   │   ├── MessageList.css
│   │   ├── UsersList.tsx
│   │   └── NewChat.tsx
│   ├── moments/
│   │   ├── MainMoments.tsx
│   │   ├── MomentDetail.tsx
│   │   ├── SingleMoment.tsx
│   │   ├── CreateMoment.tsx
│   │   └── SavedMoments.tsx
│   ├── stories/
│   │   ├── MainStories.tsx
│   │   ├── MainStories.scss
│   │   ├── StoryViewer.tsx
│   │   ├── StoryViewer.scss
│   │   ├── CreateStory.tsx
│   │   ├── CreateStory.scss
│   │   ├── MyStories.tsx
│   │   ├── Highlights.tsx
│   │   └── CloseFriends.tsx
│   ├── profile/
│   │   ├── Profile.tsx
│   │   ├── Profile.scss
│   │   ├── EditProfile.tsx
│   │   ├── UserFollowers.tsx
│   │   ├── UserFollowing.tsx
│   │   ├── UserVisitors.tsx
│   │   ├── MyMoments.tsx
│   │   ├── EditMyMoment.tsx
│   │   └── BlockedUsers.tsx
│   ├── learning/
│   │   ├── LearningDashboard.tsx
│   │   ├── Vocabulary.tsx
│   │   ├── VocabularyReview.tsx
│   │   ├── Lessons.tsx
│   │   ├── LessonDetail.tsx
│   │   ├── Quizzes.tsx
│   │   ├── Leaderboard.tsx
│   │   ├── Achievements.tsx
│   │   └── Challenges.tsx
│   ├── settings/
│   │   ├── Settings.tsx
│   │   ├── VipSettings.tsx
│   │   ├── PrivacySettings.tsx
│   │   ├── NotificationSettings.tsx
│   │   └── LanguageSettings.tsx
│   ├── navbar/
│   │   ├── MainNavbar.tsx
│   │   └── MainNavbar.scss
│   └── footer/
│       ├── FooterMain.tsx
│       └── FooterMain.scss
├── store/
│   ├── index.ts
│   └── slices/
│       ├── apiSlice.ts
│       ├── authSlice.ts
│       ├── usersSlice.ts
│       ├── momentsSlice.ts
│       ├── storiesSlice.ts
│       ├── communitySlice.ts
│       ├── chatSlice.ts
│       └── learningSlice.ts
├── router/
│   └── AppRouter.tsx
├── utils/
│   ├── locales/
│   │   ├── eng.json
│   │   └── kor.json
│   └── helpers.ts
├── constants.ts
└── App.tsx
```

---

## Routes Configuration

**File:** `src/router/AppRouter.tsx`

```typescript
const routes = [
  // Public
  { path: '/', element: <HomeMain /> },
  { path: '/login', element: <Login /> },
  { path: '/register', element: <Register /> },
  { path: '/forgot-password', element: <ForgotPassword /> },
  { path: '/verify-code', element: <VerifyCode /> },
  { path: '/reset-password', element: <SetNewPassword /> },
  { path: '/privacy-policy', element: <PrivacyPolicy /> },
  { path: '/terms', element: <TermsOfUse /> },

  // Protected (require auth)
  { path: '/community', element: <MainCommunity /> },
  { path: '/community/:userId', element: <CommunityDetail /> },
  { path: '/community/nearby', element: <NearbyUsers /> },
  { path: '/waves', element: <Waves /> },
  { path: '/topics', element: <Topics /> },

  { path: '/chat', element: <MainChat /> },
  { path: '/chat/new', element: <NewChat /> },
  { path: '/chat/:conversationId', element: <ChatContent /> },

  { path: '/moments', element: <MainMoments /> },
  { path: '/moments/create', element: <CreateMoment /> },
  { path: '/moments/saved', element: <SavedMoments /> },
  { path: '/moments/:momentId', element: <MomentDetail /> },
  { path: '/moments/:momentId/edit', element: <EditMyMoment /> },

  { path: '/stories', element: <MainStories /> },
  { path: '/stories/create', element: <CreateStory /> },
  { path: '/stories/my', element: <MyStories /> },
  { path: '/stories/:userId', element: <StoryViewer /> },

  { path: '/profile', element: <Profile /> },
  { path: '/profile/edit', element: <EditProfile /> },
  { path: '/profile/followers', element: <UserFollowers /> },
  { path: '/profile/following', element: <UserFollowing /> },
  { path: '/profile/visitors', element: <UserVisitors /> },
  { path: '/profile/moments', element: <MyMoments /> },
  { path: '/profile/highlights', element: <Highlights /> },

  { path: '/learn', element: <LearningDashboard /> },
  { path: '/learn/vocabulary', element: <Vocabulary /> },
  { path: '/learn/review', element: <VocabularyReview /> },
  { path: '/learn/lessons', element: <Lessons /> },
  { path: '/learn/lessons/:lessonId', element: <LessonDetail /> },
  { path: '/learn/quizzes', element: <Quizzes /> },
  { path: '/learn/leaderboard', element: <Leaderboard /> },
  { path: '/learn/achievements', element: <Achievements /> },
  { path: '/learn/challenges', element: <Challenges /> },

  { path: '/settings', element: <Settings /> },
  { path: '/settings/vip', element: <VipSettings /> },
  { path: '/settings/privacy', element: <PrivacySettings /> },
  { path: '/settings/notifications', element: <NotificationSettings /> },
  { path: '/settings/language', element: <LanguageSettings /> },
  { path: '/settings/blocked', element: <BlockedUsers /> },
  { path: '/settings/close-friends', element: <CloseFriends /> },
];
```

---

## Development Commands

```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build

# Run tests
npm test

# Lint code
npm run lint
```

---

## Environment Variables

Create `.env` file:

```env
REACT_APP_API_URL=https://api.banatalk.com
REACT_APP_SOCKET_URL=wss://api.banatalk.com
REACT_APP_GOOGLE_CLIENT_ID=your_google_client_id
REACT_APP_FACEBOOK_APP_ID=your_facebook_app_id
```

---

## Contributing

1. Create feature branch from `main`
2. Follow existing code style
3. Write tests for new features
4. Submit PR with clear description

---

## Contact

- **Repository:** BananaTalk Frontend
- **API Docs:** Contact backend team
- **Design:** Figma link (if available)
