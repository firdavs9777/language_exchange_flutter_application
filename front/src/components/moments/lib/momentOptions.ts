/**
 * The closed vocabularies a moment carries, mirrored from the server's
 * models/Moment.js enums. Labels live in i18n under
 * moments_section.categories.* and moments_section.moods.*.
 */
export const MOMENT_CATEGORIES = [
  "general",
  "language-learning",
  "culture",
  "food",
  "travel",
  "music",
  "books",
  "hobbies",
  "daily-life",
  "technology",
  "entertainment",
  "sports",
  "movies",
  "study",
  "work",
  "question",
];

export const MOMENT_MOODS = [
  { value: "happy", emoji: "😊" },
  { value: "excited", emoji: "🤩" },
  { value: "grateful", emoji: "🙏" },
  { value: "motivated", emoji: "💪" },
  { value: "relaxed", emoji: "😌" },
  { value: "curious", emoji: "🤔" },
  { value: "sad", emoji: "😢" },
  { value: "love", emoji: "😍" },
  { value: "funny", emoji: "😂" },
  { value: "thoughtful", emoji: "💭" },
  { value: "cool", emoji: "😎" },
  { value: "tired", emoji: "😴" },
];
