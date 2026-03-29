import React, { useState, useMemo, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import {
  useGetMyStoriesQuery,
  useDeleteIndividualStoryMutation,
  useArchiveStoryMutation,
  useGetArchivedStoriesQuery,
} from "../../store/slices/storiesSlice";
import {
  Container,
  Row,
  Col,
  Card,
  Spinner,
  Alert,
  Badge,
  Button,
} from "react-bootstrap";
import {
  FaPlus,
  FaTrash,
  FaArchive,
  FaEye,
  FaClock,
  FaImage,
  FaVideo,
  FaFont,
  FaTimes,
} from "react-icons/fa";
import { Story } from "./types";
import { toast } from "react-toastify";
import "./MyStories.scss";

interface RootState {
  auth: {
    userInfo?: {
      user?: {
        _id: string;
        name: string;
        imageUrls?: string[];
      };
      data?: {
        _id: string;
        name: string;
        imageUrls?: string[];
      };
    };
  };
}

const MyStories: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const userId = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?._id || state.auth.userInfo?.data?._id || null
  );

  const [showArchived, setShowArchived] = useState(false);
  const [selectedStory, setSelectedStory] = useState<string | null>(null);

  const {
    data: myStoriesData,
    isLoading: isLoadingActive,
    refetch: refetchActive,
  } = useGetMyStoriesQuery({}, { skip: !userId });

  const {
    data: archivedData,
    isLoading: isLoadingArchived,
  } = useGetArchivedStoriesQuery(
    { page: 1, limit: 50 },
    { skip: !userId || !showArchived }
  );

  const [deleteStory, { isLoading: isDeleting }] = useDeleteIndividualStoryMutation();
  const [archiveStory] = useArchiveStoryMutation();

  const activeStories = useMemo(() => {
    if (!myStoriesData) return [];
    const response = myStoriesData as { success?: boolean; data?: Story[]; count?: number };
    return Array.isArray(response) ? response : response.data || [];
  }, [myStoriesData]);

  const archivedStories = useMemo(() => {
    if (!archivedData) return [];
    const response = archivedData as {
      success?: boolean;
      data?: Story[];
      count?: number;
    };
    return Array.isArray(response) ? response : response.data || [];
  }, [archivedData]);

  const stories = showArchived ? archivedStories : activeStories;
  const isLoading = showArchived ? isLoadingArchived : isLoadingActive;

  const handleCreateStory = () => {
    navigate("/create-story");
  };

  const handleViewStory = (storyId: string) => {
    if (userId) {
      const storyIndex = activeStories.findIndex((s) => s._id === storyId);
      navigate(`/stories/${userId}`, { state: { startIndex: storyIndex >= 0 ? storyIndex : 0 } });
    }
  };

  const handleDeleteStory = async (storyId: string) => {
    if (!window.confirm(t("stories.delete_story") || "Delete this story?")) return;

    try {
      await deleteStory(storyId).unwrap();
      toast.success(t("stories.delete_story") || "Story deleted");
      refetchActive();
    } catch (error: any) {
      toast.error(error?.data?.error || "Failed to delete story");
    }
  };

  const handleArchiveStory = async (storyId: string) => {
    try {
      await archiveStory(storyId).unwrap();
      toast.success(t("stories.archive_story") || "Story archived");
      refetchActive();
    } catch (error: any) {
      toast.error(error?.data?.error || "Failed to archive story");
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(hours / 24);

    if (hours < 1) return t("moments_section.timeAgo.justNow") || "Just now";
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  };

  const getStoryPreview = (story: Story) => {
    if (story.mediaType === "text") {
      return (
        <div
          className="story-preview-text"
          style={{
            backgroundColor: story.backgroundColor || "#000",
            color: story.textColor || "#fff",
          }}
        >
          {story.text?.substring(0, 50)}...
        </div>
      );
    }
    return (
      <img
        src={story.mediaUrls?.[0] || story.mediaUrl || "/placeholder.jpg"}
        alt="Story"
        className="story-preview-image"
      />
    );
  };

  if (isLoading) {
    return (
      <div className="my-stories-page">
        <Container>
          <div className="d-flex justify-content-center align-items-center" style={{ minHeight: "400px" }}>
            <Spinner animation="border" variant="primary" />
          </div>
        </Container>
      </div>
    );
  }

  return (
    <div className="my-stories-page">
      <Container>
        {/* Header */}
        <div className="my-stories-header">
          <div className="header-content">
            <h1>{t("stories.title") || "My Stories"}</h1>
            <div className="header-actions">
              <Button
                variant={showArchived ? "outline-primary" : "primary"}
                onClick={() => setShowArchived(!showArchived)}
                className="me-2"
              >
                <FaArchive className="me-2" />
                {showArchived
                  ? t("stories.title") || "Active Stories"
                  : t("stories.archived_stories") || "Archived"}
              </Button>
              <Button variant="primary" onClick={handleCreateStory}>
                <FaPlus className="me-2" />
                {t("stories.create_first_story") || "Create Story"}
              </Button>
            </div>
          </div>

          {/* Stats */}
          <div className="stories-stats">
            <div className="stat-item">
              <span className="stat-value">{activeStories.length}</span>
              <span className="stat-label">{t("stories.title") || "Active"}</span>
            </div>
            <div className="stat-item">
              <span className="stat-value">{archivedStories.length}</span>
              <span className="stat-label">{t("stories.archived_stories") || "Archived"}</span>
            </div>
            <div className="stat-item">
              <span className="stat-value">
                {activeStories.reduce((sum, s) => sum + (s.viewCount || 0), 0)}
              </span>
              <span className="stat-label">{t("stories.viewers") || "Total Views"}</span>
            </div>
          </div>
        </div>

        {/* Stories Grid */}
        {stories.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">
              {showArchived ? <FaArchive /> : <FaImage />}
            </div>
            <h3>
              {showArchived
                ? t("stories.archived_stories") || "No Archived Stories"
                : t("stories.no_stories") || "No Stories Yet"}
            </h3>
            <p>
              {showArchived
                ? t("stories.archived_stories") || "You haven't archived any stories yet"
                : t("stories.no_stories_desc") || "Create your first story to share with friends!"}
            </p>
            {!showArchived && (
              <Button variant="primary" onClick={handleCreateStory}>
                <FaPlus className="me-2" />
                {t("stories.create_first_story") || "Create Story"}
              </Button>
            )}
          </div>
        ) : (
          <Row className="g-4">
            {stories.map((story: Story) => (
              <Col xs={12} sm={6} md={4} lg={3} key={story._id}>
                <Card className="story-card">
                  <div
                    className="story-preview"
                    onClick={() => handleViewStory(story._id)}
                  >
                    {getStoryPreview(story)}
                    <div className="story-overlay">
                      <div className="story-info">
                        <div className="story-type-badge">
                          {story.mediaType === "text" && <FaFont />}
                          {story.mediaType === "image" && <FaImage />}
                          {story.mediaType === "video" && <FaVideo />}
                        </div>
                        <div className="story-stats">
                          <span>
                            <FaEye /> {story.viewCount || 0}
                          </span>
                          {story.reactionCount > 0 && (
                            <span>❤️ {story.reactionCount}</span>
                          )}
                        </div>
                      </div>
                      <div className="story-time">
                        <FaClock /> {formatDate(story.createdAt)}
                      </div>
                    </div>
                  </div>
                  <Card.Body>
                    <div className="story-actions">
                      <Button
                        variant="outline-primary"
                        size="sm"
                        onClick={() => handleViewStory(story._id)}
                        className="me-2"
                      >
                        <FaEye /> {t("stories.view_story") || "View"}
                      </Button>
                      {!showArchived && (
                        <Button
                          variant="outline-secondary"
                          size="sm"
                          onClick={() => handleArchiveStory(story._id)}
                          className="me-2"
                        >
                          <FaArchive /> {t("stories.archive") || "Archive"}
                        </Button>
                      )}
                      <Button
                        variant="outline-danger"
                        size="sm"
                        onClick={() => handleDeleteStory(story._id)}
                        disabled={isDeleting}
                      >
                        <FaTrash /> {t("stories.delete_story") || "Delete"}
                      </Button>
                    </div>
                    {story.privacy && (
                      <Badge bg="secondary" className="mt-2">
                        {t(`stories.privacy.${story.privacy}`) || story.privacy}
                      </Badge>
                    )}
                  </Card.Body>
                </Card>
              </Col>
            ))}
          </Row>
        )}
      </Container>
    </div>
  );
};

export default MyStories;

