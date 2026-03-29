import React, { useEffect } from "react";
import { useGetMyMomentsQuery } from "../../store/slices/momentsSlice";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { formatDistanceToNow } from "date-fns";

// Components & Icons
import { AiFillHeart, AiOutlineHeart, AiFillEdit, AiOutlineDelete } from "react-icons/ai";
import { FaRegCommentDots, FaCommentDots } from "react-icons/fa";
import { IoMdShare } from "react-icons/io";
import { useTranslation } from "react-i18next";

// Types
interface User {
  _id: string;
  name: string;
  imageUrls?: string[];
}

export interface MomentType {
  _id: string;
  title: string;
  description: string;
  user: User;
  imageUrls: string[];
  likedUsers: string[];
  likeCount: number;
  commentCount: number;
  createdAt: string;
}

interface MomentsResponse {
  data: MomentType[];
  success: boolean;
}

const MyMoments: React.FC = () => {
  const userId = useSelector((state: any) => state.auth.userInfo?.user?._id);

  const { t } = useTranslation();
   useEffect(() => {
      window.scrollTo(0, 0);
    }, [userId]);
  const { data: moments, refetch } = useGetMyMomentsQuery({ userId });
  const momentsData = moments as MomentsResponse;
  const navigate = useNavigate();

  const handleEdit = (momentId: string) => {
    navigate(`/edit-moment/${momentId}`);
  };

  const handleDelete = (momentId: string) => {
    // Implement delete functionality when ready
    console.log("Delete moment:", momentId);
    // After implementing: refetch();
  };

  const formatTimestamp = (timestamp: string): string => {
    try {
      return formatDistanceToNow(new Date(timestamp), { addSuffix: true });
    } catch (error) {
      return "recently";
    }
  };

  if (!momentsData?.data?.length) {
    return (
      <div className="d-flex flex-column align-items-center justify-content-center p-5 text-center">
        <div className="display-1 mb-4">✨</div>
        <h3 className="h2 fw-semibold text-gray-800 mb-3">{ t("moments_section.no_moments")}</h3>
        <p className="text-muted mb-4">{ t('first_to_moment')}</p>
        <button 
          onClick={() => navigate('/create-moment')}
          className="btn btn-primary btn-lg px-4 py-2 rounded-pill fw-medium">
         {t('moments_section.share_moment')}
        </button>
      </div>
    );
  }

  return (
    <div className="container-fluid px-4 py-5">
      <div className="row g-4">
        {momentsData?.data.map((moment: MomentType) => (
          <div key={moment._id} className="col-12 col-sm-6 col-lg-4 col-xl-3">
            <div className="card h-100 border-0 shadow-sm overflow-hidden hover-shadow-lg transition-all">
              
          
              <div 
                className="card-header bg-white border-0 d-flex align-items-center p-3" 
                onClick={() => navigate(`/community/${moment.user._id}`)} 
                style={{ cursor: 'pointer' }}
              >
                <div className="rounded-circle overflow-hidden bg-light" style={{ width: '40px', height: '40px' }}>
                  <img 
                    src={moment.user?.imageUrls?.length ? moment.user.imageUrls[0] : "https://ui-avatars.com/api/?name=" + encodeURIComponent(moment.user.name)} 
                    alt={moment.user.name}
                    className="img-fluid h-100 w-100 object-fit-cover"
                  />
                </div>
                <div className="ms-3">
                  <p className="fw-medium mb-0 text-dark">{moment.user.name}</p>
                  <small className="text-muted">{formatTimestamp(moment.createdAt)}</small>
                </div>
              </div>
              
              
              {moment.imageUrls.length > 0 && (
                <div className="ratio ratio-16x9 bg-light">
                  <img 
                    src={moment.imageUrls[0]} 
                    alt={moment.title}
                    className="img-fluid object-fit-cover"
                    style={{ transition: 'transform 0.3s ease' }}
                    onMouseOver={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
                    onMouseOut={(e) => e.currentTarget.style.transform = 'scale(1)'}
                  />
                </div>
              )}
              
          
              <div className="card-body">
                <h5 className="card-title fw-semibold text-dark mb-2">{moment.title}</h5>
                <p className="card-text text-muted mb-0" style={{
                  display: '-webkit-box',
                  WebkitLineClamp: 3,
                  WebkitBoxOrient: 'vertical',
                  overflow: 'hidden'
                }}>
                  {moment.description}
                </p>
              </div>
              
              {/* Engagement */}
              <div className="card-footer bg-white border-0 d-flex align-items-center px-3 py-2">
                <button className="btn btn-sm btn-link text-decoration-none d-flex align-items-center me-3 p-1">
                  {moment.likedUsers.includes(userId) ? (
                    <AiFillHeart className="me-1 text-danger" size={18} />
                  ) : (
                    <AiOutlineHeart className="me-1" size={18} />
                  )}
                  <span className="small">{moment.likeCount}</span>
                </button>
                
                <button className="btn btn-sm btn-link text-decoration-none d-flex align-items-center me-3 p-1">
                  {moment.commentCount > 0 ? (
                    <FaCommentDots className="me-1 text-primary" size={16} />
                  ) : (
                    <FaRegCommentDots className="me-1" size={16} />
                  )}
                  <span className="small">{moment.commentCount}</span>
                </button>
                
                <div className="ms-auto d-flex">
                  <button 
                    onClick={() => handleEdit(moment._id)}
                    className="btn btn-sm btn-link text-decoration-none p-1 me-1 rounded-circle"
                    data-bs-toggle="tooltip" 
                    data-bs-placement="top" 
                    title="Edit"
                  >
                    <AiFillEdit size={16} className="text-primary" />
                  </button>
                  
                  <button 
                    onClick={() => handleDelete(moment._id)}
                    className="btn btn-sm btn-link text-decoration-none p-1 me-1 rounded-circle"
                    data-bs-toggle="tooltip" 
                    data-bs-placement="top" 
                    title="Delete"
                  >
                    <AiOutlineDelete size={16} className="text-danger" />
                  </button>
                  
                  <button 
                    className="btn btn-sm btn-link text-decoration-none p-1 rounded-circle"
                    data-bs-toggle="tooltip" 
                    data-bs-placement="top" 
                    title="Share"
                  >
                    <IoMdShare size={16} className="text-success" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default MyMoments;