import React, { useState } from "react";
import { X } from "lucide-react";
import "./StickerPanel.css";

interface StickerPanelProps {
  onSendSticker: (sticker: string) => void;
  onClose: () => void;
}

const STICKER_CATEGORIES: Record<string, { icon: string; stickers: string[] }> = {
  Smileys: {
    icon: "😀",
    stickers: [
      "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣",
      "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰",
      "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜",
      "🤗", "🤭", "🤫", "🤔", "😶", "😏", "😣", "😥",
    ],
  },
  Emotions: {
    icon: "😎",
    stickers: [
      "🤪", "🤨", "🧐", "🤓", "😎", "🥸", "🤩", "🥳",
      "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️",
      "😤", "😠", "😡", "🤬", "🥺", "😢", "😭", "😱",
      "😰", "😨", "😧", "😦", "😮", "😲", "🥱", "😴",
    ],
  },
  Gestures: {
    icon: "👍",
    stickers: [
      "👍", "👎", "👌", "✌️", "🤞", "🤟", "🤘", "🤙",
      "👈", "👉", "👆", "👇", "☝️", "👋", "🤚", "🖐️",
      "✋", "🖖", "👏", "🙌", "🤝", "🙏", "✍️", "💪",
      "🦾", "🤳", "🫶", "🫰", "🫵", "🫱", "🫲", "🤌",
    ],
  },
  Hearts: {
    icon: "❤️",
    stickers: [
      "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍",
      "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖",
      "💘", "💝", "💟", "♥️", "💌", "💋", "💍", "💎",
      "🫀", "❤️‍🔥", "❤️‍🩹", "♾️", "💏", "💑", "🥂", "🌹",
    ],
  },
  Animals: {
    icon: "🐶",
    stickers: [
      "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼",
      "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵", "🙈",
      "🙉", "🙊", "🐔", "🐧", "🐦", "🦅", "🦆", "🦉",
      "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", "🐙", "🐠",
    ],
  },
  Food: {
    icon: "🍔",
    stickers: [
      "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓",
      "🫐", "🍒", "🍑", "🥭", "🍍", "🥝", "🍔", "🍕",
      "🌮", "🌯", "🍜", "🍝", "🍣", "🍱", "🍩", "🍪",
      "🎂", "🍰", "🧁", "☕", "🍵", "🧋", "🍺", "🥤",
    ],
  },
  Travel: {
    icon: "✈️",
    stickers: [
      "🌍", "🌎", "🌏", "🗺️", "🏔️", "⛰️", "🌋", "🏝️",
      "🏖️", "🌅", "🌄", "🌠", "🎆", "🌃", "🏙️", "🌉",
      "✈️", "🚀", "🛸", "🚂", "🚗", "🚕", "🏍️", "⛵",
      "🎡", "🎢", "🎪", "🗼", "🗽", "⛩️", "🕌", "🏰",
    ],
  },
  Flags: {
    icon: "🏳️",
    stickers: [
      "🇺🇸", "🇬🇧", "🇰🇷", "🇯🇵", "🇨🇳", "🇹🇼", "🇪🇸", "🇫🇷",
      "🇩🇪", "🇧🇷", "🇮🇹", "🇷🇺", "🇸🇦", "🇮🇳", "🇻🇳", "🇹🇭",
      "🇹🇷", "🇮🇩", "🇵🇭", "🇲🇽", "🇦🇷", "🇨🇦", "🇦🇺", "🇳🇿",
      "🇳🇬", "🇪🇬", "🇿🇦", "🇰🇪", "🇨🇴", "🇵🇪", "🇵🇰", "🏳️‍🌈",
    ],
  },
};

const StickerPanel: React.FC<StickerPanelProps> = ({ onSendSticker, onClose }) => {
  const [activeCategory, setActiveCategory] = useState("Smileys");
  const [recentStickers, setRecentStickers] = useState<string[]>(() => {
    try {
      return JSON.parse(localStorage.getItem("recentStickers") || "[]");
    } catch {
      return [];
    }
  });

  const handleStickerClick = (sticker: string) => {
    onSendSticker(sticker);

    // Update recents
    const updated = [sticker, ...recentStickers.filter((s) => s !== sticker)].slice(0, 24);
    setRecentStickers(updated);
    localStorage.setItem("recentStickers", JSON.stringify(updated));
  };

  const categories = Object.keys(STICKER_CATEGORIES);

  return (
    <div className="sticker-panel">
      {/* Header */}
      <div className="sticker-panel-header">
        <span className="sticker-panel-title">Stickers</span>
        <button className="sticker-panel-close" onClick={onClose}>
          <X size={18} />
        </button>
      </div>

      {/* Category Tabs */}
      <div className="sticker-tabs">
        {recentStickers.length > 0 && (
          <button
            className={`sticker-tab ${activeCategory === "Recent" ? "active" : ""}`}
            onClick={() => setActiveCategory("Recent")}
            title="Recent"
          >
            🕐
          </button>
        )}
        {categories.map((cat) => (
          <button
            key={cat}
            className={`sticker-tab ${activeCategory === cat ? "active" : ""}`}
            onClick={() => setActiveCategory(cat)}
            title={cat}
          >
            {STICKER_CATEGORIES[cat].icon}
          </button>
        ))}
      </div>

      {/* Sticker Grid */}
      <div className="sticker-grid-container">
        <div className="sticker-grid">
          {(activeCategory === "Recent"
            ? recentStickers
            : STICKER_CATEGORIES[activeCategory]?.stickers || []
          ).map((sticker, i) => (
            <button
              key={`${sticker}-${i}`}
              className="sticker-item"
              onClick={() => handleStickerClick(sticker)}
            >
              {sticker}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default StickerPanel;
