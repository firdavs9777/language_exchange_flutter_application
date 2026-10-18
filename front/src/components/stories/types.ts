// Story Types
export interface User {
  _id: string;
  name: string;
  images?: string[];
  imageUrls?: string[];
  bio?: string;
  gender?: string;
  city?: string;
  country?: string;
  isVIP?: boolean;
  nativeLanguage?: string;
  native_language?: string;
}

export interface StoryView {
  user: User;
  viewedAt: string;
  viewDuration?: number;
}

export interface StoryReaction {
  /** A bare id string on the story routes; populated only where a route
   * populates it. */
  user: User | string;
  emoji: string;
  reactedAt: string;
}

export interface StoryReply {
  user: User;
  message: {
    _id: string;
    sender: User;
    message: string;
    createdAt: string;
  };
  repliedAt: string;
}

/**
 * A text or emoji sticker, stored as structure rather than baked into the
 * picture. `x`/`y` are 0-1 fractions of the canvas and mark the sticker's
 * CENTRE; `scale` is 0.5-3.0. See `storyOverlays.ts` for the full contract and
 * `parseOverlays()` in the backend for what it will and will not accept.
 */
export interface StoryOverlay {
  type: 'text' | 'emoji';
  content: string;
  x: number;
  y: number;
  scale: number;
  /** Degrees. The app's studio writes it; the web composer never rotates. */
  rotation?: number;
  color: string;
  fontStyle: 'sans-serif' | 'serif' | 'bold' | 'handwritten';
  bgMode: 'none' | 'semi' | 'solid';
}

export interface Mention {
  /** Populated on the story routes, but a bare ObjectId string on anything
   * that skips the populate. */
  user: User | string;
  username: string;
  /** 0-100, NOT the overlays' 0-1: `parseMentions()` really does use a
   * different scale from `parseOverlays()`. */
  position: { x: number; y: number };
}

export interface StoryLocation {
  name: string;
  address: string;
  coordinates: {
    type: 'Point';
    coordinates: [number, number];
  };
  placeId?: string;
}

export interface StoryLink {
  url: string;
  title: string;
  displayText: string;
  /** Added by the server so the viewer can show where a tap really goes; a
   * sticker reading "Shop Now" that opens an unrelated domain is the trick
   * `lib/storyLink.js` exists to defuse. */
  host?: string;
}

export interface PollOption {
  text: string;
  /** Every voter for the owner; for anyone else only their own id, or absent. */
  votes?: string[];
  voteCount?: number;
  index?: number;
  percentage?: number;
  voted?: boolean;
}

export interface StoryPoll {
  question: string;
  options: PollOption[];
  isAnonymous: boolean;
  expiresAt?: string;
  /** The viewer's own vote (null: not voted). Absent on older backends. */
  userVoteIndex?: number | null;
  totalVotes?: number;
}

export interface QuestionResponse {
  user: User | null;
  text: string;
  respondedAt: string;
  isAnonymous: boolean;
}

export interface StoryQuestionBox {
  prompt: string;
  /** Owner only; others get their own responses at most, or nothing. */
  responses?: QuestionResponse[];
  /** Whether the viewer answered. Absent on older backends. */
  hasAnswered?: boolean;
  responseCount?: number;
}

export interface StoryMusic {
  trackId: string;
  title: string;
  artist: string;
  coverUrl: string;
  previewUrl: string;
  startTime: number;
  duration: number;
}

export interface StoryHighlight {
  _id: string;
  title: string;
  coverImage: string;
  storyCount: number;
  stories: Story[];
  createdAt: string;
}

export interface StoryShare {
  user: User;
  sharedTo: 'dm' | 'story' | 'external';
  sharedAt: string;
}

export interface Story {
  _id: string;
  user: User;
  
  // Media
  mediaUrl?: string;
  mediaUrls: string[];
  mediaType: 'image' | 'video' | 'text';
  
  // Text story
  text?: string;
  backgroundColor?: string;
  textColor?: string;
  fontStyle?: 'normal' | 'bold' | 'italic' | 'handwriting';
  
  // Privacy
  privacy: 'public' | 'friends' | 'close_friends';
  
  // Views (owner only on current backends)
  views?: StoryView[];
  viewCount: number;
  
  // Reactions. For anyone but the owner, `reactions` may hold only the
  // viewer's own entry; `myReaction` is that entry's emoji (or null) on
  // backends that send it.
  reactions: StoryReaction[];
  reactionCount: number;
  myReaction?: string | null;
  
  // Replies
  replies: StoryReply[];
  replyCount: number;
  
  // Mentions
  mentions?: Mention[];

  // Text / emoji stickers, positioned but never baked in
  overlays?: StoryOverlay[];
  
  // Location
  location?: StoryLocation;
  
  // Link
  link?: StoryLink;
  
  // Poll
  poll?: StoryPoll;
  
  // Question box
  questionBox?: StoryQuestionBox;
  
  // Music
  music?: StoryMusic;
  
  // Hashtags
  hashtags?: string[];
  
  // Highlight reference
  highlight?: StoryHighlight;
  
  // Archive
  isArchived: boolean;
  archivedAt?: string;
  
  // Shares
  shares: StoryShare[];
  shareCount: number;
  
  // Settings
  allowReplies: boolean;
  allowSharing: boolean;
  
  // Status
  isActive: boolean;
  expiresAt: string;
  createdAt: string;
}

export interface StoryFeedUser {
  _id: string;
  user: User;
  stories: Story[];
  hasUnviewed: number;
  latestStory: Story;
}

export interface StoryFeedResponse {
  success: boolean;
  count: number;
  data: StoryFeedUser[];
}

export interface StoryViewersResponse {
  success: boolean;
  data: {
    viewCount: number;
    views: StoryView[];
  };
}

export interface StoryReactionsResponse {
  success: boolean;
  data: {
    reactionCount: number;
    reactions: StoryReaction[];
  };
}

export interface QuestionResponsesResponse {
  success: boolean;
  data: {
    prompt: string;
    responses: QuestionResponse[];
  };
}

export interface HighlightsResponse {
  success: boolean;
  count: number;
  data: StoryHighlight[];
}

export interface ArchivedStoriesResponse {
  success: boolean;
  count: number;
  total: number;
  pages: number;
  data: Story[];
}

export interface CloseFriendsResponse {
  success: boolean;
  count: number;
  data: User[];
}

// Common reaction emojis
export const STORY_REACTIONS = ['❤️', '😂', '😮', '😢', '😡', '🔥', '👏', '🎉', '💯', '👀'];

