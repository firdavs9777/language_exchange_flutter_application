import React, { useState, useMemo } from 'react';
import { useParams, useNavigate, useSearchParams } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { ArrowLeft, Image, Video, FileText, X, Download, ZoomIn, Loader2 } from 'lucide-react';
import { useGetConversationQuery } from '../../store/slices/chatSlice';
import './MediaGallery.scss';

interface MediaItem {
  _id: string;
  type: 'image' | 'video' | 'file';
  url: string;
  thumbnail?: string;
  name?: string;
  size?: number;
  createdAt: string;
  sender?: {
    _id: string;
    name: string;
  };
}

interface Message {
  _id: string;
  type?: 'text' | 'image' | 'video' | 'file' | 'voice';
  message?: string;
  content?: string;
  mediaUrl?: string;
  imageUrl?: string;
  fileUrl?: string;
  fileName?: string;
  fileSize?: number;
  createdAt: string;
  sender: {
    _id: string;
    name: string;
  };
}

interface RootState {
  auth: {
    userInfo: {
      user: {
        _id: string;
      };
    };
  };
}

const MediaGallery: React.FC = () => {
  const { conversationId } = useParams<{ conversationId: string }>();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  const userId = useSelector((state: RootState) => state.auth.userInfo?.user?._id);

  const initialTab = searchParams.get('type') || 'photos';
  const [activeTab, setActiveTab] = useState<'photos' | 'videos' | 'files'>(
    initialTab as 'photos' | 'videos' | 'files'
  );
  const [selectedMedia, setSelectedMedia] = useState<MediaItem | null>(null);

  // Fetch conversation messages
  const { data, isLoading, error } = useGetConversationQuery(
    {
      senderId: userId,
      receiverId: conversationId || '',
      limit: 500, // Get more messages to find all media
    },
    { skip: !userId || !conversationId }
  );

  // Extract media items from messages
  const mediaItems = useMemo(() => {
    if (!data?.data) return [];

    const items: MediaItem[] = [];

    data.data.forEach((message: Message) => {
      const messageType = message.type || 'text';

      // Skip text and voice messages
      if (messageType === 'text' || messageType === 'voice') return;

      // Get media URL from various possible fields
      const mediaUrl = message.mediaUrl || message.imageUrl || message.fileUrl;

      if (!mediaUrl) return;

      let type: 'image' | 'video' | 'file' = 'file';
      if (messageType === 'image' || mediaUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
        type = 'image';
      } else if (messageType === 'video' || mediaUrl.match(/\.(mp4|webm|mov|avi)$/i)) {
        type = 'video';
      }

      items.push({
        _id: message._id,
        type,
        url: mediaUrl,
        thumbnail: type === 'video' ? undefined : mediaUrl,
        name: message.fileName || message.message || message.content,
        size: message.fileSize,
        createdAt: message.createdAt,
        sender: message.sender,
      });
    });

    // Sort by date (newest first)
    return items.sort((a, b) =>
      new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  }, [data]);

  const filteredMedia = useMemo(() => {
    return mediaItems.filter(item => {
      if (activeTab === 'photos') return item.type === 'image';
      if (activeTab === 'videos') return item.type === 'video';
      if (activeTab === 'files') return item.type === 'file';
      return true;
    });
  }, [mediaItems, activeTab]);

  // Group media by date
  const groupedMedia = useMemo(() => {
    return filteredMedia.reduce((acc, item) => {
      const date = new Date(item.createdAt).toLocaleDateString('en-US', {
        month: 'long',
        year: 'numeric',
      });
      if (!acc[date]) acc[date] = [];
      acc[date].push(item);
      return acc;
    }, {} as Record<string, MediaItem[]>);
  }, [filteredMedia]);

  const formatFileSize = (bytes?: number) => {
    if (!bytes) return 'Unknown size';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const handleDownload = (url: string, name?: string) => {
    const link = document.createElement('a');
    link.href = url;
    link.download = name || 'download';
    link.target = '_blank';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Get counts for each tab
  const counts = useMemo(() => ({
    photos: mediaItems.filter(i => i.type === 'image').length,
    videos: mediaItems.filter(i => i.type === 'video').length,
    files: mediaItems.filter(i => i.type === 'file').length,
  }), [mediaItems]);

  if (isLoading) {
    return (
      <div className="media-gallery">
        <header className="gallery-header">
          <button className="back-btn" onClick={() => navigate(-1)}>
            <ArrowLeft size={24} />
          </button>
          <h1>Shared Media</h1>
        </header>
        <div className="gallery-loading">
          <Loader2 className="spinner" size={40} />
          <p>Loading media...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="media-gallery">
        <header className="gallery-header">
          <button className="back-btn" onClick={() => navigate(-1)}>
            <ArrowLeft size={24} />
          </button>
          <h1>Shared Media</h1>
        </header>
        <div className="empty-state">
          <div className="empty-icon">
            <X size={48} />
          </div>
          <p>Error loading media</p>
        </div>
      </div>
    );
  }

  return (
    <div className="media-gallery">
      {/* Header */}
      <header className="gallery-header">
        <button className="back-btn" onClick={() => navigate(-1)}>
          <ArrowLeft size={24} />
        </button>
        <h1>Shared Media</h1>
      </header>

      {/* Tabs */}
      <div className="gallery-tabs">
        <button
          className={`tab ${activeTab === 'photos' ? 'active' : ''}`}
          onClick={() => setActiveTab('photos')}
        >
          <Image size={18} />
          Photos {counts.photos > 0 && `(${counts.photos})`}
        </button>
        <button
          className={`tab ${activeTab === 'videos' ? 'active' : ''}`}
          onClick={() => setActiveTab('videos')}
        >
          <Video size={18} />
          Videos {counts.videos > 0 && `(${counts.videos})`}
        </button>
        <button
          className={`tab ${activeTab === 'files' ? 'active' : ''}`}
          onClick={() => setActiveTab('files')}
        >
          <FileText size={18} />
          Files {counts.files > 0 && `(${counts.files})`}
        </button>
      </div>

      {/* Content */}
      <div className="gallery-content">
        {Object.entries(groupedMedia).length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">
              {activeTab === 'photos' && <Image size={48} />}
              {activeTab === 'videos' && <Video size={48} />}
              {activeTab === 'files' && <FileText size={48} />}
            </div>
            <p>No {activeTab} shared yet</p>
          </div>
        ) : (
          Object.entries(groupedMedia).map(([date, items]) => (
            <div key={date} className="media-group">
              <h3 className="group-date">{date}</h3>

              {activeTab === 'files' ? (
                <div className="files-list">
                  {items.map((item) => (
                    <div key={item._id} className="file-item">
                      <div className="file-icon">
                        <FileText size={24} />
                      </div>
                      <div className="file-info">
                        <span className="file-name">{item.name || 'Unknown file'}</span>
                        <span className="file-size">{formatFileSize(item.size)}</span>
                      </div>
                      <button
                        className="download-btn"
                        onClick={() => handleDownload(item.url, item.name)}
                      >
                        <Download size={18} />
                      </button>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="media-grid">
                  {items.map((item) => (
                    <div
                      key={item._id}
                      className="media-item"
                      onClick={() => setSelectedMedia(item)}
                    >
                      <img
                        src={item.thumbnail || item.url}
                        alt=""
                        loading="lazy"
                        onError={(e) => {
                          (e.target as HTMLImageElement).src = '/placeholder-image.png';
                        }}
                      />
                      {item.type === 'video' && (
                        <div className="video-overlay">
                          <Video size={24} />
                        </div>
                      )}
                      <div className="zoom-overlay">
                        <ZoomIn size={20} />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))
        )}
      </div>

      {/* Lightbox */}
      {selectedMedia && (
        <div className="lightbox" onClick={() => setSelectedMedia(null)}>
          <button className="close-btn" onClick={() => setSelectedMedia(null)}>
            <X size={24} />
          </button>
          <button
            className="download-btn"
            onClick={(e) => {
              e.stopPropagation();
              handleDownload(selectedMedia.url, selectedMedia.name);
            }}
          >
            <Download size={24} />
          </button>
          <div className="lightbox-content" onClick={(e) => e.stopPropagation()}>
            {selectedMedia.type === 'video' ? (
              <video src={selectedMedia.url} controls autoPlay />
            ) : (
              <img src={selectedMedia.url} alt="" />
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default MediaGallery;
