import React from 'react';
import { X, Send, Image as ImageIcon, Video, File } from 'lucide-react';
import { formatFileSize } from '../utils/messageFormatter';
import './MediaPreview.scss';

interface MediaPreviewProps {
  file: File;
  type: 'image' | 'video' | 'file';
  onRemove: () => void;
  onSend: () => void;
  caption?: string;
  onCaptionChange?: (caption: string) => void;
}

const MediaPreview: React.FC<MediaPreviewProps> = ({
  file,
  type,
  onRemove,
  onSend,
  caption = '',
  onCaptionChange,
}) => {
  const previewUrl = React.useMemo(() => {
    if (type === 'file') return null;
    return URL.createObjectURL(file);
  }, [file, type]);

  React.useEffect(() => {
    return () => {
      if (previewUrl) {
        URL.revokeObjectURL(previewUrl);
      }
    };
  }, [previewUrl]);

  const getFileIcon = () => {
    const extension = file.name.split('.').pop()?.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📎';
    }
  };

  return (
    <div className="media-preview-overlay" onClick={onRemove}>
      <div className="media-preview" onClick={(e) => e.stopPropagation()}>
        <header className="preview-header">
          <span className="preview-title">
            {type === 'image' && <><ImageIcon size={18} /> Send Photo</>}
            {type === 'video' && <><Video size={18} /> Send Video</>}
            {type === 'file' && <><File size={18} /> Send File</>}
          </span>
          <button className="close-btn" onClick={onRemove}>
            <X size={20} />
          </button>
        </header>

        <div className="preview-content">
          {type === 'image' && previewUrl && (
            <img src={previewUrl} alt="Preview" className="preview-image" />
          )}

          {type === 'video' && previewUrl && (
            <video src={previewUrl} controls className="preview-video" />
          )}

          {type === 'file' && (
            <div className="file-preview">
              <span className="file-icon">{getFileIcon()}</span>
              <div className="file-info">
                <span className="file-name">{file.name}</span>
                <span className="file-size">{formatFileSize(file.size)}</span>
              </div>
            </div>
          )}
        </div>

        {onCaptionChange && type !== 'file' && (
          <div className="caption-input">
            <input
              type="text"
              value={caption}
              onChange={(e) => onCaptionChange(e.target.value)}
              placeholder="Add a caption..."
            />
          </div>
        )}

        <footer className="preview-footer">
          <button className="cancel-btn" onClick={onRemove}>
            Cancel
          </button>
          <button className="send-btn" onClick={onSend}>
            <Send size={18} />
            Send
          </button>
        </footer>
      </div>
    </div>
  );
};

export default MediaPreview;
