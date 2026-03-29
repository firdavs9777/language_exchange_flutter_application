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
  image: string;
  native_language: string;
  language_to_learn: string;
  createdAt: string;
  images: string[];
  imageUrls: string[];
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
export interface ImageViewerModalProps {
  show: boolean;
  images: string[];
  currentIndex: number;
  onClose: () => void;
  onSelectImage: (index: number) => void;
}
