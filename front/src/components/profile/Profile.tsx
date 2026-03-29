import React, { useEffect, useState, useCallback } from "react";
import {
  useGetFollowersQuery,
  useGetFollowingsQuery,
  useGetUserProfileQuery,
  useUploadUserPhotoMutation,
  useUpdateUserInfoMutation,
  useDeleteUserPhotoMutation,
  useGetProfileVisitorsQuery,
  useGetVipStatusQuery,
} from "../../store/slices/usersSlice";
import {
  Button,
  Card,
  Col,
  Container,
  Image,
  Row,
  Form,
  Badge,
  Spinner,
  Alert,
} from "react-bootstrap";
import backgroundImage from "../../assets/profile_background.png";
import {
  FaCameraRetro,
  FaCrown,
  FaEdit,
  FaEye,
  FaLock,
  FaSave,
  FaTimes,
  FaUserCheck,
  FaUserFriends,
} from "react-icons/fa";
import { useSelector } from "react-redux";
import { Link } from "react-router-dom";
import { useGetMyMomentsQuery } from "../../store/slices/momentsSlice";
import { MomentType } from "../moments/types";
import { FollowerInterface, UserProfileData } from "./ProfileTypes/types";
import ImageViewerModal from "./ImageViewer/ImageModal";
import ImageUploaderModal from "./ImageUploader/ImageUploader";
import { Bounce, toast } from "react-toastify";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import ISO6391 from "iso-639-1";
import { useTranslation } from "react-i18next";
import LanguagesView from "./LanguageView";
import InfoRow from "./InfoRow";
import { setCredentials } from "../../store/slices/authSlice";
import { useDispatch } from "react-redux";

interface Moment {
  count: number;
  success: string;
  data: MomentType[];
}


