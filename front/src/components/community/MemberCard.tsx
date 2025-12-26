import { useState, useMemo } from "react";
import { 

  ArrowRight, Heart, MessageCircle, Star, Zap
} from "lucide-react";

import { Link } from "react-router-dom";
import { MemberCardProps } from "./type";
import { generateRandomStats, getLanguageCode } from "./utils";
import { LanguageFlag } from "./MainCommunity";




export const MemberCard: React.FC<MemberCardProps> = ({ member, onMemberClick }) => {
  const [isLiked, setIsLiked] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  
  const stats = useMemo(() => generateRandomStats(), []);
  const nativeCode = useMemo(() => getLanguageCode(member.native_language), [member.native_language]);
  const learningCode = useMemo(() => getLanguageCode(member.language_to_learn), [member.language_to_learn]);

  const handleCardClick = () => onMemberClick(member._id);
  
  const handleLikeClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsLiked(!isLiked);
  };

  const handleMessageClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    console.log(`Message ${member.name}`);
  };

  const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
    e.currentTarget.src = "";
  };

  return (
    <Link to={`/community/${member._id}`} className="member-card">
      <div 
        className="group relative bg-white bg-opacity-10 backdrop-blur-lg rounded-3xl overflow-hidden hover:bg-opacity-15 transition-all duration-500 hover:scale-105 hover:-translate-y-2 shadow-xl hover:shadow-2xl cursor-pointer border border-white border-opacity-20"
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        onClick={handleCardClick}
      >
        {/* Gradient border effect */}
        <div className="absolute inset-0 bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 rounded-3xl opacity-0 group-hover:opacity-75 transition-opacity duration-300 p-px">
          <div className="w-full h-full bg-gray-900 bg-opacity-90 rounded-3xl"></div>
        </div>
        
        <div className="relative z-10 p-4 sm:p-6">
          {/* Header with image and status */}
          <div className="relative mb-4">
            <div className="relative w-16 h-16 sm:w-20 sm:h-20 mx-auto mb-4">
              <img
                src={member.imageUrls?.[0] || ""}
                alt={member.name}
                className="w-16 h-16 sm:w-20 sm:h-20 rounded-full object-cover border-4 border-white border-opacity-20 group-hover:border-opacity-40 transition-all duration-300"
                onError={handleImageError}
              />
              <div className="absolute -top-1 -right-1 w-5 h-5 sm:w-6 sm:h-6 bg-green-400 rounded-full border-2 border-white animate-pulse"></div>
            </div>
            
            {/* Action buttons */}
            <div className={`absolute top-2 right-2 flex space-x-2 transition-all duration-300 ${isHovered ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-2'}`}>
              <button 
                onClick={handleLikeClick}
                className={`p-2 rounded-full backdrop-blur-sm transition-all duration-300 hover:scale-110 ${isLiked ? 'bg-red-500 bg-opacity-20 text-red-400' : 'bg-white bg-opacity-10 text-white hover:bg-opacity-20'}`}
                aria-label={isLiked ? "Unlike" : "Like"}
              >
                <Heart className={`w-3 h-3 sm:w-4 sm:h-4 ${isLiked ? 'fill-current' : ''}`} />
              </button>
              <button 
                onClick={handleMessageClick}
                className="p-2 bg-white bg-opacity-10 backdrop-blur-sm rounded-full hover:bg-opacity-20 transition-all duration-300 hover:scale-110"
                aria-label="Send message"
              >
                <MessageCircle className="w-3 h-3 sm:w-4 sm:h-4 text-white" />
              </button>
            </div>
          </div>

          <div className="flex items-center justify-center space-x-2 sm:space-x-3 mb-4 bg-white bg-opacity-5 rounded-2xl p-2 sm:p-3">
            <div className="flex items-center space-x-1 sm:space-x-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-lg sm:rounded-xl px-2 sm:px-3 py-1 sm:py-2">
              <LanguageFlag code={nativeCode} />
              <span className="text-white text-xs sm:text-sm font-medium hidden sm:inline">Native</span>
            </div>
            <ArrowRight className="text-white text-opacity-60 w-3 h-3 sm:w-4 sm:h-4" />
            <div className="flex items-center space-x-1 sm:space-x-2 bg-gradient-to-r from-pink-500 to-orange-500 rounded-lg sm:rounded-xl px-2 sm:px-3 py-1 sm:py-2">
              <LanguageFlag code={learningCode} />
              <span className="text-white text-xs sm:text-sm font-medium hidden sm:inline">Learning</span>
            </div>
          </div>

          {/* Member info */}
          <div className="text-center">
            <h3 className="text-lg sm:text-xl font-bold text-white mb-2 bg-gradient-to-r from-pink-400 to-purple-400 bg-clip-text text-transparent">
              {member.name}
            </h3>
            
            <div className="flex items-center justify-center space-x-3 sm:space-x-4 mb-3 text-white text-opacity-80">
              <div className="flex items-center space-x-1" title="Rating">
                <Star className="w-3 h-3 sm:w-4 sm:h-4 text-yellow-400 fill-current" />
                <span className="text-xs sm:text-sm">{stats.rating}</span>
              </div>
              <div className="flex items-center space-x-1" title="Sessions completed">
                <Zap className="w-3 h-3 sm:w-4 sm:h-4 text-green-400" />
                <span className="text-xs sm:text-sm">{stats.sessions}</span>
              </div>
            </div>

            <p className="text-white text-opacity-90 text-xs sm:text-sm leading-relaxed">
              {member.bio?.substring(0, 60) || "Passionate language learner ready to connect!"}
              {member.bio && member.bio.length > 60 ? "..." : ""}
            </p>
          </div>

          {/* Hover overlay */}
          <div className={`absolute inset-0 bg-gradient-to-t from-purple-600 from-opacity-20 to-transparent rounded-3xl transition-opacity duration-300 ${isHovered ? 'opacity-100' : 'opacity-0'}`}></div>
        </div>
      </div>
    </Link>
  );
};