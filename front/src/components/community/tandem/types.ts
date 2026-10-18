/**
 * Shapes shared by the tandem community widgets.
 *
 * `TandemMember` used to live in `TandemMemberCard.tsx`. That component was
 * the old member row, rendered only by the deleted `CommunityDetail` page;
 * `MemberCard.tsx` replaced it everywhere else. Once the detail page became
 * the profile page nothing rendered it any more, and the only thing still
 * imported from it was this interface — a 89-line component kept alive by a
 * type. The type moved here and the component went.
 */
export interface TandemMember {
  _id: string;
  name: string;
  imageUrls?: string[];
  bio?: string;
  topic?: string;
  native_language?: string;
  language_to_learn?: string;
  isVIP?: boolean;
  isVip?: boolean;
  isOnline?: boolean;
  isNew?: boolean;
  createdAt?: string;
  fluentExtras?: number;
  learnsExtras?: number;
}
