import React, { useState, useEffect } from "react";
import { Col, Row, Container, Card } from "react-bootstrap";
import UsersList from "./UsersList";
import ChatContent from "./ChatContent";
import { useNavigate, useParams } from "react-router-dom";
import { NavLink } from "react-router-dom";
const MainChat: React.FC = () => {
  const { userId } = useParams<{ userId?: string }>();
  const [userName, setUserName] = useState<string>("");
  const [profilePicture, setProfilePicture] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [isLoadingUserInfo, setIsLoadingUserInfo] = useState<boolean>(false);
  const navigate = useNavigate();

  // Handle direct navigation to chat URL
  useEffect(() => {
    const fetchUserInfo = async () => {
      if (userId && !userName) {
        setIsLoadingUserInfo(true);
        try {
          // Replace this with your actual API call to fetch user info
          const response = await fetch(`/api/users/${userId}`);
          if (response.ok) {
            const userInfo = await response.json();
            setUserName(userInfo.name || "");
            setProfilePicture(userInfo.imageUrls?.[0] || "");
          }
        } catch (error) {
          console.error("Error fetching user info:", error);
        } finally {
          setIsLoadingUserInfo(false);
        }
      }
    };

    fetchUserInfo();
  }, [userId, userName]);

  // Reset user info when userId changes or becomes undefined
  useEffect(() => {
    if (!userId) {
      setUserName("");
      setProfilePicture("");
    }
  }, [userId]);

  const handleSelectUser = (
    selectedUserId: string,
    selectedUserName: string,
    selectedProfilePicture: string
  ) => {
    // Only navigate if we're selecting a different user
    if (selectedUserId !== userId) {
      navigate(`/chat/${selectedUserId}`);
    }

    // Always update the user info (in case it wasn't loaded from direct navigation)
    setUserName(selectedUserName);
    setProfilePicture(selectedProfilePicture);
  };

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(e.target.value);
  };

  const handleStartNewChat = () => {
    // You can implement logic to show a user search modal or navigate to user selection
    console.log("Start new chat clicked");
  };

  return (
    <Container fluid className="p-0">
      <Row className="g-0 vh-100">
        {/* Left sidebar - Users list */}
        <Col md={3} lg={5} xl={3} className="border-end shadow-sm bg-white">
          <div className="d-flex flex-column h-100">
            <div className="p-3 border-bottom bg-light">
              <h5 className="mb-0 fw-bold text-primary">
                <i className="bi bi-chat-dots-fill me-2"></i>
                Messages
              </h5>
            </div>


            <div className="px-3 py-2 mx-1 border-bottom">
              <div className="input-group input-group-sm">
                <span className="input-group-text bg-light border-end-0">
                  <i className="bi bi-search"></i>
                </span>
                <input
                  type="text"
                  className="form-control form-control-sm bg-light border-start-0"
                  placeholder="Search messages..."
                  value={searchQuery}
                  onChange={handleSearch}
                  aria-label="Search messages"
                />
                {searchQuery && (
                  <button
                    className="btn btn-sm btn-outline-secondary border-start-0"
                    onClick={() => setSearchQuery("")}
                    aria-label="Clear search"
                  >
                    <i className="bi bi-x"></i>
                  </button>
                )}
              </div>
            </div>
            
            <div className="flex-grow-1 overflow-auto" style={{ maxHeight: "calc(100vh - 130px)" }}>
              <UsersList 
                onSelectUser={handleSelectUser} 
                activeUserId={userId} 
                searchQuery={searchQuery}
              />
            </div>
          </div>
        </Col>
        
        <Col md={9} lg={7} xl={9} className="bg-light">
          {userId ? (
            <ChatContent
              selectedUser={userId}
              userName={userName}
              profilePicture={profilePicture}
              isLoadingUserInfo={isLoadingUserInfo}
            />
          ) : (
            <div className="d-flex align-items-center justify-content-center h-100 flex-column text-center p-4">
              <div className="mb-4">
                <div
                  className="bg-white rounded-circle p-4 shadow-sm d-inline-flex align-items-center justify-content-center"
                  style={{ width: "120px", height: "120px" }}
                >
                  <i
                    className="bi bi-chat-text text-primary"
                    style={{ fontSize: "3rem" }}
                  ></i>
                </div>
              </div>
              <Card
                className="border-0 shadow-sm"
                style={{ maxWidth: "400px" }}
              >
                <Card.Body>
                  <h4 className="mb-3">Welcome to Chat</h4>
                  <p className="text-muted mb-4">
                    Select a conversation from the list to start chatting or
                    search for a user to begin a new conversation.
                  </p>
                  <div className="d-grid">
                    <button className="btn btn-primary rounded-pill">
                      <i className="bi bi-plus-circle me-2"></i>
                      Start New Chat
                    </button>
                  </div>
                </Card.Body>
              </Card>
            </div>
          )}
        </Col>
      </Row>
    </Container>
  );
};

export default MainChat;
