import React, { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import { useTranslation } from "react-i18next";
import {
  useGetUserProfileQuery,
  useUploadUserPhotoMutation,
  useUpdateUserInfoMutation,
  useDeleteUserPhotoMutation,
} from "../../store/slices/usersSlice";
import { setCredentials } from "../../store/slices/authSlice";
import { RootState } from "../../store";
import { Bounce, toast } from "react-toastify";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import ISO6391 from "iso-639-1";
import {
  ArrowLeft,
  Camera,
  User,
  Mail,
  Calendar,
  Globe,
  BookOpen,
  FileText,
  Save,
  Loader2,
  X,
  Plus,
  Trash2,
} from "lucide-react";

interface UserProfileData {
  _id: string;
  name: string;
  username: string;
  gender: string;
  email: string;
  bio: string;
  birth_year: string;
  birth_month: string;
  birth_day: string;
  native_language: string;
  language_to_learn: string;
  imageUrls: string[];
  mbti: string;
  bloodType: string;
  topics: string[];
}

// MBTI Types
const MBTI_TYPES = [
  "INTJ", "INTP", "ENTJ", "ENTP",
  "INFJ", "INFP", "ENFJ", "ENFP",
  "ISTJ", "ISFJ", "ESTJ", "ESFJ",
  "ISTP", "ISFP", "ESTP", "ESFP",
];

// Blood Types
const BLOOD_TYPES = ["A", "B", "AB", "O"];

// Topic Options
const TOPIC_OPTIONS = [
  "music", "movies", "travel", "sports", "gaming",
  "food", "art", "photography", "reading", "fitness",
  "technology", "fashion", "cooking", "nature", "pets",
  "anime", "kpop", "kdrama", "languages", "culture",
];

const EditProfile: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const userId = useSelector((state: RootState) => state.auth.userInfo?.user?._id);

  // API
  const { data, isLoading, refetch } = useGetUserProfileQuery({});
  const [uploadUserPhoto, { isLoading: isUploading }] = useUploadUserPhotoMutation();
  const [updateUserProfile, { isLoading: isSaving }] = useUpdateUserInfoMutation();
  const [deleteUserPhoto] = useDeleteUserPhotoMutation();

  // State
  const [formData, setFormData] = useState<UserProfileData>({
    _id: "",
    name: "",
    username: "",
    gender: "",
    email: "",
    bio: "",
    birth_year: "",
    birth_month: "",
    birth_day: "",
    native_language: "",
    language_to_learn: "",
    imageUrls: [],
    mbti: "",
    bloodType: "",
    topics: [],
  });
  const [birthDate, setBirthDate] = useState<Date | null>(null);
  const [hasChanges, setHasChanges] = useState(false);

  // Language options
  const languageOptions = React.useMemo(() => {
    return ISO6391.getAllCodes().map((code) => ({
      value: code,
      label: ISO6391.getName(code),
    }));
  }, []);

  // Initialize form
  useEffect(() => {
    if (data?.data) {
      setFormData({
        _id: data.data._id || "",
        name: data.data.name || "",
        username: data.data.username || "",
        gender: data.data.gender || "",
        email: data.data.email || "",
        bio: data.data.bio || "",
        birth_year: data.data.birth_year || "",
        birth_month: data.data.birth_month || "",
        birth_day: data.data.birth_day || "",
        native_language: data.data.native_language || "",
        language_to_learn: data.data.language_to_learn || "",
        imageUrls: data.data.imageUrls || [],
        mbti: data.data.mbti || "",
        bloodType: data.data.bloodType || "",
        topics: data.data.topics || [],
      });

      // Set birth date
      if (data.data.birth_year && data.data.birth_month && data.data.birth_day) {
        const year = parseInt(data.data.birth_year);
        const month = parseInt(data.data.birth_month) - 1;
        const day = parseInt(data.data.birth_day);
        if (!isNaN(year) && !isNaN(month) && !isNaN(day)) {
          setBirthDate(new Date(year, month, day));
        }
      }
    }
  }, [data]);

  // Handlers
  const handleInputChange = useCallback((
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    setHasChanges(true);
  }, []);

  const handleBirthDateChange = useCallback((date: Date | null) => {
    if (date) {
      setBirthDate(date);
      setFormData((prev) => ({
        ...prev,
        birth_year: String(date.getFullYear()),
        birth_month: String(date.getMonth() + 1),
        birth_day: String(date.getDate()),
      }));
      setHasChanges(true);
    }
  }, []);

  const handleTopicToggle = useCallback((topic: string) => {
    setFormData((prev) => {
      const newTopics = prev.topics.includes(topic)
        ? prev.topics.filter((t) => t !== topic)
        : [...prev.topics, topic];
      return { ...prev, topics: newTopics };
    });
    setHasChanges(true);
  }, []);

  const handleSave = async () => {
    try {
      // Ensure gender is lowercase for backend validation
      const dataToSave = {
        ...formData,
        gender: formData.gender?.toLowerCase() || "",
      };
      const result = await updateUserProfile(dataToSave).unwrap();
      dispatch(setCredentials({ ...result }));
      toast.success(t("profile.messages.profile_update_success") || "Profile updated successfully", {
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setHasChanges(false);
      navigate("/profile");
    } catch (error: any) {
      toast.error(
        t("profile.messages.profile_update_failure") || "Failed to update profile",
        { autoClose: 3000, theme: "dark", transition: Bounce }
      );
    }
  };

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0 || !userId) return;

    try {
      const formDataUpload = new FormData();
      Array.from(files).forEach((file) => formDataUpload.append("photo", file));

      const result = await uploadUserPhoto({
        userId,
        imageFiles: formDataUpload,
      }).unwrap();

      dispatch(setCredentials({ ...result }));
      refetch();
      toast.success(t("profile.messages.image_update_success") || "Photo uploaded", {
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
    } catch (error: any) {
      toast.error(t("profile.messages.image_update_failure") || "Failed to upload photo", {
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleDeletePhoto = async (index: number) => {
    if (!userId) return;

    try {
      const result = await deleteUserPhoto({ userId, index }).unwrap();
      dispatch(setCredentials({ ...result }));
      refetch();
      toast.success(t("profile.messages.image_delete_success") || "Photo deleted", {
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
    } catch (error: any) {
      toast.error(t("profile.messages.image_delete_failure") || "Failed to delete photo", {
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-yellow-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 text-teal-500 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-yellow-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-500 to-teal-600 text-white p-4 sticky top-0 z-10">
        <div className="max-w-2xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-white/10 rounded-full transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <h1 className="text-lg font-semibold">
              {t("profile.edit_profile") || "Edit Profile"}
            </h1>
          </div>
          <button
            onClick={handleSave}
            disabled={!hasChanges || isSaving}
            className={`px-4 py-2 rounded-lg font-medium transition-all flex items-center gap-2 ${
              hasChanges
                ? "bg-white text-teal-600 hover:bg-teal-50"
                : "bg-white/30 text-white/70 cursor-not-allowed"
            }`}
          >
            {isSaving ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Save className="w-4 h-4" />
            )}
            {t("profile.actions.save") || "Save"}
          </button>
        </div>
      </div>

      <div className="max-w-2xl mx-auto p-4 pb-20">
        {/* Photos Section */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 mb-4">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
            {t("profile.photos") || "Photos"}
          </h3>
          <div className="grid grid-cols-3 gap-3">
            {formData.imageUrls.map((url, index) => (
              <div key={index} className="relative aspect-square rounded-xl overflow-hidden group">
                <img
                  src={url}
                  alt={`Photo ${index + 1}`}
                  className="w-full h-full object-cover"
                />
                <button
                  onClick={() => handleDeletePhoto(index)}
                  className="absolute top-2 right-2 p-1.5 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
            {formData.imageUrls.length < 6 && (
              <label className="aspect-square rounded-xl border-2 border-dashed border-gray-300 flex flex-col items-center justify-center cursor-pointer hover:border-teal-400 hover:bg-teal-50/50 transition-colors">
                <input
                  type="file"
                  accept="image/*"
                  multiple
                  onChange={handlePhotoUpload}
                  className="hidden"
                />
                {isUploading ? (
                  <Loader2 className="w-6 h-6 text-teal-500 animate-spin" />
                ) : (
                  <>
                    <Plus className="w-6 h-6 text-gray-400" />
                    <span className="text-xs text-gray-400 mt-1">Add Photo</span>
                  </>
                )}
              </label>
            )}
          </div>
        </div>

        {/* Personal Info */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 mb-4">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
            {t("profile.sections.personal_info") || "Personal Information"}
          </h3>

          {/* Name */}
          <div className="mb-4">
            <label className="flex items-center gap-2 text-sm text-gray-600 mb-1">
              <User className="w-4 h-4" />
              {t("profile.labels.name") || "Name"}
            </label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent transition-all"
            />
          </div>

          {/* Username (Read-only) */}
          {formData.username && (
            <div className="mb-4">
              <label className="flex items-center gap-2 text-sm text-gray-600 mb-1">
                <span className="text-gray-400">@</span>
                {t("profile.labels.username") || "Username"}
              </label>
              <input
                type="text"
                value={`@${formData.username}`}
                disabled
                className="w-full px-4 py-3 bg-gray-100 border border-gray-200 rounded-xl text-gray-500 cursor-not-allowed"
              />
              <p className="text-xs text-gray-400 mt-1">
                {t("profile.hints.username_readonly") || "Username cannot be changed"}
              </p>
            </div>
          )}

          {/* Email */}
          <div className="mb-4">
            <label className="flex items-center gap-2 text-sm text-gray-600 mb-1">
              <Mail className="w-4 h-4" />
              {t("profile.labels.email") || "Email"}
            </label>
            <input
              type="email"
              name="email"
              value={formData.email}
              disabled
              className="w-full px-4 py-3 bg-gray-100 border border-gray-200 rounded-xl text-gray-500 cursor-not-allowed"
            />
          </div>

          {/* Gender */}
          <div className="mb-4">
            <label className="text-sm text-gray-600 mb-1 block">
              {t("profile.labels.gender") || "Gender"}
            </label>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => {
                  setFormData((prev) => ({ ...prev, gender: "male" }));
                  setHasChanges(true);
                }}
                className={`flex-1 py-3 rounded-xl font-medium transition-all ${
                  formData.gender?.toLowerCase() === "male"
                    ? "bg-teal-500 text-white"
                    : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                }`}
              >
                {t("profile.options.male") || "Male"}
              </button>
              <button
                type="button"
                onClick={() => {
                  setFormData((prev) => ({ ...prev, gender: "female" }));
                  setHasChanges(true);
                }}
                className={`flex-1 py-3 rounded-xl font-medium transition-all ${
                  formData.gender?.toLowerCase() === "female"
                    ? "bg-pink-500 text-white"
                    : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                }`}
              >
                {t("profile.options.female") || "Female"}
              </button>
            </div>
          </div>

          {/* Birthday */}
          <div className="mb-4">
            <label className="flex items-center gap-2 text-sm text-gray-600 mb-1">
              <Calendar className="w-4 h-4" />
              {t("profile.labels.birthday") || "Birthday"}
            </label>
            <DatePicker
              selected={birthDate}
              onChange={handleBirthDateChange}
              dateFormat="MMMM d, yyyy"
              placeholderText={t("profile.placeholders.select_date") || "Select date"}
              className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent"
              showYearDropdown
              showMonthDropdown
              dropdownMode="select"
              maxDate={new Date()}
            />
          </div>
        </div>

        {/* Bio */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 mb-4">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
            <FileText className="w-4 h-4 inline mr-2" />
            {t("profile.sections.bio") || "Bio"}
          </h3>
          <textarea
            name="bio"
            value={formData.bio}
            onChange={handleInputChange}
            placeholder={t("profile.placeholders.bio") || "Tell us about yourself..."}
            rows={4}
            className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent resize-none"
          />
          <p className="text-xs text-gray-400 mt-1 text-right">
            {formData.bio.length}/500
          </p>
        </div>

        {/* Languages */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 mb-4">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
            {t("profile.sections.languages") || "Languages"}
          </h3>

          {/* Native Language */}
          <div className="mb-4">
            <label className="flex items-center gap-2 text-sm text-gray-600 mb-1">
              <Globe className="w-4 h-4" />
              {t("profile.labels.native_language") || "Native Language"}
            </label>
            <select
              name="native_language"
              value={formData.native_language}
              onChange={handleInputChange}
              className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent appearance-none"
            >
              <option value="">{t("profile.placeholders.select_native_language") || "Select native language"}</option>
              {languageOptions.map((lang) => (
                <option key={lang.value} value={lang.label}>
                  {lang.label}
                </option>
              ))}
            </select>
          </div>

          {/* Learning Language */}
          <div>
            <label className="flex items-center gap-2 text-sm text-gray-600 mb-1">
              <BookOpen className="w-4 h-4" />
              {t("profile.labels.learning") || "Learning"}
            </label>
            <select
              name="language_to_learn"
              value={formData.language_to_learn}
              onChange={handleInputChange}
              className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent appearance-none"
            >
              <option value="">{t("profile.placeholders.select_learning_language") || "Select learning language"}</option>
              {languageOptions.map((lang) => (
                <option key={lang.value} value={lang.label}>
                  {lang.label}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* MBTI & Blood Type */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 mb-4">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
            {t("profile.sections.personality") || "Personality"}
          </h3>

          {/* MBTI */}
          <div className="mb-4">
            <label className="text-sm text-gray-600 mb-2 block">
              {t("profile.labels.mbti") || "MBTI Type"}
            </label>
            <div className="grid grid-cols-4 gap-2">
              {MBTI_TYPES.map((type) => (
                <button
                  key={type}
                  type="button"
                  onClick={() => {
                    setFormData((prev) => ({ ...prev, mbti: type }));
                    setHasChanges(true);
                  }}
                  className={`py-2 px-3 rounded-lg text-sm font-medium transition-all ${
                    formData.mbti === type
                      ? "bg-teal-500 text-white"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                  }`}
                >
                  {type}
                </button>
              ))}
            </div>
            {formData.mbti && (
              <button
                type="button"
                onClick={() => {
                  setFormData((prev) => ({ ...prev, mbti: "" }));
                  setHasChanges(true);
                }}
                className="mt-2 text-xs text-gray-400 hover:text-gray-600"
              >
                {t("profile.actions.clear") || "Clear selection"}
              </button>
            )}
          </div>

          {/* Blood Type */}
          <div>
            <label className="text-sm text-gray-600 mb-2 block">
              {t("profile.labels.blood_type") || "Blood Type"}
            </label>
            <div className="flex gap-3">
              {BLOOD_TYPES.map((type) => (
                <button
                  key={type}
                  type="button"
                  onClick={() => {
                    setFormData((prev) => ({ ...prev, bloodType: type }));
                    setHasChanges(true);
                  }}
                  className={`flex-1 py-3 rounded-xl font-medium transition-all ${
                    formData.bloodType === type
                      ? "bg-red-500 text-white"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                  }`}
                >
                  {type}
                </button>
              ))}
            </div>
            {formData.bloodType && (
              <button
                type="button"
                onClick={() => {
                  setFormData((prev) => ({ ...prev, bloodType: "" }));
                  setHasChanges(true);
                }}
                className="mt-2 text-xs text-gray-400 hover:text-gray-600"
              >
                {t("profile.actions.clear") || "Clear selection"}
              </button>
            )}
          </div>
        </div>

        {/* Topics / Interests */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
            {t("profile.sections.topics") || "Topics & Interests"}
          </h3>
          <p className="text-xs text-gray-400 mb-3">
            {t("profile.labels.topics_hint") || "Select topics you're interested in (max 10)"}
          </p>
          <div className="flex flex-wrap gap-2">
            {TOPIC_OPTIONS.map((topic) => {
              const isSelected = formData.topics.includes(topic);
              const isDisabled = !isSelected && formData.topics.length >= 10;
              return (
                <button
                  key={topic}
                  type="button"
                  onClick={() => !isDisabled && handleTopicToggle(topic)}
                  disabled={isDisabled}
                  className={`px-3 py-2 rounded-full text-sm font-medium transition-all ${
                    isSelected
                      ? "bg-teal-500 text-white"
                      : isDisabled
                      ? "bg-gray-100 text-gray-300 cursor-not-allowed"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                  }`}
                >
                  {t(`profile.topics.${topic}`) || topic}
                </button>
              );
            })}
          </div>
          <p className="text-xs text-gray-400 mt-3 text-right">
            {formData.topics.length}/10 {t("profile.labels.selected") || "selected"}
          </p>
        </div>
      </div>
    </div>
  );
};

export default EditProfile;
