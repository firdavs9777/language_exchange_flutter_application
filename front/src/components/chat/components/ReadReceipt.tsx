import React from 'react';
import { Check, CheckCheck } from 'lucide-react';
import './ReadReceipt.scss';

interface ReadReceiptProps {
  status: 'sending' | 'sent' | 'delivered' | 'read' | 'error';
}

const ReadReceipt: React.FC<ReadReceiptProps> = ({ status }) => {
  const renderIcon = () => {
    switch (status) {
      case 'sending':
        return (
          <div className="sending-indicator">
            <div className="sending-dot" />
          </div>
        );
      case 'sent':
        return <Check size={14} className="check-icon sent" />;
      case 'delivered':
        return <CheckCheck size={14} className="check-icon delivered" />;
      case 'read':
        return <CheckCheck size={14} className="check-icon read" />;
      case 'error':
        return (
          <svg className="error-icon" viewBox="0 0 24 24" width={14} height={14}>
            <circle cx="12" cy="12" r="10" fill="currentColor" />
            <line x1="12" y1="8" x2="12" y2="12" stroke="white" strokeWidth="2" />
            <circle cx="12" cy="16" r="1" fill="white" />
          </svg>
        );
      default:
        return null;
    }
  };

  return (
    <span className={`read-receipt ${status}`} aria-label={`Message ${status}`}>
      {renderIcon()}
    </span>
  );
};

export default ReadReceipt;