const ProfileScreen: React.FC = () => {
  const { t } = useTranslation();
  const userId = useSelector((state: any) => state.auth.userInfo?.user?._id);
   useEffect(() => {
      window.scrollTo(0, 1);
    }, [userId]);
  // API Queries
  const { data, isLoading, error, refetch } = useGetUserProfileQuery({});
  const { data: followers } = useGetFollowersQuery({ userId });
  const { data: followings } = useGetFollowingsQuery({ userId });
  const { data: moments } = useGetMyMomentsQuery({ userId });
  // VIP Status
  const { data: vipData } = useGetVipStatusQuery(userId || "", {
    skip: !userId,
  });
  const userMode = useSelector((state: any) => state.auth.userInfo?.user?.userMode);
  const isVip = userMode === "vip" || (vipData as any)?.data?.isActive;

  const { data: visitors } = useGetProfileVisitorsQuery(
    { userId: userId || "", page: 1, limit: 1 },
    { skip: !userId || !isVip }
  );
  const [uploadUserPhoto] = useUploadUserPhotoMutation();
  const [updateUserProfile] = useUpdateUserInfoMutation();
  const [deleteUserPhoto] = useDeleteUserPhotoMutation();
    const dispatch = useDispatch();
  

  // State
  const [formData, setFormData] = useState<UserProfileData>({
    _id: "",
    name: "",
    gender: "",
    email: "",
    bio: "",
    birth_year: "",
    birth_month: "",
    birth_day: "",
    image: "",
    native_language: "",
    language_to_learn: "",
    createdAt: "",
    images: [],
    imageUrls: [],
  });
  
  const [birthDate, setBirthDate] = useState<Date | null>(null);
  const [editMode, setEditMode] = useState<"personal" | "bio" | "languages" | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showImageViewer, setShowImageViewer] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);

  // Derived data
  const followersData = followers as FollowerInterface;
  const followingsData = followings as FollowerInterface;
  const momentsData = moments as Moment;

  // Memoized language options
  const languageOptions = React.useMemo(() => {
    return ISO6391.getAllCodes().map((code) => ({
      value: code,
      label: ISO6391.getName(code),
    }));
  }, []);

  // Initialize form data
  useEffect(() => {
    if (data?.data) {
      setFormData(data.data);
      
      // Set birth date if available
      if (data.data.birth_year && data.data.birth_month && data.data.birth_day) {
        const year = parseInt(data.data.birth_year);
        const month = parseInt(data.data.birth_month) - 1; // Month is 0-indexed
        const day = parseInt(data.data.birth_day);

        if (
          !isNaN(year) &&
          !isNaN(month) &&
          !isNaN(day) &&
          month >= 0 &&
          month <= 11 &&
          day >= 1 &&
          day <= 31
        ) {
          setBirthDate(new Date(year, month, day));
        } else {
          setBirthDate(null);
        }
      } else {
        setBirthDate(null);
      }
    }
  }, [data]);

  // Handlers
  const handleUploadImages = useCallback(async (newFiles: File[]) => {
    try {
      const formData = new FormData();
      newFiles.forEach((file) => formData.append("photo", file));

      if (newFiles.length > 0 && userId) {
       const userInfo =  await uploadUserPhoto({
          userId,
          imageFiles: formData,
       }).unwrap();
        const ActionPayload: Response | any = userInfo;
        dispatch(setCredentials({ ...ActionPayload }));
        refetch();
        toast.success(t("profile.messages.image_update_success"));
      }
    } catch (error: any) {
      toast.error(
        `${t("profile.messages.image_update_failure")}: ${error?.error || t("profile.messages.unknown_error")}`
      ,{
                autoClose: 3000,
                hideProgressBar: false,
                theme: "dark",
                transition: Bounce,
              });
    }
  }, [uploadUserPhoto, userId, refetch, t]);

  const handleProfileUpdate = useCallback(async () => {
    try {
      // Ensure gender is lowercase for backend validation
      const dataToSave = {
        ...formData,
        gender: formData.gender?.toLowerCase() || "",
      };
      const userInfo = await updateUserProfile(dataToSave).unwrap();

      const ActionPayload: Response | any = userInfo;
      dispatch(setCredentials({ ...ActionPayload }));
      toast.success(t("profile.messages.profile_update_success"), {
                autoClose: 3000,
                hideProgressBar: false,
                theme: "dark",
                transition: Bounce,
              });
      setEditMode(null);
      
    } catch (error: any) {
      toast.error(
        `${t("profile.messages.profile_update_failure")}: ${error?.error || t("profile.messages.unknown_error")}`
      ,{
                autoClose: 3000,
                hideProgressBar: false,
                theme: "dark",
                transition: Bounce,
              });
    }
  }, [formData, updateUserProfile, refetch, t]);

  const handleBirthDateChange = useCallback((date: Date | null) => {
    if (date) {
      setBirthDate(date);
      setFormData((prev) => ({
        ...prev,
        birth_year: String(date.getFullYear()),
        birth_month: String(date.getMonth() + 1),
        birth_day: String(date.getDate()),
      }));
    } else {
      setBirthDate(null);
      setFormData((prev) => ({
        ...prev,
        birth_year: "",
        birth_month: "",
        birth_day: "",
      }));
    }
  }, []);

  const handleInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
      const { name, value } = e.target;
      setFormData((prev) => ({ ...prev, [name]: value }));
    },
    []
  );

  const handleCancelChanges = useCallback(() => {
    setEditMode(null);
    if (data) {
      setFormData(data.data);
    }
  }, [data]);

  const handleDeletePhoto = useCallback(async (index: number) => {
    if (!userId) return;
    
    try {
      const userInfo = await deleteUserPhoto({ userId, index }).unwrap();
      console.log(userInfo)
      const ActionPayload: Response | any = userInfo;
      dispatch(setCredentials({ ...ActionPayload }));
      toast.success(t("profile.messages.image_delete_success"), {
                autoClose: 3000,
                hideProgressBar: false,
                theme: "dark",
                transition: Bounce,
              });
      refetch();
    } catch (error: any) {
      toast.error(
        `${t("profile.messages.image_delete_failure")}: ${error?.error || t("profile.messages.unknown_error")}`
      );
    }
  }, [deleteUserPhoto, userId, refetch, t]);

  const handleImageClick = useCallback((index: number) => {
    setCurrentImageIndex(index);
    setShowImageViewer(true);
  }, []);

  const getOrdinalSuffix = useCallback((day: string): string => {
    const n = parseInt(day);
    if (isNaN(n)) return day;

    if (n >= 11 && n <= 13) return `${n}th`;
    
    switch (n % 10) {
      case 1: return `${n}st`;
      case 2: return `${n}nd`;
      case 3: return `${n}rd`;
      default: return `${n}th`;
    }
  }, []);

  // Loading and error states
  if (isLoading) {
    return (
      <div className="d-flex justify-content-center align-items-center min-vh-100">
        <Spinner animation="border" variant="primary" />
      </div>
    );
  }

  if (error) {
    return (
      <Alert variant="danger" className="m-3">
        {t("profile.messages.error_loading_profile")}
      </Alert>
    );
  }

  if (!data) {
    return (
      <Alert variant="warning" className="m-3">
        {t("profile.messages.no_profile_data")}
      </Alert>
    );
  }

  return (
    <Container fluid className="px-0">
      {/* Banner Section */}
      <div className="position-relative mb-5" style={{ height: "180px" }}>
        <Image
          src={backgroundImage}
          fluid
          className="w-100 h-100 object-fit-cover"
          alt="Profile background"
        />
        <div className="position-absolute top-50 start-50 translate-middle text-center">
          <h1 className="text-white fw-bold">{t("profile.title")}</h1>
        </div>
      </div>

      {/* Avatar Section */}
      <div className="text-center mb-4" style={{ marginTop: "-60px" }}>
        <div className="position-relative d-inline-block">
          <Image
            src={
              formData.imageUrls?.[0] || 
              "https://via.placeholder.com/150"
            }
            alt="Profile"
            roundedCircle
            className="border border-4 border-white shadow"
            style={{
              width: "120px",
              height: "120px",
              objectFit: "cover",
              cursor: "pointer",
            }}
            onClick={() => handleImageClick(0)}
          />
          <Button
            variant="primary"
            size="sm"
            className="position-absolute bottom-0 end-0 rounded-circle d-flex align-items-center justify-content-center"
            style={{ width: "36px", height: "36px" }}
            onClick={() => setShowModal(true)}
            aria-label={t("profile.actions.edit_photo")}
          >
            <FaEdit />
          </Button>
        </div>
        <h4 className="mt-2 mb-0 fw-bold">{formData.name}</h4>
        <p className="text-muted small">
          @{formData.username || formData.name?.toLowerCase().replace(/\s+/g, "")}
        </p>
      </div>

      {/* Modals */}
      <ImageViewerModal
        show={showImageViewer}
        images={formData.imageUrls || []}
        currentIndex={currentImageIndex}
        onClose={() => setShowImageViewer(false)}
        onSelectImage={setCurrentImageIndex}
      />

      <ImageUploaderModal
        onDeleteImage={handleDeletePhoto}
        images={formData.imageUrls || []}
        show={showModal}
        onClose={() => setShowModal(false)}
        onUploadImages={handleUploadImages}
      />

      {/* Stats Section */}
      <Container className="mb-4">
        <Row className="g-3">
          <Col xs={6} sm={3}>
            <Link to="/followersList" className="text-decoration-none">
              <StatsCard
                icon={<FaUserFriends className="text-primary" size={24} />}
                value={followersData?.count || 0}
                label={t("profile.stats.followers")}
              />
            </Link>
          </Col>

          <Col xs={6} sm={3}>
            <Link to="/followingsList" className="text-decoration-none">
              <StatsCard
                icon={<FaUserCheck className="text-success" size={24} />}
                value={followingsData?.count || 0}
                label={t("profile.stats.following")}
              />
            </Link>
          </Col>

          <Col xs={6} sm={3}>
            <Link to="/my-moments" className="text-decoration-none">
              <StatsCard
                icon={<FaCameraRetro className="text-danger" size={24} />}
                value={momentsData?.count || 0}
                label={t("profile.stats.moments")}
              />
            </Link>
          </Col>

          <Col xs={6} sm={3}>
            <Link to="/visitors" className="text-decoration-none">
              <StatsCard
                icon={isVip ? <FaEye className="text-info" size={24} /> : <FaLock className="text-warning" size={24} />}
                value={isVip ? ((visitors as any)?.count || 0) : "VIP"}
                label={t("profile.stats.visitors")}
              />
            </Link>
          </Col>
        </Row>
      </Container>

      {/* Profile Sections */}
      <Container>
        {/* Personal Information */}
        <ProfileSection
          title={t("profile.sections.personal_info")}
          editMode={editMode === "personal"}
          onEdit={() => setEditMode("personal")}
          onSave={handleProfileUpdate}
          onCancel={handleCancelChanges}
        >
          {editMode === "personal" ? (
            <PersonalInfoForm
              formData={formData}
              onInputChange={handleInputChange}
              birthDate={birthDate}
              onDateChange={handleBirthDateChange}
            />
          ) : (
            <PersonalInfoView
              formData={formData}
              getOrdinalSuffix={getOrdinalSuffix}
            />
          )}
        </ProfileSection>

        {/* Bio Section */}
        <ProfileSection
          title={t("profile.sections.bio")}
          editMode={editMode === "bio"}
          onEdit={() => setEditMode("bio")}
          onSave={handleProfileUpdate}
          onCancel={handleCancelChanges}
        >
          {editMode === "bio" ? (
            <Form.Control
              as="textarea"
              rows={4}
              name="bio"
              value={formData.bio}
              onChange={handleInputChange}
              placeholder={t("profile.placeholders.bio")}
            />
          ) : (
            <p className="mb-0">
              {formData.bio || (
                <span className="text-muted fst-italic">
                  {t("profile.messages.no_bio")}
                </span>
              )}
            </p>
          )}
        </ProfileSection>

        {/* Languages Section */}
        <ProfileSection
          title={t("profile.sections.languages")}
          editMode={editMode === "languages"}
          onEdit={() => setEditMode("languages")}
          onSave={handleProfileUpdate}
          onCancel={handleCancelChanges}
        >
          {editMode === "languages" ? (
            <LanguagesForm
              formData={formData}
              onInputChange={handleInputChange}
              languageOptions={languageOptions}
            />
          ) : (
            <LanguagesView formData={formData} />
          )}
        </ProfileSection>
      </Container>
    </Container>
  );
};

