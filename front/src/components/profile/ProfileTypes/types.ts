export interface UserProfileData {
  _id: string;
  name: string;
  username: string;
  gender: string;
  email: string;
  bio: string;
  birth_year: string;
  birth_month: string;
  birth_day: string;
  native_language: string;
  language_to_learn: string;
  imageUrls: string[];
  /**
   * Present on the API document, never owned by the profile editor — optional
   * so the edit form can model itself with this type without inventing empty
   * values for fields it would then post back over the real ones.
   */
  image?: string;
  images?: string[];
  createdAt?: string;
  mbti?: string;
  bloodType?: string;
  topics?: string[];
  languageLevel?: string;
  occupation?: string;
  school?: string;
  /** Why they are here: learn / meet / date. See `../intents.ts`. */
  intents?: string[];
  location?: any;
  isOnline?: boolean;
  lastActive?: string;
}
export interface FollowerInterface {
  success?: boolean;
  data?: UserProfileData;
  count: string;
  message: string;
  followers?: UserProfileData[];
  following?: UserProfileData[];
  note: string;
}
