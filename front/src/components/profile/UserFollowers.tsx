import React, { useEffect } from "react";
import "./UserFollowers.css";
import { useGetFollowersQuery } from "../../store/slices/usersSlice";
import { useSelector } from "react-redux";
import { Card, Col, Row, Container, Badge, Spinner, Alert } from "react-bootstrap";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
// Define proper TypeScript interfaces for your data
interface Location {
  type: string;
  coordinates: number[];
  formattedAddress: string;
  street: string;
  city: string;
  state: string;
  zipcode: string;
  country: string;
}

interface Follower {
  _id: string;
  name: string;
  gender: string;
  mbti: string;
  bio: string;
  images: string[];
  native_language: string;
  language_to_learn: string;
  imageUrls: string[];
  location?: Location;
}

interface FollowersResponse {
  success: boolean;
  count: number;
  data: Follower[];
}

interface RootState {
  auth: {
    userInfo?: {
      user?: {
        _id: string;
      };
    };
  };
}

const UserFollowersList: React.FC = () => {
  // Type the useSelector properly
  const userId = useSelector((state: RootState) => state.auth.userInfo?.user?._id);
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [userId]);
  const {
    data: followers,
    isLoading,
    error,
  } = useGetFollowersQuery({ userId }, { skip: !userId });

  // Type cast the followers data
  const followersData = followers as FollowersResponse | undefined;

  const { t } = useTranslation();
  // Loading state
  if (isLoading) {
    return (
      <Container className="d-flex justify-content-center align-items-center" style={{ minHeight: "200px" }}>
        <Spinner animation="border" variant="primary" />
      </Container>
    );
  }

  // Error state
  if (error) {
    return (
      <Container className="my-4">
        <Alert variant="danger">
          {t('profile.stats.follower_error')}
        </Alert>
      </Container>
    );
  }

  // No followers state
  if (!followersData || followersData.count === 0) {
    return (
      <Container className="my-4 text-center">
        <h1 className="mb-4">{t('profile.stats.followers')} (0)</h1>
        <Alert variant="info">
          {t('profile.stats.no_followers')}
        </Alert>
      </Container>
    );
  }

  return (
    <Container className="followers-container my-4">
      <h1 className="mb-4 text-center">
        {t('profile.stats.followers')}  <Badge bg="primary" pill>{followersData.count}</Badge>
      </h1>
      <Row className="g-4">
        {followersData.data.map((follower: Follower) => (
          <Col xs={12} sm={6} md={4} lg={3} key={follower._id}>
            <Link to={`/community/${follower._id}`} className="text-decoration-none">
              <Card className="shadow-sm h-100 border-0 hover-card">
                <div className="position-relative">
                  <Card.Img
                    variant="top"
                    src={follower.imageUrls[0] || "/placeholder.jpg"}
                    alt={follower.name}
                    className="img-fluid rounded-top"
                    style={{ height: "180px", objectFit: "cover" }}
                  />
                  <div className="position-absolute bottom-0 start-0 w-100 bg-dark bg-opacity-50 text-white p-2">
                    <h5 className="mb-0">{follower.name}</h5>
                  </div>
                </div>
                <Card.Body>
                  <p className="mb-2 text-truncate">
                    <small className="text-muted">{follower.bio || "No bio available"}</small>
                  </p>
                  <div className="d-flex justify-content-between">
                    <Badge bg="secondary">{t("profile.labels.native_language")}: {follower.native_language}</Badge>
                    <Badge bg="info">{t("profile.labels.learning")}: {follower.language_to_learn}</Badge>
                  </div>
                  {follower.location && (
                    <small className="d-block mt-2 text-muted">
                      <i className="bi bi-geo-alt"></i> {follower.location.city}, {follower.location.country}
                    </small>
                  )}
                </Card.Body>
              </Card>
            </Link>
          </Col>
        ))}
      </Row>
    </Container>
  );
};

export default UserFollowersList;