import React, { useEffect, useMemo } from "react";
import "./UserVisitors.css";
import { useGetProfileVisitorsQuery, useGetVipStatusQuery } from "../../store/slices/usersSlice";
import { useSelector } from "react-redux";
import {
  Card,
  Col,
  Row,
  Container,
  Badge,
  Spinner,
  Alert,
  Button,
} from "react-bootstrap";
import { Link, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  FaCrown,
  FaMapMarkerAlt,
  FaEye,
  FaUserFriends,
  FaCalendarDay,
  FaCalendarWeek,
  FaChartBar,
  FaClock,
  FaLock,
  FaMobileAlt,
} from "react-icons/fa";

interface VisitorUser {
  _id: string;
  name: string;
  photo?: string;
  imageUrls?: string[];
  gender: string;
  city?: string;
  country?: string;
  isVIP?: boolean;
  nativeLanguage: string;
  native_language?: string;
}

interface Visitor {
  user: VisitorUser;
  lastVisit: string;
  visitCount: number;
  source: string;
}

interface VisitorsResponse {
  success: boolean;
  count: number;
  stats?: {
    totalVisits: number;
    uniqueVisitors: number;
    visitsToday: number;
    visitsThisWeek: number;
    bySource?: Array<{ _id: string; count: number }>;
  };
  data: Visitor[];
}

interface RootState {
  auth: {
    userInfo?: {
      user?: {
        _id: string;
        userMode?: string;
      };
      data?: {
        _id: string;
        userMode?: string;
      };
    };
  };
}

// Time formatting helper component
const TimeAgo: React.FC<{ date: string }> = ({ date }) => {
  const { t } = useTranslation();

  const timeAgoText = useMemo(() => {
    const now = new Date();
    const past = new Date(date);
    const diff = now.getTime() - past.getTime();

    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    const weeks = Math.floor(days / 7);

    if (minutes < 1) return t("moments_section.timeAgo.justNow");
    if (minutes < 60)
      return t("moments_section.timeAgo.minutesAgo", { minutes });
    if (hours < 24) return t("moments_section.timeAgo.hoursAgo", { hours });
    if (days < 7) return t("moments_section.timeAgo.daysAgo", { days });
    if (weeks < 4) return `${weeks}w ago`;
    return new Date(date).toLocaleDateString();
  }, [date, t]);

  return <span className="time-text">{timeAgoText}</span>;
};

// Source badge helper
const SourceBadge: React.FC<{ source: string }> = ({ source }) => {
  const { t } = useTranslation();
  const sourceMap: { [key: string]: { bg: string; label: string } } = {
    moments: {
      bg: "primary",
      label: t("profile.visitors.via_moments") || "Via Moments",
    },
    search: {
      bg: "info",
      label: t("profile.visitors.via_search") || "Via Search",
    },
    chat: {
      bg: "success",
      label: t("profile.visitors.via_chat") || "Via Chat",
    },
    direct: {
      bg: "secondary",
      label: t("profile.visitors.via_direct") || "Direct",
    },
    followers: {
      bg: "warning",
      label: t("profile.visitors.via_followers") || "Via Followers",
    },
  };

  const sourceInfo = sourceMap[source] || { bg: "secondary", label: source };
  return (
    <Badge bg={sourceInfo.bg as any} className="source-badge">
      {sourceInfo.label}
    </Badge>
  );
};

