import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useGetCommunityDetailsQuery } from "../../store/slices/communitySlice";
import { useSelector } from "react-redux";
import {
  useFollowUserMutation,
  useUnFollowUserMutation,
} from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import Loader from "../Loader";
import { useCreateChatRoomMutation } from "../../store/slices/chatSlice";
import { useTranslation } from "react-i18next";
import { AiFillProfile } from "react-icons/ai";
import { ActionButtonProps, ImageGalleryProps, LanguagePairProps, StatsCardProps } from "./type";
import { getLanguageFlag } from "./utils";
import { RootState } from "../../store";

// Modern Language Display Component
const LanguagePair: React.FC<LanguagePairProps> = ({
  nativeLanguage,
  learningLanguage,
}) => {
  const { t } = useTranslation();

  return (
    <div className="d-flex align-items-center justify-content-center gap-4 p-4 bg-light rounded-4 mb-4">
      <div className="text-center">
        <div className="fs-2 mb-2">{getLanguageFlag(nativeLanguage)}</div>
        <div className="fw-medium text-dark">{nativeLanguage}</div>
        <div className="small text-muted">{t("communityDetail.language.speaks")}</div>
      </div>
      <div className="text-primary fs-4">⟷</div>
      <div className="text-center">
        <div className="fs-2 mb-2">{getLanguageFlag(learningLanguage)}</div>
        <div className="fw-medium text-dark">{learningLanguage}</div>
        <div className="small text-muted">{t("communityDetail.language.learning")}</div>
      </div>
    </div>
  );
};

