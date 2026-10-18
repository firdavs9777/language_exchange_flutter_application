import React, { useState } from "react";
import { Image as ImageIcon } from "lucide-react";

interface StoryReferenceCardProps {
  storyId: string;
  thumbnail?: string | null;
  label: string;
  onOpen?: (storyId: string) => void;
}

/**
 * The story a message is about (a share, a reply, a reaction), drawn above
 * the message the way the app's story reference preview is: thumbnail (a
 * placeholder for a text story, which has none) and what happened.
 */
const StoryReferenceCard: React.FC<StoryReferenceCardProps> = ({ storyId, thumbnail, label, onOpen }) => {
  const [broken, setBroken] = useState(false);
  const showThumbnail = !!thumbnail && !broken;
  return (
    <button
      type="button"
      className="story-ref"
      data-testid="story-ref"
      disabled={!storyId || !onOpen}
      onClick={(e) => {
        e.stopPropagation();
        if (storyId && onOpen) onOpen(storyId);
      }}
    >
      <span className="story-ref-thumb">
        {showThumbnail ? (
          <img
            src={thumbnail as string}
            alt=""
            loading="lazy"
            decoding="async"
            onError={() => setBroken(true)}
          />
        ) : (
          <ImageIcon size={18} aria-hidden="true" />
        )}
      </span>
      <span className="story-ref-label">{label}</span>
    </button>
  );
};

export default StoryReferenceCard;
