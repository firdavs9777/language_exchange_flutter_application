import React, {
  useState,
  useEffect,
  useRef,
  ChangeEvent,
  FormEvent,
} from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from 'react-i18next';
import { Bounce, toast } from "react-toastify";
import { useSelector } from "react-redux";
import {
  FaTimes,
  FaPlus,
  FaMapMarkerAlt,
  FaSmile,
  FaTag,
  FaGlobe,
  FaUsers,
  FaLock,
  FaChevronDown,
  FaImage,
  FaArrowLeft
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
  coordinates?: {
    lat: number;
    lng: number;
  };
}

const CreateMoment: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

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
  const [language, setLanguage] = useState<string>("english");
  const [category, setCategory] = useState<string>("general");
  const [scheduledDate, setScheduledDate] = useState<string>("");

  // UI state
  const [showOptions, setShowOptions] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const user = useSelector((state: any) => state.auth.userInfo?.user);

  // Mock mutation hooks - replace with your actual hooks
  const [createMoment] = [() => Promise.resolve({ data: { _id: '123' } })];
  const [uploadMomentPhotos] = [() => Promise.resolve()];

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

  const languages = [
    { value: "english", label: "English", flag: "🇺🇸" },
    { value: "spanish", label: "Spanish", flag: "🇪🇸" },
    { value: "french", label: "French", flag: "🇫🇷" },
    { value: "german", label: "German", flag: "🇩🇪" },
    { value: "korean", label: "Korean", flag: "🇰🇷" },
    { value: "japanese", label: "Japanese", flag: "🇯🇵" },
    { value: "chinese", label: "Chinese", flag: "🇨🇳" },
  ];

  useEffect(() => {
    setIsButtonEnabled(description.trim() !== "");
  }, [description]);

  // Auto-resize textarea
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${textareaRef.current.scrollHeight}px`;
    }
  }, [description]);

  const handleImageUpload = (event: ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    if (files.length + selectedImages.length > 10) {
      toast.error("Maximum 10 images allowed", { autoClose: 3000 });
      return;
    }
    setSelectedImages((prev) => [...prev, ...files]);
    const newPreviews = files.map((file) => URL.createObjectURL(file));
    setImagePreviews((prev) => [...prev, ...newPreviews]);
  };

  const handleRemoveImage = (index: number) => {
    URL.revokeObjectURL(imagePreviews[index]);
    setSelectedImages((prev) => prev.filter((_, i) => i !== index));
    setImagePreviews((prev) => prev.filter((_, i) => i !== index));
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
        (position) => {
          setLocation({
            formattedAddress: "Current Location",
            coordinates: {
              lat: position.coords.latitude,
              lng: position.coords.longitude,
            },
          });
          toast.success("Location added!", { autoClose: 2000 });
        },
        () => toast.error("Could not get location", { autoClose: 2000 })
      );
    }
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!isButtonEnabled) return;

    setIsSubmitting(true);
    try {
      const momentData = {
        title: title || undefined,
        description,
        user: user?._id,
        mood: mood || undefined,
        tags: tags.length > 0 ? tags : undefined,
        category,
        language,
        privacy,
        location: location ? {
          type: "Point",
          coordinates: location.coordinates ? [location.coordinates.lng, location.coordinates.lat] : undefined,
          formattedAddress: location.formattedAddress
        } : undefined,
        scheduledFor: scheduledDate || undefined,
      };

      // Remove undefined fields
      Object.keys(momentData).forEach(key => {
        if (momentData[key as keyof typeof momentData] === undefined) {
          delete momentData[key as keyof typeof momentData];
        }
      });

      // const response = await createMoment(momentData).unwrap();
      const response = { data: { _id: '123' } };

      if (selectedImages.length > 0) {
        const formData = new FormData();
        selectedImages.forEach((file) => formData.append("file", file));
        // await uploadMomentPhotos({ momentId: response.data._id, imageFiles: formData }).unwrap();
      }

      toast.success("Moment shared successfully!", { autoClose: 3000 });
      navigate("/moments");
    } catch (error) {
      toast.error("Failed to share moment", { autoClose: 3000 });
    } finally {
      setIsSubmitting(false);
    }
  };

  const getPrivacyLabel = () => {
    switch(privacy) {
      case 'public': return { icon: <FaGlobe />, label: 'Public' };
      case 'friends': return { icon: <FaUsers />, label: 'Friends' };
      case 'private': return { icon: <FaLock />, label: 'Only me' };
      default: return { icon: <FaGlobe />, label: 'Public' };
    }
  };

  const selectedMood = moods.find(m => m.value === mood);
  const selectedCategory = categories.find(c => c.value === category);
  const selectedLanguage = languages.find(l => l.value === language);

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
                src={user?.imageUrls?.[0] || "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face"}
                alt="Profile"
                className="w-10 h-10 rounded-full object-cover"
              />
              <div className="flex-1">
                <div className="font-medium text-gray-900">{user?.name || "User"}</div>
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

            {/* Main textarea */}
            <textarea
              ref={textareaRef}
              placeholder={`What's on your mind, ${user?.name?.split(' ')[0] || 'there'}?`}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full border-none outline-none resize-none text-lg placeholder-gray-500 min-h-[120px]"
              maxLength={2000}
            />

            {/* Character count */}
            <div className="text-right text-xs text-gray-400 mt-2">
              {description.length}/2000
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
            {(selectedMood || location || tags.length > 0 || selectedCategory?.value !== 'general') && (
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
              <div className="flex items-center gap-2">
                {/* Photo Button */}
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                  title="Add photos"
                >
                  <FaImage className="w-6 h-6 text-green-500" />
                </button>

                {/* Mood Button */}
                <button
                  onClick={() => {/* Add mood selector modal */}}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                  title="Add mood"
                >
                  <FaSmile className="w-6 h-6 text-yellow-500" />
                </button>

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
                  onClick={() => {/* Add tag input modal */}}
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
                {languages.map(lang => (
                  <option key={lang.value} value={lang.value}>
                    {lang.flag} {lang.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Tag Input */}
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
