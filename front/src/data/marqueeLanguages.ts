// The marquee scrolls 24 languages, not all 137: a full catalog loop takes
// minutes and buries Korean behind Zulu. The real total is stated as a stat.
//
// Order is the backend's own, from utils/languageCodes.js NAME_TO_ISO, whose
// comment reads "Popular languages first (mirrors Flutter list order)".
// Deriving it from an existing ordering keeps it defensible.
//
// The four sign languages in the catalog are deliberately absent: the app's
// LanguageCodes._untaggable set cannot represent a written exchange in them.
export const MARQUEE_LANGUAGES: string[] = [
  "English", "Korean", "Japanese", "Chinese", "Spanish", "French",
  "German", "Italian", "Portuguese", "Russian", "Arabic", "Hindi",
  "Indonesian", "Vietnamese", "Thai", "Turkish", "Polish", "Dutch",
  "Swedish", "Ukrainian", "Persian", "Tagalog", "Bengali", "Greek",
];