// Sub-components for better organization
const StatsCard: React.FC<{
  icon: React.ReactNode;
  value: number | string;
  label: string;
}> = ({ icon, value, label }) => (
  <Card className="h-100 border-0 shadow-sm hover-shadow transition-all">
    <Card.Body className="d-flex flex-column align-items-center">
      <div className="rounded-circle bg-light p-3 mb-2">{icon}</div>
      <h5 className={`fw-bold mb-0 ${value === "VIP" ? "text-warning" : ""}`}>{value}</h5>
      <p className="text-muted mb-0">{label}</p>
    </Card.Body>
  </Card>
);

const ProfileSection: React.FC<{
  title: string;
  editMode: boolean;
  onEdit: () => void;
  onSave: () => void;
  onCancel: () => void;
  children: React.ReactNode;
}> = ({ title, editMode, onEdit, onSave, onCancel, children }) => {
  const { t } = useTranslation();


  return (<Card className="mb-4 border-0 shadow-sm">
    <Card.Header className="bg-white border-bottom d-flex justify-content-between align-items-center py-3">
      <h5 className="mb-0 fw-bold">{title}</h5>
      {editMode ? (
        <div>
          <Button
            variant="success"
            size="sm"
            className="me-2"
            onClick={onSave}
          >
            <FaSave className="me-1" /> {t("profile.actions.save")}
          </Button>
          <Button
            variant="outline-secondary"
            size="sm"
            onClick={onCancel}
          >
            <FaTimes className="me-1" /> {t("profile.actions.cancel")}
          </Button>
        </div>
      ) : (
        <Button
          variant="outline-primary"
          size="sm"
          onClick={onEdit}
        >
          <FaEdit className="me-1" /> {t("profile.actions.edit")}
        </Button>
      )}
    </Card.Header>
    <Card.Body>{children}</Card.Body>
  </Card>
  );
}

