// Common emoji categories
export const EMOJI_CATEGORIES = {
  recent: {
    label: 'Recent',
    icon: '🕐',
    emojis: [] as string[],
  },
  smileys: {
    label: 'Smileys',
    icon: '😀',
    emojis: [
      '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂',
      '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋',
      '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
      '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥', '😌',
      '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🤧',
    ],
  },
  gestures: {
    label: 'Gestures',
    icon: '👋',
    emojis: [
      '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞',
      '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍',
      '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝',
      '🙏', '✍️', '💅', '🤳', '💪', '🦾', '🦿', '🦵', '🦶', '👂',
    ],
  },
  hearts: {
    label: 'Hearts',
    icon: '❤️',
    emojis: [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '♥️',
    ],
  },
  nature: {
    label: 'Nature',
    icon: '🌸',
    emojis: [
      '🌸', '💮', '🏵️', '🌹', '🥀', '🌺', '🌻', '🌼', '🌷', '🌱',
      '🌲', '🌳', '🌴', '🌵', '🌾', '🌿', '☘️', '🍀', '🍁', '🍂',
      '🍃', '🌍', '🌎', '🌏', '🌑', '🌒', '🌓', '🌔', '🌕', '🌙',
    ],
  },
  food: {
    label: 'Food',
    icon: '🍔',
    emojis: [
      '🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐', '🍈', '🍒',
      '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦', '🥬',
      '🌭', '🍔', '🍟', '🍕', '🥪', '🥙', '🌮', '🌯', '🥗', '🥘',
    ],
  },
  objects: {
    label: 'Objects',
    icon: '💡',
    emojis: [
      '📱', '💻', '⌨️', '🖥️', '🖨️', '🖱️', '📷', '📸', '📹', '🎥',
      '📽️', '🎞️', '📞', '☎️', '📟', '📠', '📺', '📻', '🎙️', '🎚️',
      '⏰', '⏱️', '⏲️', '🕰️', '⌛', '⏳', '📡', '🔋', '🔌', '💡',
    ],
  },
  flags: {
    label: 'Flags',
    icon: '🏳️',
    emojis: [
      '🏳️', '🏴', '🏁', '🚩', '🏳️‍🌈', '🏳️‍⚧️', '🇺🇳', '🇺🇸', '🇬🇧', '🇨🇦',
      '🇦🇺', '🇩🇪', '🇫🇷', '🇮🇹', '🇪🇸', '🇯🇵', '🇰🇷', '🇨🇳', '🇮🇳', '🇧🇷',
    ],
  },
};

// Quick reaction emojis
export const QUICK_REACTIONS = ['❤️', '😂', '😮', '😢', '😡', '👍'];

// Get stored recent emojis
export const getRecentEmojis = (): string[] => {
  try {
    const stored = localStorage.getItem('recentEmojis');
    return stored ? JSON.parse(stored) : [];
  } catch {
    return [];
  }
};

// Add emoji to recent
export const addRecentEmoji = (emoji: string): void => {
  try {
    const recent = getRecentEmojis();
    const filtered = recent.filter(e => e !== emoji);
    const updated = [emoji, ...filtered].slice(0, 20);
    localStorage.setItem('recentEmojis', JSON.stringify(updated));
  } catch {
    // Silent fail
  }
};

// Search emojis
export const searchEmojis = (query: string): string[] => {
  if (!query) return [];

  const allEmojis = Object.values(EMOJI_CATEGORIES)
    .flatMap(cat => cat.emojis);

  // For now, just return all emojis - in a real app, you'd search by emoji name/keywords
  return allEmojis;
};

// Check if text contains only emojis
export const isOnlyEmojis = (text: string): boolean => {
  const emojiRegex = /^[\p{Emoji}\s]+$/u;
  return emojiRegex.test(text.trim());
};

// Count emojis in text
export const countEmojis = (text: string): number => {
  const emojiRegex = /\p{Emoji}/gu;
  const matches = text.match(emojiRegex);
  return matches ? matches.length : 0;
};
