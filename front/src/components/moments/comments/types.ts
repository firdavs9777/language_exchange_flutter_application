/**
 * The comment shape the web feed reads, matching models/Comment.js plus the
 * `user.imageUrls` the controllers add (controllers/comments.js maps
 * `user.images` through `toCdnUrl` before responding).
 *
 * Types only -- nothing here emits runtime code, so importing from this
 * module costs nothing at build time.
 */

export interface CommentUser {
  _id: string;
  name: string;
  imageUrls?: string[];
}

export interface CommentCorrection {
  originalText?: string;
  correctedText: string;
  explanation?: string;
}

export interface CommentReaction {
  emoji: string;
  user?: string | { _id: string };
  users?: Array<string | { _id: string }>;
}

export interface CommentMention {
  user?: string | { _id: string };
  username?: string;
  /** UTF-16 offset into `text` (the app computes it with Dart String indices, the same unit as JS). */
  offset?: number;
  length?: number;
}

export interface CommentType {
  _id: string;
  text: string;
  user: CommentUser;
  createdAt: string;
  imageUrl?: string;
  parentComment?: string | null;
  replyCount?: number;
  likedUsers?: Array<string | { _id: string }>;
  likeCount?: number;
  reactions?: CommentReaction[];
  reactionCount?: number;
  correction?: CommentCorrection;
  mentions?: CommentMention[];
}