const PersonalInfoForm: React.FC<{
  formData: UserProfileData;
  onInputChange: React.ChangeEventHandler<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>;
  birthDate: Date | null;
  onDateChange: (date: Date | null) => void;
}> = ({ formData, onInputChange, birthDate, onDateChange }) => {
  const { t } = useTranslation();

  return (<Form>
    <Form.Group className="mb-3">
      <Form.Label>{t("profile.labels.name")}</Form.Label>
      <Form.Control
        type="text"
        name="name"
        value={formData.name}
        onChange={onInputChange}
      />
    </Form.Group>
    <Form.Group className="mb-3">
      <Form.Label>{t("profile.labels.email")}</Form.Label>
      <Form.Control
        type="email"
        name="email"
        value={formData.email}
        disabled
        onChange={onInputChange}
      />
    </Form.Group>
    <Form.Group className="mb-3">
      <Form.Label>{t("profile.labels.gender")}</Form.Label>
      <Form.Select
        name="gender"
        value={formData.gender}
        onChange={onInputChange}
      >
        <option value="">{t("profile.placeholders.select_gender")}</option>
        <option value="male">{t("profile.options.male")}</option>
        <option value="female">{t("profile.options.female")}</option>
      </Form.Select>
    </Form.Group>
    <Form.Group className="mb-3">
      <Form.Label>{t("profile.labels.birthday")}</Form.Label>
      <DatePicker
        selected={birthDate}
        onChange={onDateChange}
        dateFormat="dd/MM/yyyy"
        placeholderText={t("profile.placeholders.select_date")}
        className="form-control"
        aria-label={t("profile.labels.birthday")}
      />
    </Form.Group>
  </Form>
  )
}

