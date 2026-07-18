export interface Moment {
  _id: string;
  title: string;
  description: string;
  comments: any[]; // Array of comment objects
  commentCount: number;
  location: {
    type: string; // "Point"
    coordinates: [number, number]; // [longitude, latitude]
    formattedAddress: string;
  };
  user: {
    _id: string;
    name: string;
    gender: string;
    email: string;
    mbti?: string;
    bloodType?: string;
    bio: string;
    birth_year: string;
    birth_month: string;
    birth_day: string;
    images: string[]; // Original image filenames
    native_language: string;
    language_to_learn: string;
    createdAt: string;
    imageUrls: string[]; // Full URLs to images
    __v: number;
  };
  likeCount: number;
  likedUsers: string[]; // Array of user IDs who liked the moment
  mood: string;
  tags: string[]; // Array of tag strings
  category: string; // e.g., "language-learning", "music"
  language: string; // e.g., "de", "korean"
  privacy: string; // e.g., "public"
  images: string[]; // Original image filenames
  imageUrls: string[]; // Full URLs to images
  scheduledFor: string | null;
  createdAt: string;
  __v: number;
  refetch?: () => void;
  // Video attachment (Package 3 parity)
  video?: {
    url: string;
    thumbnail?: string;
    duration?: number;
    width?: number;
    height?: number;
    mimeType?: string;
    fileSize?: number;
  };
  // Audio attachment (Package 3 parity)
  audio?: {
    url: string;
    duration: number;
    waveform: number[];
    mimeType?: string;
    fileSize?: number;
  };
  mediaType?: 'image' | 'video' | 'audio' | 'text';
  backgroundColor?: string;
  reactions?: Array<{ user: string; emoji: string; createdAt?: string }>;
  reactionCount?: number;
  shareCount?: number;
  saveCount?: number;
  savedBy?: string[];
  isSaved?: boolean;
  promptId?: string;
  isReel?: boolean;
}

// Back-compat alias — keep existing imports of `MomentType` compiling.
export type MomentType = Moment;
export interface User {
  _id: string;
  name: string;
  imageUrls?: string[];
}
export interface MomentProps {
  _id: string;
  title: string;
  description: string;
  likeCount: number;
  likedUsers: string[];
  commentCount: string[];
  createdAt: string;
  user: User;
  imageUrls?: string[];
  refetch?: () => void;
}
export interface AuthState {
  userInfo?: {
    user: {
      _id: string;
    };
  };
}
export interface RootState {
  auth: AuthState;
}
