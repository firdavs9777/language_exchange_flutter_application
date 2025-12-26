import ISO6391 from 'iso-639-1';
import React, {
  ChangeEvent,
  FormEvent,
  useEffect,
  useRef,
  useState,
} from "react";
import { useTranslation } from 'react-i18next';
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { Bounce, toast } from "react-toastify";
import {
  useCreateMomentMutation,
  useUploadMomentPhotosMutation,
} from "../../store/slices/momentsSlice";

import {
  FaArrowLeft,
  FaChevronDown,
  FaGlobe,
  FaImage,
  FaLock,
  FaMapMarkerAlt,
  FaSmile,
  FaTag,
  FaTimes,
  FaUsers
} from "react-icons/fa";

interface Moment {
  success: string;
  data: {
    _id: string;
    title: string;
    description: string;
    user: string;
    comments: string[];
    likeCount: number;
    likedUsers: string[];
    slug: string;
    location: { location: string };
    images: string[];
    createdAt: string;
    updatedAt: string;
  };
}

interface LocationData {
  formattedAddress?: string;
  type: "Point";
  coordinates: [number, number]; // [lng, lat]
}

const CreateMoment: React.FC = () => {
  const navigate = useNavigate();
  const [createMoment] = useCreateMomentMutation();
  const [uploadMomentPhotos] = useUploadMomentPhotosMutation();
  const { t } = useTranslation();

  // Basic form state
  const [title, setTitle] = useState<string>("");
  const [description, setDescription] = useState<string>("");
  const [selectedImages, setSelectedImages] = useState<File[]>([]);
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [isButtonEnabled, setIsButtonEnabled] = useState<boolean>(false);

  // Enhanced features state
  const [location, setLocation] = useState<LocationData | null>(null);
  const [mood, setMood] = useState<string>("");
  const [tags, setTags] = useState<string[]>([]);
  const [currentTag, setCurrentTag] = useState<string>("");
  const [privacy, setPrivacy] = useState<string>("public");
  const [language, setLanguage] = useState<string>("en");
  const [category, setCategory] = useState<string>("general");
  const [scheduledDate, setScheduledDate] = useState<string>("");

  // UI state
  const [showOptions, setShowOptions] = useState<boolean>(false);
  const [showMoodSelector, setShowMoodSelector] = useState<boolean>(false);
  const [showTagInput, setShowTagInput] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const userInfo = useSelector((state: any) => state.auth.userInfo?.user);
  const user = userInfo?._id;

  // Generate language options using ISO6391
  const languageOptions = ISO6391.getAllCodes().map((code) => ({
    value: code,
    label: ISO6391.getName(code),
    nativeName: ISO6391.getNativeName(code)
  }));

  const moods = [
    { value: "happy", label: "Happy", emoji: "😊" },
    { value: "excited", label: "Excited", emoji: "🎉" },
    { value: "grateful", label: "Grateful", emoji: "🙏" },
    { value: "motivated", label: "Motivated", emoji: "💪" },
    { value: "relaxed", label: "Relaxed", emoji: "😌" },
    { value: "curious", label: "Curious", emoji: "🤔" },
  ];

  const categories = [
    { value: "general", label: "General", emoji: "💬" },
    { value: "language-learning", label: "Language Learning", emoji: "📚" },
    { value: "culture", label: "Culture", emoji: "🌍" },
    { value: "food", label: "Food & Cooking", emoji: "🍳" },
    { value: "travel", label: "Travel", emoji: "✈️" },
    { value: "music", label: "Music", emoji: "🎵" },
    { value: "books", label: "Books & Literature", emoji: "📖" },
    { value: "hobbies", label: "Hobbies", emoji: "🎨" },
  ];

  useEffect(() => {
    setIsButtonEnabled(description.trim() !== "");
  }, [description]);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${textareaRef.current.scrollHeight}px`;
    }
  }, [description]);

  const handleImageUpload = (event: ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    if (files.length + selectedImages.length > 10) {
      toast.error("Maximum 10 images allowed", {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }
    setSelectedImages((prevImages) => [...prevImages, ...files]);

    const newPreviews = files.map((file) => URL.createObjectURL(file));
    setImagePreviews((prevPreviews) => [...prevPreviews, ...newPreviews]);
  };

  const handleRemoveImage = (index: number) => {
    setSelectedImages((prevImages) => prevImages.filter((_, i) => i !== index));
    setImagePreviews((prevPreviews) =>
      prevPreviews.filter((_, i) => i !== index)
    );
    URL.revokeObjectURL(imagePreviews[index]);
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!isButtonEnabled || isSubmitting) return;

    setIsSubmitting(true);

    try {
      const response = await createMoment({
        title,
        description,
        user,
        location,
        mood,
        tags,
        privacy,
        language,
        category,
        scheduledDate,
      }).unwrap();

      const newMoment = response as Moment;

      if (selectedImages.length > 0 && newMoment.data._id) {
        const formData = new FormData();
        selectedImages.forEach((file) => {
          formData.append("file", file);
        });

        await uploadMomentPhotos({
          momentId: newMoment.data._id,
          imageFiles: formData,
        }).unwrap();
      }

      toast.success(t("createMoment.toast.createSuccess"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      navigate("/moments");
    } catch (error) {
      toast.error(t("createMoment.toast.createError"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleAddTag = () => {
    if (currentTag.trim() && !tags.includes(currentTag.trim()) && tags.length < 5) {
      setTags([...tags, currentTag.trim()]);
      setCurrentTag("");
    } else if (tags.length >= 5) {
      toast.warn("Maximum 5 tags allowed", { autoClose: 2000 });
    }
  };

  const getCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const lat = position.coords.latitude;
          const lng = position.coords.longitude;

          try {
            const res = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`
            );
            const data = await res.json();

            const address = data.address;
            const city = address.city || address.town || address.village || "";
            const country = address.country || "";

            setLocation({
              formattedAddress: `${city}, ${country}`,
              type: "Point",
              coordinates: [lng, lat],
            });

            toast.success("Location added!", { autoClose: 2000 });
          } catch (err) {
            toast.error("Could not fetch address", { autoClose: 2000 });
          }
        },
        () => toast.error("Could not get location", { autoClose: 2000 })
      );
    }
  };

  const getPrivacyLabel = () => {
    switch (privacy) {
      case 'public': return { icon: <FaGlobe />, label: 'Public' };
      case 'friends': return { icon: <FaUsers />, label: 'Friends' };
      case 'private': return { icon: <FaLock />, label: 'Only me' };
      default: return { icon: <FaGlobe />, label: 'Public' };
    }
  };

  const selectedMood = moods.find(m => m.value === mood);
  const selectedCategory = categories.find(c => c.value === category);
  const selectedLanguage = languageOptions.find(l => l.value === language);

  useEffect(() => {
    return () => {
      imagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
    };
  }, [imagePreviews]);

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <div className="bg-white shadow-sm border-b sticky top-0 z-50">
        <div className="max-w-2xl mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button
                onClick={() => navigate(-1)}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <FaArrowLeft className="w-5 h-5 text-gray-600" />
              </button>
              <h1 className="text-xl font-semibold text-gray-900">Create moment</h1>
            </div>
            <button
              onClick={handleSubmit}
              disabled={!isButtonEnabled || isSubmitting}
              className={`px-6 py-2 rounded-full font-medium text-sm transition-all ${
                isButtonEnabled && !isSubmitting
                  ? 'bg-blue-500 hover:bg-blue-600 text-white'
                  : 'bg-gray-200 text-gray-400 cursor-not-allowed'
              }`}
            >
              {isSubmitting ? 'Sharing...' : 'Share'}
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-2xl mx-auto p-4">
        {/* User Info */}
        <div className="bg-white rounded-lg shadow-sm mb-4">
          <div className="p-4">
            <div className="flex items-center gap-3 mb-4">
              <img
                src={userInfo?.imageUrls?.[0] || "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face"}
                alt="Profile"
                className="w-10 h-10 rounded-full object-cover"
              />
              <div className="flex-1">
                <div className="font-medium text-gray-900">{userInfo?.name || "User"}</div>
                <button
                  onClick={() => setShowOptions(!showOptions)}
                  className="flex items-center gap-1 text-sm text-gray-600 hover:bg-gray-100 px-2 py-1 rounded transition-colors"
                >
                  {getPrivacyLabel().icon}
                  <span>{getPrivacyLabel().label}</span>
                  <FaChevronDown className="w-3 h-3" />
                </button>
              </div>
            </div>

            {/* Privacy Dropdown */}
            {showOptions && (
              <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                <div className="grid grid-cols-3 gap-2 mb-3">
                  {[
                    { value: 'public', icon: <FaGlobe />, label: 'Public' },
                    { value: 'friends', icon: <FaUsers />, label: 'Friends' },
                    { value: 'private', icon: <FaLock />, label: 'Only me' }
                  ].map((option) => (
                    <button
                      key={option.value}
                      onClick={() => setPrivacy(option.value)}
                      className={`p-3 rounded-lg flex flex-col items-center gap-2 text-sm transition-colors ${
                        privacy === option.value ? 'bg-blue-100 text-blue-600' : 'hover:bg-gray-100'
                      }`}
                    >
                      {option.icon}
                      {option.label}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Content Input */}
            <div className="w-full bg-white border border-gray-300 rounded-lg p-4 space-y-3">
              {/* Title input */}
              <input
                type="text"
                placeholder="Add a title..."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full border-b border-gray-300 outline-none text-lg font-semibold placeholder-gray-500 pb-2"
                maxLength={100}
              />
              <div className="text-right text-xs text-gray-400">
                {title.length}/100
              </div>

              {/* Main textarea */}
              <textarea
                ref={textareaRef}
                placeholder={`What's on your mind, ${userInfo?.name?.split(' ')[0] || 'there'}?`}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full border-none outline-none resize-none text-lg placeholder-gray-500 min-h-[120px]"
                maxLength={2000}
              />

              {/* Character count */}
              <div className="text-right text-xs text-gray-400">
                {description.length}/2000
              </div>
            </div>

            {/* Image Previews */}
            {imagePreviews.length > 0 && (
              <div className="mt-4">
                <div className="grid grid-cols-2 gap-2">
                  {imagePreviews.map((preview, index) => (
                    <div key={index} className="relative group">
                      <img
                        src={preview}
                        alt={`Preview ${index + 1}`}
                        className="w-full h-48 object-cover rounded-lg"
                      />
                      <button
                        onClick={() => handleRemoveImage(index)}
                        className="absolute top-2 right-2 w-8 h-8 bg-black bg-opacity-50 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <FaTimes className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Selected enhancements */}
            {(selectedMood || location || tags.length > 0 || selectedCategory?.value !== 'general' || selectedLanguage?.value !== 'en') && (
              <div className="mt-4 flex flex-wrap gap-2">
                {selectedMood && (
                  <span className="inline-flex items-center gap-1 px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm">
                    {selectedMood.emoji} Feeling {selectedMood.label}
                    <button onClick={() => setMood("")} className="ml-1 hover:text-yellow-900">
                      <FaTimes className="w-3 h-3" />
                    </button>
                  </span>
                )}
                {location && (
                  <span className="inline-flex items-center gap-1 px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm">
                    📍 {location.formattedAddress}
                    <button onClick={() => setLocation(null)} className="ml-1 hover:text-green-900">
                      <FaTimes className="w-3 h-3" />
                    </button>
                  </span>
                )}
                {selectedCategory?.value !== 'general' && (
                  <span className="inline-flex items-center gap-1 px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm">
                    {selectedCategory?.emoji} {selectedCategory?.label}
                  </span>
                )}
                {selectedLanguage?.value !== 'en' && (
                  <span className="inline-flex items-center gap-1 px-3 py-1 bg-indigo-100 text-indigo-800 rounded-full text-sm">
                    🌐 {selectedLanguage?.label}
                  </span>
                )}
                {tags.map((tag) => (
                  <span key={tag} className="inline-flex items-center gap-1 px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
                    #{tag}
                    <button
                      onClick={() => setTags(tags.filter(t => t !== tag))}
                      className="ml-1 hover:text-blue-900"
                    >
                      <FaTimes className="w-3 h-3" />
                    </button>
                  </span>
                ))}
              </div>
            )}
          </div>

          {/* Action Bar */}
          <div className="border-t p-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Add to your moment</span>
              <div className="flex items-center gap-2 relative">
                {/* Photo Button */}
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                  title="Add photos"
                >
                  <FaImage className="w-6 h-6 text-green-500" />
                </button>

                {/* Mood Button */}
                <div className="relative">
                  <button
                    onClick={() => setShowMoodSelector(!showMoodSelector)}
                    className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                    title="Add mood"
                  >
                    <FaSmile className="w-6 h-6 text-yellow-500" />
                  </button>

                  {/* Mood Selector Dropdown */}
                  {showMoodSelector && (
                    <div className="absolute bottom-12 right-0 bg-white border rounded-lg shadow-lg p-3 z-50 min-w-48">
                      <div className="text-sm font-medium mb-2">How are you feeling?</div>
                      <div className="grid grid-cols-2 gap-2">
                        {moods.map((moodOption) => (
                          <button
                            key={moodOption.value}
                            onClick={() => {
                              setMood(moodOption.value);
                              setShowMoodSelector(false);
                            }}
                            className="flex items-center gap-2 p-2 hover:bg-gray-100 rounded text-left"
                          >
                            <span>{moodOption.emoji}</span>
                            <span className="text-sm">{moodOption.label}</span>
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* Location Button */}
                <button
                  onClick={getCurrentLocation}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                  title="Add location"
                >
                  <FaMapMarkerAlt className="w-6 h-6 text-red-500" />
                </button>

                {/* Tag Button */}
                <button
                  onClick={() => setShowTagInput(!showTagInput)}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                  title="Add tags"
                >
                  <FaTag className="w-6 h-6 text-blue-500" />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Options */}
        <div className="bg-white rounded-lg shadow-sm p-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Category</label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {categories.map(cat => (
                  <option key={cat.value} value={cat.value}>
                    {cat.emoji} {cat.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Language</label>
              <select
                value={language}
                onChange={(e) => setLanguage(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {languageOptions.map(lang => (
                  <option key={lang.value} value={lang.value}>
                    {lang.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Tag Input */}
          {(showTagInput || tags.length > 0) && (
            <div className="mt-4">
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Add a tag..."
                  value={currentTag}
                  onChange={(e) => setCurrentTag(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
                  className="flex-1 p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  maxLength={20}
                />
                <button
                  onClick={handleAddTag}
                  disabled={!currentTag.trim() || tags.length >= 5}
                  className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Add
                </button>
              </div>
              <div className="text-xs text-gray-500 mt-1">
                {tags.length}/5 tags used
              </div>
            </div>
          )}

          {/* Schedule Option */}
          <div className="mt-4">
            <label className="block text-sm font-medium text-gray-700 mb-1">Schedule (optional)</label>
            <input
              type="datetime-local"
              value={scheduledDate}
              onChange={(e) => setScheduledDate(e.target.value)}
              min={new Date().toISOString().slice(0, 16)}
              className="w-full p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept="image/*"
          onChange={handleImageUpload}
          className="hidden"
        />
      </div>
    </div>
  );
};

export default CreateMoment;