const PersonalInfoView: React.FC<{
  formData: UserProfileData;
  getOrdinalSuffix: (day: string) => string;
}> = ({ formData, getOrdinalSuffix }) => {
    const { t } = useTranslation();

  return (
    <div className="py-2">
      <InfoRow label={t("profile.labels.name")} value={formData.name} />
      <InfoRow label={t("profile.labels.email")} value={formData.email} />
      <InfoRow
        label={t("profile.labels.gender")}
        value={formData.gender ? (
          <Badge
            bg={formData.gender.toLowerCase() === "male" ? "primary" : "danger"}
            className="fw-normal"
          >
            {formData.gender}
          </Badge>
        ) : (
          t("profile.messages.not_specified")
        )}
      />
      <InfoRow
        label={t("profile.labels.birthday")}
        value={
          formData.birth_day && formData.birth_month && formData.birth_year
            ? `${getOrdinalSuffix(formData.birth_day)} ${t("profile.labels.of")} ${new Date(
              Number(formData.birth_year),
              Number(formData.birth_month) - 1
            ).toLocaleString("en-US", { month: "long" })}, ${formData.birth_year
            }`
            : t("profile.messages.not_specified")
        }
      />
    </div>
  );
}

const LanguagesForm: React.FC<{
  formData: UserProfileData;
  onInputChange: React.ChangeEventHandler<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>;
  languageOptions: { value: string; label: string }[];
}> = ({ formData, onInputChange, languageOptions }) => {
    const { t } = useTranslation();

  return (
    <Form>
      <Form.Group className="mb-3">
        <Form.Label>{t("profile.labels.native_language")}</Form.Label>
        <Form.Select
          name="native_language"
          value={formData.native_language}
          onChange={onInputChange}
          required
        >
          <option value="">{t("profile.placeholders.select_native_language")}</option>
          {languageOptions.map((lang) => (
            <option key={lang.value} value={lang.label}>
              {lang.label}
            </option>
          ))}
        </Form.Select>
      </Form.Group>
      <Form.Group>
        <Form.Label>{t("profile.labels.learning")}</Form.Label>
        <Form.Select
          name="language_to_learn"
          value={formData.language_to_learn}
          onChange={onInputChange}
          required
        >
          <option value="">{t("profile.placeholders.select_learning_language")}</option>
          {languageOptions.map((lang) => (
            <option key={lang.value} value={lang.label}>
              {lang.label}
            </option>
          ))}
        </Form.Select>
      </Form.Group>
    </Form>
  );
}




export default ProfileScreen;