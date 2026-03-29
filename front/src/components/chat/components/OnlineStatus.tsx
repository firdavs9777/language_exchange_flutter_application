import React from 'react';
import './OnlineStatus.scss';

interface OnlineStatusProps {
  isOnline: boolean;
  size?: 'small' | 'medium' | 'large';
  showLabel?: boolean;
}

const OnlineStatus: React.FC<OnlineStatusProps> = ({
  isOnline,
  size = 'medium',
  showLabel = false,
}) => {
  const sizeClasses = {
    small: 'w-2 h-2',
    medium: 'w-3 h-3',
    large: 'w-4 h-4',
  };

  return (
    <div className="online-status-wrapper">
      <span
        className={`online-status-dot ${sizeClasses[size]} ${isOnline ? 'online' : 'offline'}`}
        role="status"
        aria-label={isOnline ? 'User is online' : 'User is offline'}
      />
      {showLabel && (
        <span className={`online-status-label ${isOnline ? 'online' : 'offline'}`}>
          {isOnline ? 'Online' : 'Offline'}
        </span>
      )}
    </div>
  );
};

export default OnlineStatus;
