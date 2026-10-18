import { Clock, TrendingUp, Users } from "lucide-react";

export interface CommunityMember {
  _id: string;
  name: string;
  bio: string;
  native_language: string;
  language_to_learn: string;
  imageUrls: string[];
}

export interface MemberCardProps {
  member: CommunityMember;
  onMemberClick: (memberId: string) => void;
}

export interface LanguageFlagProps {
  code: string;
}


export type TabType = "all" | "popular" | "new";


// Offline fallback only: the filter sheet lists the whole GET /languages
// catalog (lib/languageOptions.ts) and falls back to these while it loads.
export const COMMON_LANGUAGES = [
  "English", "Spanish", "French", "German", "Korean", 
  "Japanese", "Chinese", "Portuguese", "Russian", "Italian"
] as const;

// Both tables now live in src/utils/languages.ts, generated from the backend
// catalog. New code should import displayCode/languageFlag directly.

export const TABS = [
  { id: "all" as const, label: "All", icon: Users },
  { id: "popular" as const, label: "Popular", icon: TrendingUp },
  { id: "new" as const, label: "New", icon: Clock }
] as const;

export interface MemberCardProps {
  member: CommunityMember;
  onMemberClick: (memberId: string) => void;
}


export interface UserData {
  _id: string;
  name: string;
  gender: string;
  email: string;
  bio: string;
  birth_year: string;
  birth_month: string;
  birth_day: string;
  images: string[];
  native_language: string;
  language_to_learn: string;
  createdAt: string;
  followers: string[];
  following: string[];
  imageUrls: string[];
  isOnline?: boolean;
  lastActive?: string;
  lastSeen?: string;
  __v: number;
}

export interface SingleMember {
  data: UserData;
}

export interface RootState {
  auth: {
    userInfo?: {
      user: {
        _id: string;
      };
    };
  };
}

export interface LanguagePairProps {
  nativeLanguage: string;
  learningLanguage: string;
}

export interface ImageGalleryProps {
  images: string[];
  userName: string;
}

export interface ActionButtonProps {
  icon: string;
  label: string;
  onClick: () => void;
  variant?:
    | "primary"
    | "secondary"
    | "success"
    | "warning"
    | "following"
    | "outline";
  isLoading?: boolean;
  disabled?: boolean;
  size?: "sm" | "md" | "lg";
}

export interface StatsCardProps {
  value: number;
  label: string;
}