// Modern Image Gallery Component
const ImageGallery: React.FC<ImageGalleryProps> = ({ images, userName }) => {
  const [activeIndex, setActiveIndex] = useState(0);
  const { t } = useTranslation();
  
  if (!images || images.length === 0) {
    return (
      <div
        className="bg-gradient rounded-4 d-flex align-items-center justify-content-center position-relative overflow-hidden"
        style={{
          height: "400px",
          background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
        }}
      >
        <div className="text-white text-center">
          <div className="fs-1 mb-2">
            <AiFillProfile />
          </div>
          <div className="fw-medium">
            {t("communityDetail.profile.noPhotos")}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="position-relative">
      <div
        className="rounded-4 overflow-hidden shadow-lg position-relative"
        style={{ height: "400px" }}
      >
        <img
          src={images[activeIndex] || "/images/default-avatar.jpg"}
          alt={`${userName}'s photo`}
          className="w-100 h-100 object-fit-cover"
          style={{ objectFit: "cover" }}
        />

        {images.length > 1 && (
          <div className="position-absolute bottom-0 start-0 end-0 p-3 bg-gradient-dark">
            <div className="d-flex justify-content-center gap-1">
              {images.map((_, index) => (
                <button
                  key={index}
                  className={`btn btn-sm rounded-circle p-0 ${
                    activeIndex === index ? "btn-light" : "btn-outline-light"
                  }`}
                  style={{ width: "8px", height: "8px" }}
                  onClick={() => setActiveIndex(index)}
                  aria-label={`View photo ${index + 1}`}
                />
              ))}
            </div>
          </div>
        )}
      </div>

      {images.length > 1 && (
        <div className="d-flex gap-2 mt-3 overflow-auto pb-2">
          {images.map((image, index) => (
            <button
              key={index}
              className={`border-0 rounded-3 overflow-hidden p-0 ${
                activeIndex === index ? "ring ring-primary" : "opacity-75"
              }`}
              style={{
                width: "60px",
                height: "60px",
                boxShadow:
                  activeIndex === index
                    ? "0 0 0 2px var(--bs-primary)"
                    : "none",
              }}
              onClick={() => setActiveIndex(index)}
            >
              <img
                src={image}
                alt={`${userName}'s photo ${index + 1}`}
                className="w-100 h-100 object-fit-cover"
                style={{ objectFit: "cover" }}
              />
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

const StatsCard: React.FC<StatsCardProps> = ({ value, label }) => (
  <div className="text-center p-3 bg-white rounded-3 shadow-sm">
    <div className="fs-4 fw-bold text-primary mb-1">{value}</div>
    <div className="small text-muted fw-medium">{label}</div>
  </div>
);

const ActionButton: React.FC<ActionButtonProps> = ({
  icon,
  label,
  onClick,
  variant = "primary",
  isLoading = false,
  disabled = false,
  size = "md",
}) => {
  const getButtonClasses = (): string => {
    const baseClasses =
      "btn d-flex align-items-center justify-content-center gap-2 fw-medium rounded-3";
    const sizeClasses = {
      sm: "btn-sm",
      md: "",
      lg: "btn-lg",
    };

    const variantClasses = {
      primary: "btn-primary shadow-sm",
      secondary: "btn-secondary",
      success: "btn-success shadow-sm",
      warning: "btn-warning text-white shadow-sm",
      following: "btn-outline-primary",
      outline: "btn-outline-secondary",
    };

    return `${baseClasses} ${sizeClasses[size]} ${variantClasses[variant]}`;
  };

  return (
    <button
      className={`${getButtonClasses()} ${
        disabled || isLoading ? "disabled" : ""
      }`}
      onClick={onClick}
      disabled={disabled || isLoading}
      aria-label={label}
      style={{ minHeight: "44px" }}
    >
      <span className="fs-5">{icon}</span>
      <span>{isLoading ? `${label}...` : label}</span>
    </button>
  );
};

const CommunityDetail: React.FC = () => {
  const { id: communityId } = useParams<{ id: string }>();
  const { data, isLoading, error, refetch } =
    useGetCommunityDetailsQuery(communityId);
  const [createChatRoom, { isLoading: isCreatingChat }] =
    useCreateChatRoomMutation();

  const navigate = useNavigate();
  const userId = useSelector(
    (state: RootState) => state.auth.userInfo?.user?._id
  );
  const token = useSelector(
    (state: RootState) => state.auth.userInfo?.token
  );
  const { t } = useTranslation();

  const [followUser, { isLoading: isFollowing }] = useFollowUserMutation();
  const [unFollowUser, { isLoading: isUnfollowing }] =
    useUnFollowUserMutation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [communityId]);

  if (!communityId) {
    return (
      <div className="container py-5 text-center">
        <div className="alert alert-danger rounded-4">
          {t("communityDetail.errors.invalidProfileId")}
        </div>
        <button
          className="btn btn-outline-primary rounded-3"
          onClick={() => navigate("/community")}
        >
          {t("communityDetail.buttons.backToCommunity")}
        </button>
      </div>
    );
  }

  const handleFollow = async (targetUser: string): Promise<void> => {
    try {
      if (!userId) {
        toast.error(t("communityDetail.notifications.loginToFollow"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        return;
      }

      const response = await followUser({ userId, targetUserId: targetUser });
      if ("error" in response) {
        toast.error(t("communityDetail.notifications.followFailed"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
      } else {
        toast.success(t("communityDetail.notifications.followSuccess"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        await refetch();
      }
    } catch (error) {
      toast.error(t("communityDetail.notifications.errorOccurred"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleUnfollow = async (targetUser: string): Promise<void> => {
    if (window.confirm(t("communityDetail.notifications.confirmUnfollow"))) {
      try {
        if (!userId) {
          toast.error(t("communityDetail.notifications.loginToUnfollow"), {
            autoClose: 3000,
            hideProgressBar: false,
            theme: "dark",
            transition: Bounce,
          });
          return;
        }

        const response = await unFollowUser({
          userId,
          targetUserId: targetUser,
        });

        if ("error" in response) {
          toast.error(t("communityDetail.notifications.unfollowFailed"), {
            autoClose: 3000,
            hideProgressBar: false,
            theme: "dark",
            transition: Bounce,
          });
        } else {
          toast.success(t("communityDetail.notifications.unfollowSuccess"), {
            autoClose: 3000,
            hideProgressBar: false,
            theme: "dark",
            transition: Bounce,
          });
          await refetch();
        }
      } catch (error) {
        toast.error(t("communityDetail.notifications.errorOccurred"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
      }
    }
  };

  const handleStartChat = async (memberId: string): Promise<void> => {
    try {
      if (!userId || !token) {
        toast.error(t("communityDetail.notifications.loginToChat") || "Please login to start a conversation", {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        navigate("/login");
        return;
      }

      const response = await createChatRoom(memberId).unwrap();

      if (response) {
        navigate(`/chat/${memberId}`);
      } else {
        navigate(`/chat`);
      }
    } catch (error) {
      toast.error(t("communityDetail.notifications.chatFailed"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      console.error(t("communityDetail.notifications.chatFailed"), error);
      navigate(`/chat/${memberId}`);
    }
  };

  const handleCallUser = (memberName: string): void => {
    toast.info(t("communityDetail.loading.initiatingCall", { name: memberName }), {
      autoClose: 3000,
      hideProgressBar: false,
      theme: "dark",
      transition: Bounce,
    });
  };

  if (isLoading) {
    return (
      <div className="container py-5 text-center">
        <Loader />
        <p className="mt-3 text-muted">{t("communityDetail.loading.loadingProfile")}</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container py-5 text-center">
        <div className="display-1 mb-3">⚠️</div>
        <h3 className="fw-bold">{t("communityDetail.errors.somethingWentWrong")}</h3>
        <p className="text-muted mb-4">
          {t("communityDetail.errors.tryAgainLater")}
        </p>
        <div className="d-flex gap-3 justify-content-center">
          <button
            className="btn btn-primary rounded-3"
            onClick={() => refetch()}
          >
            {t("communityDetail.buttons.tryAgain")}
          </button>
          <button
            className="btn btn-outline-secondary rounded-3"
            onClick={() => navigate("/community")}
          >
            {t("communityDetail.buttons.backToCommunity")}
          </button>
        </div>
      </div>
    );
  }

  const member = data as SingleMember;
  const memberDetails = member?.data;

  if (!memberDetails) {
    return (
      <div className="container py-5 text-center">
        <div className="display-1 mb-3">🔍</div>
        <h3 className="fw-bold">{t("communityDetail.errors.profileNotFound")}</h3>
        <p className="text-muted mb-4">
          {t("communityDetail.errors.profileNotFoundDesc")}
        </p>
        <button
          className="btn btn-outline-primary rounded-3"
          onClick={() => navigate("/community")}
        >
          {t("communityDetail.buttons.backToCommunity")}
        </button>
      </div>
    );
  }

  const userAge: number | null = memberDetails.birth_year
    ? new Date().getFullYear() - parseInt(memberDetails.birth_year)
    : null;

  const memberSince: string = new Date(
    memberDetails.createdAt
  ).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
  });

  const isUserFollowing: boolean = memberDetails.followers.includes(
    userId || ""
  );

  // Helper function to get first name safely
  const getFirstName = (fullName: string | undefined): string => {
    if (!fullName || typeof fullName !== "string") return "User";
    const parts = fullName.trim().split(" ");
    return parts[0] || "User";
  };

  const firstName = getFirstName(memberDetails.name);

  // Online status
  const isOnline = memberDetails.isOnline || false;
  const lastActiveDate = memberDetails.lastActive || memberDetails.lastSeen;

  // Format last seen time
  const formatLastSeen = (dateString: string | undefined): string => {
    if (!dateString) return t("communityDetail.profile.recentlyActive");
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return t("communityDetail.profile.justNow");
    if (diffMins < 60) return t("communityDetail.profile.minutesAgo", { count: diffMins });
    if (diffHours < 24) return t("communityDetail.profile.hoursAgo", { count: diffHours });
    if (diffDays < 7) return t("communityDetail.profile.daysAgo", { count: diffDays });
    return date.toLocaleDateString();
  };

  return (
    <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
      <div className="bg-white border-bottom ">
        <div className="container py-3">
          <button
            className="btn btn-link text-decoration-none p-0 d-flex align-items-center gap-2"
            onClick={() => navigate("/communities")}
          >
            <span className="fs-5">←</span>
            <span className="">{t("communityDetail.buttons.backToCommunity")}</span>
          </button>
        </div>
      </div>

      <div className="container py-4">
        <div className="row g-4">
          <div className="col-lg-4">
            <div className="bg-white rounded-4 p-4 shadow-sm h-100">
              <ImageGallery
                images={memberDetails.imageUrls || []}
                userName={memberDetails.name || "User"}
              />
              <div className="row g-2 my-4">
                <div className="col-6">
                  <StatsCard
                    value={memberDetails.followers?.length || 0}
                    label={t("communityDetail.stats.followers")}
                  />
                </div>
                <div className="col-6">
                  <StatsCard
                    value={memberDetails.following?.length || 0}
                    label={t("communityDetail.stats.following")}
                  />
                </div>
              </div>

              {/* Action Buttons */}
              <div className="d-grid gap-2">
                {userId !== memberDetails._id && (
                  <>
                    {isUserFollowing ? (
                      <ActionButton
                        icon="✓"
                        label={t("communityDetail.buttons.following")}
                        variant="following"
                        onClick={() => handleUnfollow(memberDetails._id)}
                        isLoading={isUnfollowing}
                      />
                    ) : (
                      <ActionButton
                        icon="+"
                        label={t("communityDetail.buttons.follow")}
                        variant="primary"
                        onClick={() => handleFollow(memberDetails._id)}
                        isLoading={isFollowing}
                      />
                    )}

                    <ActionButton
                      icon="💬"
                      label={t("communityDetail.buttons.startChat")}
                      variant="success"
                      onClick={() => handleStartChat(memberDetails._id)}
                      isLoading={isCreatingChat}
                    />

                    <ActionButton
                      icon="📞"
                      label={t("communityDetail.buttons.videoCall")}
                      variant="warning"
                      onClick={() =>
                        handleCallUser(memberDetails.name || "User")
                      }
                    />
                  </>
                )}
              </div>
            </div>
          </div>

          {/* Right Column - Profile Details */}
          <div className="col-lg-8">
            <div className="bg-white rounded-4 p-4 shadow-sm">
              {/* Header */}
              <div className="mb-4">
                <div className="d-flex align-items-baseline flex-wrap gap-3 mb-3">
                  <h1 className="display-6 fw-bold mb-0">
                    {memberDetails.name || "User"}
                  </h1>
                  {userAge && (
                    <span className="badge bg-light text-dark fs-6 fw-normal">
                      {t("communityDetail.profile.yearsOld", { age: userAge })}
                    </span>
                  )}
                  {memberDetails.gender && (
                    <span className="badge bg-light text-dark fs-6 fw-normal">
                      {memberDetails.gender}
                    </span>
                  )}
                </div>
                {memberDetails.username && (
                  <p className="text-muted mb-2">
                    @{memberDetails.username}
                  </p>
                )}

                {/* Online Status */}
                <div className="d-flex align-items-center gap-3 mb-3">
                  <div className="d-flex align-items-center gap-2">
                    <span
                      className="rounded-circle"
                      style={{
                        width: "10px",
                        height: "10px",
                        backgroundColor: isOnline ? "#22c55e" : "#9ca3af",
                        display: "inline-block",
                      }}
                    />
                    <span className={`fw-medium ${isOnline ? "text-success" : "text-muted"}`}>
                      {isOnline
                        ? t("communityDetail.profile.online")
                        : formatLastSeen(lastActiveDate)}
                    </span>
                  </div>
                </div>

                <div className="small text-muted d-flex align-items-center gap-2">
                  <span>📅</span>
                  <span>{t("communityDetail.profile.memberSince", { date: memberSince })}</span>
                </div>
              </div>

              {/* Languages */}
              <LanguagePair
                nativeLanguage={
                  memberDetails.native_language || t("communityDetail.language.notSpecified")
                }
                learningLanguage={
                  memberDetails.language_to_learn || t("communityDetail.language.notSpecified")
                }
              />

              {/* About Section */}
              <div className="mb-4">
                <h2 className="h5 fw-bold mb-3 d-flex align-items-center gap-2">
                  <span>💭</span>
                  {t("communityDetail.profile.aboutUser", { name: firstName })}
                </h2>
                <div className="bg-light rounded-3 p-4">
                  <p className="mb-0 lh-lg">
                    {memberDetails.bio && memberDetails.bio.trim()
                      ? memberDetails.bio
                      : t("communityDetail.profile.noBio", { name: firstName })}
                  </p>
                </div>
              </div>

              {/* Call to Action */}
              {userId !== memberDetails._id && (
                <div className="bg-primary bg-opacity-10 rounded-4 p-4 text-center border border-primary border-opacity-25">
                  <div className="mb-3">
                    <span className="fs-2">🌟</span>
                  </div>
                  <h3 className="h5 fw-bold text-primary mb-2">
                    {t("communityDetail.profile.readyToPractice", { name: firstName })}
                  </h3>
                  <p className="text-muted mb-3">
                    {t("communityDetail.profile.practiceDescription")}
                  </p>
                  <ActionButton
                    icon="💬"
                    label={t("communityDetail.buttons.startConversation")}
                    variant="primary"
                    size="lg"
                    onClick={() => handleStartChat(memberDetails._id)}
                    isLoading={isCreatingChat}
                  />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CommunityDetail;