const UserVisitorsList: React.FC = () => {
  const navigate = useNavigate();
  const userId = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?._id || state.auth.userInfo?.data?._id || null
  );
  const userMode = useSelector(
    (state: RootState) =>
      state.auth.userInfo?.user?.userMode || state.auth.userInfo?.data?.userMode || "free"
  );

  // Check VIP status
  const { data: vipData } = useGetVipStatusQuery(userId || "", {
    skip: !userId,
  });

  const isVip = userMode === "vip" || (vipData as any)?.data?.isActive;

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [userId]);

  const {
    data: visitors,
    isLoading,
    error,
  } = useGetProfileVisitorsQuery({ userId: userId || "", page: 1, limit: 50 }, { skip: !userId || !isVip });

  const visitorsData = visitors as VisitorsResponse | undefined;
  const { t } = useTranslation();

  // VIP-only feature - show upgrade prompt for non-VIP users
  if (!isVip) {
    return (
      <div className="visitors-page">
        <div className="visitors-hero">
          <Container>
            <h1 className="hero-title">
              <FaEye className="me-2" />
              {t("profile.visitors.title") || "Profile Visitors"}
            </h1>
          </Container>
        </div>
        <Container className="visitors-content">
          <Card className="text-center p-5 border-0 shadow-lg" style={{ borderRadius: "20px" }}>
            <Card.Body>
              <div className="mb-4">
                <div
                  className="d-inline-flex align-items-center justify-content-center rounded-circle bg-warning bg-opacity-10"
                  style={{ width: "80px", height: "80px" }}
                >
                  <FaLock className="text-warning" size={32} />
                </div>
              </div>
              <h3 className="mb-3">{t("profile.visitors.vipOnly") || "VIP Feature"}</h3>
              <p className="text-muted mb-4">
                {t("profile.visitors.vipOnlyDesc") || "See who visited your profile by upgrading to VIP. This feature is available exclusively for VIP members."}
              </p>
              <div className="d-flex flex-column gap-3 align-items-center">
                <div className="bg-light rounded-3 p-4 w-100" style={{ maxWidth: "400px" }}>
                  <div className="d-flex align-items-center gap-3 mb-3">
                    <FaCrown className="text-warning" size={24} />
                    <div className="text-start">
                      <strong>{t("profile.visitors.vipBenefits") || "VIP Benefits"}</strong>
                    </div>
                  </div>
                  <ul className="text-start mb-0 ps-4">
                    <li className="mb-2">{t("vip.features.seeProfileVisitors") || "See who visited your profile"}</li>
                    <li className="mb-2">{t("vip.features.unlimitedMessages") || "Unlimited messages"}</li>
                    <li className="mb-2">{t("vip.features.advancedFilters") || "Advanced search filters"}</li>
                    <li>{t("vip.features.noAds") || "Ad-free experience"}</li>
                  </ul>
                </div>
                <div className="bg-info bg-opacity-10 rounded-3 p-3 w-100" style={{ maxWidth: "400px" }}>
                  <div className="d-flex align-items-center gap-2">
                    <FaMobileAlt className="text-info" />
                    <small className="text-muted">
                      {t("vip.upgradeInAppDesc") || "VIP subscriptions can only be purchased through our mobile app"}
                    </small>
                  </div>
                </div>
                <Button
                  variant="outline-primary"
                  onClick={() => navigate("/settings/vip")}
                  className="mt-2"
                >
                  {t("profile.visitors.learnMore") || "Learn More About VIP"}
                </Button>
              </div>
            </Card.Body>
          </Card>
        </Container>
      </div>
    );
  }

  // Helper to get user image
  const getUserImage = (user: VisitorUser) => {
    if (user.imageUrls && user.imageUrls.length > 0) {
      return user.imageUrls[0];
    }
    if (user.photo) {
      return user.photo;
    }
    // Default avatar based on gender
    const gender = user.gender?.toLowerCase();
    if (gender === "male") {
      return (
        "https://ui-avatars.com/api/?name=" +
        encodeURIComponent(user.name) +
        "&background=667eea&color=fff&size=200"
      );
    } else if (gender === "female") {
      return (
        "https://ui-avatars.com/api/?name=" +
        encodeURIComponent(user.name) +
        "&background=f093fb&color=fff&size=200"
      );
    }
    return (
      "https://ui-avatars.com/api/?name=" +
      encodeURIComponent(user.name) +
      "&background=4facfe&color=fff&size=200"
    );
  };

  // Loading state
  if (isLoading) {
    return (
      <div className="visitors-page">
        <div className="visitors-hero">
          <Container>
            <h1 className="hero-title">
              <FaEye className="me-2" />
              {t("profile.visitors.title") || "Profile Visitors"}
            </h1>
          </Container>
        </div>
        <Container className="visitors-content">
          <div
            className="d-flex justify-content-center align-items-center"
            style={{ minHeight: "300px" }}
          >
            <Spinner animation="border" variant="primary" />
          </div>
        </Container>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="visitors-page">
        <div className="visitors-hero">
          <Container>
            <h1 className="hero-title">
              <FaEye className="me-2" />
              {t("profile.visitors.title") || "Profile Visitors"}
            </h1>
          </Container>
        </div>
        <Container className="visitors-content">
          <Alert variant="danger" className="modern-alert">
            {t("profile.visitors.error") || "Error loading visitors"}
          </Alert>
        </Container>
      </div>
    );
  }

  // No visitors state
  if (!visitorsData || visitorsData.count === 0) {
    return (
      <div className="visitors-page">
        <div className="visitors-hero">
          <Container>
            <h1 className="hero-title">
              <FaEye className="me-2" />
              {t("profile.visitors.title") || "Profile Visitors"}
              <Badge bg="light" text="dark" className="ms-3 count-badge">
                0
              </Badge>
            </h1>
          </Container>
        </div>
        <Container className="visitors-content">
          <div className="empty-state">
            <FaUserFriends className="empty-icon" />
            <h3>{t("profile.visitors.no_visitors") || "No visitors yet"}</h3>
            <p className="text-muted">
              {t("profile.visitors.no_visitors_desc") ||
                "When people visit your profile, they'll appear here"}
            </p>
          </div>
        </Container>
      </div>
    );
  }

  return (
    <div className="visitors-page">
      {/* Hero Section */}
      <div className="visitors-hero">
        <Container>
          <h1 className="hero-title">
            <FaEye className="me-2" />
            {t("profile.visitors.title") || "Profile Visitors"}
            <Badge bg="light" text="dark" className="ms-3 count-badge">
              {visitorsData.count}
            </Badge>
          </h1>
        </Container>
      </div>

      <Container className="visitors-content">
        {/* Stats Section */}
        {visitorsData.stats && (
          <Card className="stats-card mb-4">
            <Card.Body>
              <Row className="g-3">
                <Col xs={6} md={3}>
                  <div className="stat-item">
                    <div className="stat-icon total-visits">
                      <FaChartBar />
                    </div>
                    <div className="stat-details">
                      <div className="stat-value">
                        {visitorsData.stats.totalVisits || 0}
                      </div>
                      <div className="stat-label">
                        {t("profile.visitors.total_visits") || "Total Visits"}
                      </div>
                    </div>
                  </div>
                </Col>

                <Col xs={6} md={3}>
                  <div className="stat-item">
                    <div className="stat-icon unique-visitors">
                      <FaUserFriends />
                    </div>
                    <div className="stat-details">
                      <div className="stat-value">
                        {visitorsData.stats.uniqueVisitors || 0}
                      </div>
                      <div className="stat-label">
                        {t("profile.visitors.unique_visitors") ||
                          "Unique Visitors"}
                      </div>
                    </div>
                  </div>
                </Col>

                <Col xs={6} md={3}>
                  <div className="stat-item">
                    <div className="stat-icon visits-today">
                      <FaCalendarDay />
                    </div>
                    <div className="stat-details">
                      <div className="stat-value">
                        {visitorsData.stats.visitsToday || 0}
                      </div>
                      <div className="stat-label">
                        {t("profile.visitors.visits_today") || "Today"}
                      </div>
                    </div>
                  </div>
                </Col>

                <Col xs={6} md={3}>
                  <div className="stat-item">
                    <div className="stat-icon visits-week">
                      <FaCalendarWeek />
                    </div>
                    <div className="stat-details">
                      <div className="stat-value">
                        {visitorsData.stats.visitsThisWeek || 0}
                      </div>
                      <div className="stat-label">
                        {t("profile.visitors.visits_week") || "This Week"}
                      </div>
                    </div>
                  </div>
                </Col>
              </Row>
            </Card.Body>
          </Card>
        )}

        {/* Visitors Grid */}
        <Row className="g-3">
          {visitorsData.data.map((visitor: Visitor) => {
            const userImage = getUserImage(visitor.user);
            const nativeLanguage =
              visitor.user.nativeLanguage || visitor.user.native_language;

            return (
              <Col xs={12} sm={6} md={4} lg={3} key={visitor.user._id}>
                <Link
                  to={`/community/${visitor.user._id}`}
                  className="text-decoration-none"
                >
                  <Card className="visitor-card">
                    {/* Image Section */}
                    <div className="visitor-image-wrapper">
                      <img
                        src={userImage}
                        alt={visitor.user.name}
                        className="visitor-image"
                        onError={(e: any) => {
                          const gender = visitor.user.gender?.toLowerCase();
                          if (gender === "male") {
                            e.target.src =
                              "https://ui-avatars.com/api/?name=" +
                              encodeURIComponent(visitor.user.name) +
                              "&background=667eea&color=fff&size=200";
                          } else if (gender === "female") {
                            e.target.src =
                              "https://ui-avatars.com/api/?name=" +
                              encodeURIComponent(visitor.user.name) +
                              "&background=f093fb&color=fff&size=200";
                          } else {
                            e.target.src =
                              "https://ui-avatars.com/api/?name=" +
                              encodeURIComponent(visitor.user.name) +
                              "&background=4facfe&color=fff&size=200";
                          }
                        }}
                      />

                      {/* VIP Badge */}
                      {visitor.user.isVIP && (
                        <div className="vip-badge-wrapper">
                          <Badge bg="warning" className="vip-badge">
                            <FaCrown className="me-1" />
                            VIP
                          </Badge>
                        </div>
                      )}

                      {/* Name Overlay */}
                      <div className="name-overlay">
                        <h5 className="visitor-name">{visitor.user.name}</h5>
                      </div>
                    </div>

                    {/* Card Body */}
                    <Card.Body className="visitor-body">
                      {/* Visit Info */}
                      <div className="visit-info-section">
                        <div className="visit-info-item">
                          <FaClock className="info-icon" />
                          <TimeAgo date={visitor.lastVisit} />
                        </div>
                        <Badge bg="info" pill className="visit-count-badge">
                          {visitor.visitCount}{" "}
                          {visitor.visitCount === 1 ? "visit" : "visits"}
                        </Badge>
                      </div>

                      {/* Source Badge */}
                      <div className="mb-2">
                        <SourceBadge source={visitor.source} />
                      </div>

                      {/* Language Badge */}
                      {nativeLanguage && (
                        <div className="mb-2">
                          <Badge bg="secondary" className="language-badge">
                            🌍 {nativeLanguage}
                          </Badge>
                        </div>
                      )}

                      {/* Location */}
                      {(visitor.user.city || visitor.user.country) && (
                        <div className="location-info">
                          <FaMapMarkerAlt className="location-icon" />
                          <span className="location-text">
                            {[visitor.user.city, visitor.user.country]
                              .filter(Boolean)
                              .join(", ")}
                          </span>
                        </div>
                      )}
                    </Card.Body>
                  </Card>
                </Link>
              </Col>
            );
          })}
        </Row>
      </Container>
    </div>
  );
};

export default UserVisitorsList;
