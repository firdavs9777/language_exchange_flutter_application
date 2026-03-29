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
  user: User;
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

export interface Mention {
  user: User;
  username: string;
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
}

export interface PollOption {
  text: string;
  votes: string[];
  voteCount: number;
  index?: number;
  percentage?: number;
  voted?: boolean;
}

export interface StoryPoll {
  question: string;
  options: PollOption[];
  isAnonymous: boolean;
  expiresAt?: string;
}

export interface QuestionResponse {
  user: User | null;
  text: string;
  respondedAt: string;
  isAnonymous: boolean;
}

export interface StoryQuestionBox {
  prompt: string;
  responses: QuestionResponse[];
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
  
  // Views
  views: StoryView[];
  viewCount: number;
  
  // Reactions
  reactions: StoryReaction[];
  reactionCount: number;
  
  // Replies
  replies: StoryReply[];
  replyCount: number;
  
  // Mentions
  mentions?: Mention[];
  
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

