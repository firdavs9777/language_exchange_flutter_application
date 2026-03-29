import React, { useState } from 'react';
import { X, Search } from 'lucide-react';
import { EMOJI_CATEGORIES, getRecentEmojis, addRecentEmoji } from '../utils/emojiUtils';
import './EmojiPicker.scss';

interface EmojiPickerProps {
  onSelect: (emoji: string) => void;
  onClose: () => void;
}

const EmojiPicker: React.FC<EmojiPickerProps> = ({ onSelect, onClose }) => {
  const [activeCategory, setActiveCategory] = useState('smileys');
  const [searchQuery, setSearchQuery] = useState('');
  const recentEmojis = getRecentEmojis();

  const handleEmojiClick = (emoji: string) => {
    addRecentEmoji(emoji);
    onSelect(emoji);
  };

  const categories = {
    recent: { label: 'Recent', icon: '🕐', emojis: recentEmojis },
    ...EMOJI_CATEGORIES,
  };

  const filteredEmojis = searchQuery
    ? Object.values(EMOJI_CATEGORIES).flatMap(cat => cat.emojis).filter(emoji =>
        emoji.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : categories[activeCategory as keyof typeof categories]?.emojis || [];

  return (
    <div className="emoji-picker">
      <div className="emoji-picker-header">
        <div className="emoji-search">
          <Search size={16} />
          <input
            type="text"
            placeholder="Search emojis..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <button className="close-btn" onClick={onClose}>
          <X size={18} />
        </button>
      </div>

      {!searchQuery && (
        <div className="emoji-categories">
          {Object.entries(categories).map(([key, cat]) => (
            <button
              key={key}
              className={`category-btn ${activeCategory === key ? 'active' : ''}`}
              onClick={() => setActiveCategory(key)}
              title={cat.label}
            >
              {cat.icon}
            </button>
          ))}
        </div>
      )}

      <div className="emoji-grid">
        {filteredEmojis.length > 0 ? (
          filteredEmojis.map((emoji, index) => (
            <button
              key={`${emoji}-${index}`}
              className="emoji-btn"
              onClick={() => handleEmojiClick(emoji)}
            >
              {emoji}
            </button>
          ))
        ) : (
          <div className="no-emojis">
            {searchQuery ? 'No emojis found' : 'No recent emojis'}
          </div>
        )}
      </div>
    </div>
  );
};

export default EmojiPicker;
