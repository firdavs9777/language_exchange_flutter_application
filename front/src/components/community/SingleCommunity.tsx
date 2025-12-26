import { useState, useEffect } from "react";
import { Heart, MessageCircle, Globe, Trophy, Sparkles, ArrowLeft, Star, MapPin, Calendar, Zap } from "lucide-react";

// Mock type definition - replace with your actual type
interface CommunityMember {
  id: string;
  name: string;
  imageUrls: string[];
  bio?: string;
  native_language: string;
  language_to_learn: string;
  location?: string;
  joined_date?: string;
  level?: string;
  interests?: string[];
  streak?: number;
}

const SingleCommunity = () => {
  // Mock member data - replace with your actual data source
  const member: CommunityMember = {
    id: "1",
    name: "Sofia Martinez",
    imageUrls: [
      "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face",
      "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face"
    ],
    bio: "Passionate language learner from Barcelona! I love sharing Spanish culture and learning about different traditions around the world. When I'm not studying, you'll find me cooking paella or exploring new hiking trails.",
    native_language: "Spanish",
    language_to_learn: "English",
    location: "Barcelona, Spain",
    joined_date: "March 2024",
    level: "Intermediate",
    interests: ["Travel", "Cooking", "Hiking", "Photography", "Music"],
    streak: 47
  };
  const [isLiked, setIsLiked] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    setIsLoaded(true);
  }, []);

  if (!member) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 flex items-center justify-center">
        <div className="text-white text-xl">No member info provided.</div>
      </div>
    );
  }

  const nextImage = () => {
    if (member.imageUrls.length > 1) {
      setCurrentImageIndex((prev) => (prev + 1) % member.imageUrls.length);
    }
  };

  const languages = [
    { code: member.native_language, flag: "🇺🇸", level: "Native" },
    { code: member.language_to_learn, flag: "🇪🇸", level: member.level || "Beginner" }
  ];

  const mockInterests = member.interests || ["Travel", "Music", "Food", "Culture"];
  const mockStreak = member.streak || Math.floor(Math.random() * 100) + 1;

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 relative overflow-hidden">
      {/* Animated background elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-pink-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-yellow-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse delay-1000"></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-80 h-80 bg-green-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-pulse delay-500"></div>
      </div>

      {/* Floating particles */}
      {[...Array(20)].map((_, i) => (
        <div
          key={i}
          className="absolute animate-float opacity-20"
          style={{
            left: `${Math.random() * 100}%`,
            top: `${Math.random() * 100}%`,
            animationDelay: `${Math.random() * 3}s`,
            animationDuration: `${3 + Math.random() * 2}s`
          }}
        >
          <Sparkles className="text-white w-4 h-4" />
        </div>
      ))}

      <div className={`relative z-10 container mx-auto px-4 py-8 transition-all duration-1000 ${isLoaded ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'}`}>
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <button className="flex items-center space-x-2 text-white/80 hover:text-white transition-colors bg-white/10 backdrop-blur-sm rounded-full px-4 py-2 hover:bg-white/20">
            <ArrowLeft className="w-5 h-5" />
            <span>Back</span>
          </button>
          <div className="flex space-x-3">
            <button className="p-3 bg-white/10 backdrop-blur-sm rounded-full hover:bg-white/20 transition-all duration-300 hover:scale-110">
              <MessageCircle className="w-6 h-6 text-white" />
            </button>
            <button 
              onClick={() => setIsLiked(!isLiked)}
              className={`p-3 backdrop-blur-sm rounded-full transition-all duration-300 hover:scale-110 ${
                isLiked ? 'bg-red-500/20 text-red-400' : 'bg-white/10 text-white hover:bg-white/20'
              }`}
            >
              <Heart className={`w-6 h-6 ${isLiked ? 'fill-current' : ''}`} />
            </button>
          </div>
        </div>

        {/* Main Content */}
        <div className="grid lg:grid-cols-2 gap-8">
          {/* Left Column - Image & Basic Info */}
          <div className="space-y-6">
            {/* Profile Image */}
            <div className="relative group">
              <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-pink-500 via-purple-500 to-blue-500 p-1 shadow-2xl">
                <div className="relative overflow-hidden rounded-3xl bg-black/20 backdrop-blur-sm">
                  <img
                    src={member.imageUrls.length > 0 ? member.imageUrls[currentImageIndex] : "/images/default-avatar.jpg"}
                    alt={member.name}
                    className="w-full h-96 object-cover cursor-pointer transition-transform duration-500 hover:scale-105"
                    onClick={nextImage}
                  />
                  {member.imageUrls.length > 1 && (
                    <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2">
                      {member.imageUrls.map((_, index) => (
                        <div
                          key={index}
                          className={`w-2 h-2 rounded-full transition-all ${
                            index === currentImageIndex ? 'bg-white' : 'bg-white/50'
                          }`}
                        />
                      ))}
                    </div>
                  )}
                </div>
              </div>
              
              {/* Status indicator */}
              <div className="absolute -top-2 -right-2 bg-green-500 w-6 h-6 rounded-full border-4 border-white shadow-lg animate-pulse"></div>
            </div>

            {/* Quick Stats */}
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 text-center hover:bg-white/15 transition-all duration-300 hover:scale-105">
                <div className="flex items-center justify-center mb-2">
                  <Zap className="w-6 h-6 text-yellow-400" />
                </div>
                <div className="text-2xl font-bold text-white">{mockStreak}</div>
                <div className="text-white/70 text-sm">Day Streak</div>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 text-center hover:bg-white/15 transition-all duration-300 hover:scale-105">
                <div className="flex items-center justify-center mb-2">
                  <Trophy className="w-6 h-6 text-orange-400" />
                </div>
                <div className="text-2xl font-bold text-white">Level {Math.floor(Math.random() * 10) + 1}</div>
                <div className="text-white/70 text-sm">Progress</div>
              </div>
            </div>
          </div>

          {/* Right Column - Detailed Info */}
          <div className="space-y-6">
            {/* Name & Location */}
            <div className="bg-white/10 backdrop-blur-sm rounded-3xl p-6 hover:bg-white/15 transition-all duration-300">
              <h1 className="text-4xl font-bold text-white mb-2 bg-gradient-to-r from-pink-400 to-purple-400 bg-clip-text text-transparent">
                {member.name}
              </h1>
              <div className="flex items-center space-x-2 text-white/80 mb-4">
                <MapPin className="w-4 h-4" />
                <span>{member.location || "San Francisco, CA"}</span>
              </div>
              <div className="flex items-center space-x-2 text-white/80">
                <Calendar className="w-4 h-4" />
                <span>Joined {member.joined_date || "January 2024"}</span>
              </div>
            </div>

            {/* Languages */}
            <div className="bg-white/10 backdrop-blur-sm rounded-3xl p-6 hover:bg-white/15 transition-all duration-300">
              <h3 className="text-xl font-semibold text-white mb-4 flex items-center">
                <Globe className="w-5 h-5 mr-2" />
                Languages
              </h3>
              <div className="space-y-3">
                {languages.map((lang, index) => (
                  <div key={index} className="flex items-center justify-between bg-white/10 rounded-2xl p-4">
                    <div className="flex items-center space-x-3">
                      <span className="text-2xl">{lang.flag}</span>
                      <div>
                        <div className="text-white font-medium">{lang.code}</div>
                        <div className="text-white/70 text-sm">{lang.level}</div>
                      </div>
                    </div>
                    <div className="flex">
                      {[...Array(5)].map((_, i) => (
                        <Star
                          key={i}
                          className={`w-4 h-4 ${
                            i < (lang.level === 'Native' ? 5 : 2) 
                              ? 'text-yellow-400 fill-current' 
                              : 'text-gray-500'
                          }`}
                        />
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Bio */}
            <div className="bg-white/10 backdrop-blur-sm rounded-3xl p-6 hover:bg-white/15 transition-all duration-300">
              <h3 className="text-xl font-semibold text-white mb-4">About</h3>
              <p className="text-white/90 leading-relaxed">
                {member.bio || "Passionate language learner looking to connect with native speakers and explore new cultures. Love traveling, trying new foods, and sharing stories from around the world!"}
              </p>
            </div>

            {/* Interests */}
            <div className="bg-white/10 backdrop-blur-sm rounded-3xl p-6 hover:bg-white/15 transition-all duration-300">
              <h3 className="text-xl font-semibold text-white mb-4">Interests</h3>
              <div className="flex flex-wrap gap-2">
                {mockInterests.map((interest, index) => (
                  <span
                    key={index}
                    className="bg-gradient-to-r from-pink-500 to-purple-500 text-white px-4 py-2 rounded-full text-sm font-medium hover:scale-110 transition-transform cursor-pointer shadow-lg"
                  >
                    {interest}
                  </span>
                ))}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="grid grid-cols-2 gap-4">
              <button className="bg-gradient-to-r from-pink-500 to-purple-500 text-white font-semibold py-4 px-6 rounded-2xl hover:scale-105 transition-all duration-300 shadow-lg hover:shadow-xl">
                Start Chat
              </button>
              <button className="bg-white/10 backdrop-blur-sm text-white font-semibold py-4 px-6 rounded-2xl hover:bg-white/20 transition-all duration-300 hover:scale-105">
                Add Friend
              </button>
            </div>
          </div>
        </div>
      </div>

      <style jsx>{`
        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-20px); }
        }
        .animate-float {
          animation: float 3s ease-in-out infinite;
        }
      `}</style>
    </div>
  );
};

export default SingleCommunity;