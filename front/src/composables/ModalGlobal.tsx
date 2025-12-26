import React from 'react';
import { Modal, Button } from 'react-bootstrap';

export interface ModalAction {
  label: string;
  variant?: 'primary' | 'secondary' | 'success' | 'danger' | 'warning' | 'info' | 'light' | 'dark' | 'outline-primary' | 'outline-secondary' | 'outline-success' | 'outline-danger' | 'outline-warning' | 'outline-info' | 'outline-light' | 'outline-dark';
  icon?: string;
  onClick: () => void;
  loading?: boolean;
  disabled?: boolean;
}

export interface GlobalModalProps {
  show: boolean;
  onHide: () => void;
  title?: string;
  titleIcon?: string;
  titleColor?: string;
  children?: React.ReactNode;
  content?: string;
  description?: string;
  icon?: string;
  iconColor?: string;
  iconBg?: string;
  size?: 'sm' | 'lg' | 'xl';
  centered?: boolean;
  backdrop?: boolean | 'static';
  keyboard?: boolean;
  animation?: boolean;
  scrollable?: boolean;
  fullscreen?: boolean | string;
  actions?: ModalAction[];
  showCloseButton?: boolean;
  customFooter?: React.ReactNode;
  className?: string;
  headerClassName?: string;
  bodyClassName?: string;
  footerClassName?: string;
  type?: 'default' | 'confirmation' | 'alert' | 'success' | 'error' | 'warning' | 'info';
}

const GlobalModal: React.FC<GlobalModalProps> = ({
  show,
  onHide,
  title,
  titleIcon,
  titleColor,
  children,
  content,
  description,
  icon,
  iconColor = 'text-gray-600',
  iconBg = 'bg-gray-100',
  size,
  centered = true,
  backdrop = 'static',
  keyboard = true,
  animation = true,
  scrollable = false,
  fullscreen = false,
  actions = [],
  showCloseButton = true,
  customFooter,
  className = '',
  headerClassName = '',
  bodyClassName = '',
  footerClassName = '',
  type = 'default'
}) => {
  // Pre-defined configurations for different modal types
  const getTypeConfig = () => {
    switch (type) {
      case 'confirmation':
        return {
          titleIcon: titleIcon || 'bi-question-circle-fill',
          titleColor: titleColor || 'text-blue-600',
          icon: icon || 'bi-question-circle',
          iconColor: iconColor || 'text-blue-600',
          iconBg: iconBg || 'bg-blue-100'
        };
      case 'alert':
      case 'error':
        return {
          titleIcon: titleIcon || 'bi-exclamation-triangle-fill',
          titleColor: titleColor || 'text-red-600',
          icon: icon || 'bi-exclamation-triangle',
          iconColor: iconColor || 'text-red-600',
          iconBg: iconBg || 'bg-red-100'
        };
      case 'success':
        return {
          titleIcon: titleIcon || 'bi-check-circle-fill',
          titleColor: titleColor || 'text-green-600',
          icon: icon || 'bi-check-circle',
          iconColor: iconColor || 'text-green-600',
          iconBg: iconBg || 'bg-green-100'
        };
      case 'warning':
        return {
          titleIcon: titleIcon || 'bi-exclamation-triangle-fill',
          titleColor: titleColor || 'text-amber-600',
          icon: icon || 'bi-exclamation-triangle',
          iconColor: iconColor || 'text-amber-600',
          iconBg: iconBg || 'bg-amber-100'
        };
      case 'info':
        return {
          titleIcon: titleIcon || 'bi-info-circle-fill',
          titleColor: titleColor || 'text-blue-600',
          icon: icon || 'bi-info-circle',
          iconColor: iconColor || 'text-blue-600',
          iconBg: iconBg || 'bg-blue-100'
        };
      default:
        return {
          titleIcon,
          titleColor: titleColor || 'text-gray-900',
          icon,
          iconColor,
          iconBg
        };
    }
  };

  const config = getTypeConfig();

  return (
    <Modal
      show={show}
      onHide={onHide}
      size={size}
      centered={centered}
      backdrop={backdrop}
      keyboard={keyboard}
      animation={animation}
      scrollable={scrollable}
      fullscreen={fullscreen}
      className={className}
    >
      {/* Header */}
      {(title || showCloseButton) && (
        <Modal.Header 
          closeButton={showCloseButton} 
          className={`border-0 pb-2 ${headerClassName}`}
        >
          {title && (
            <Modal.Title className={`text-lg font-semibold flex items-center ${config.titleColor}`}>
              {config.titleIcon && (
                <i className={`${config.titleIcon} mr-2`}></i>
              )}
              {title}
            </Modal.Title>
          )}
        </Modal.Header>
      )}

      {/* Body */}
      <Modal.Body className={`pt-0 ${bodyClassName}`}>
        {/* Icon and content layout */}
        {(config.icon || content || description || children) && (
          <div className="flex items-start space-x-3">
            {/* Icon */}
            {config.icon && (
              <div className="flex-shrink-0">
                <div className={`w-12 h-12 rounded-full ${config.iconBg} flex items-center justify-center`}>
                  <i className={`${config.icon} ${config.iconColor} text-lg`}></i>
                </div>
              </div>
            )}

            {/* Content */}
            <div className="flex-grow">
              {content && (
                <p className="text-gray-700 mb-2">
                  {content}
                </p>
              )}
              
              {description && (
                <p className="text-sm text-gray-500 mb-0 flex items-start">
                  <i className="bi bi-info-circle mr-1 mt-0.5 flex-shrink-0"></i>
                  {description}
                </p>
              )}
              
              {children}
            </div>
          </div>
        )}
        {!config.icon && (content || description || children) && (
          <div>
            {content && (
              <p className="text-gray-700 mb-2">
                {content}
              </p>
            )}
            
            {description && (
              <p className="text-sm text-gray-500 mb-0 flex items-start">
                <i className="bi bi-info-circle mr-1 mt-0.5 flex-shrink-0"></i>
                {description}
              </p>
            )}
            
            {children}
          </div>
        )}
      </Modal.Body>

      {/* Footer */}
      {(actions.length > 0 || customFooter) && (
        <Modal.Footer className={`border-0 pt-0 ${footerClassName}`}>
          {customFooter || (
            <div className="flex justify-end space-x-2 w-full">
              {actions.map((action, index) => (
                <Button
                  key={index}
                  variant={action.variant || 'primary'}
                  onClick={action.onClick}
                  disabled={action.disabled || action.loading}
                  className="px-4 py-2 text-sm font-medium flex items-center"
                >
                  {action.loading ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                      Loading...
                    </>
                  ) : (
                    <>
                      {action.icon && (
                        <i className={`${action.icon} mr-1`}></i>
                      )}
                      {action.label}
                    </>
                  )}
                </Button>
              ))}
            </div>
          )}
        </Modal.Footer>
      )}
    </Modal>
  );
};

export default GlobalModal;

// Helper functions for common modal types
export const useModal = () => {
  const [isOpen, setIsOpen] = React.useState(false);
  const [modalProps, setModalProps] = React.useState<Partial<GlobalModalProps>>({});

  const openModal = (props: Partial<GlobalModalProps>) => {
    setModalProps(props);
    setIsOpen(true);
  };

  const closeModal = () => {
    setIsOpen(false);
    setTimeout(() => setModalProps({}), 300); // Clear props after animation
  };

  return {
    isOpen,
    modalProps,
    openModal,
    closeModal
  };
};

// Predefined modal configurations
export const ModalPresets = {
  confirmation: (
    title: string,
    content: string,
    onConfirm: () => void,
    onCancel: () => void,
    confirmText: string = 'Confirm',
    cancelText: string = 'Cancel'
  ): Partial<GlobalModalProps> => ({
    type: 'confirmation',
    title,
    content,
    actions: [
      {
        label: cancelText,
        variant: 'outline-secondary',
        icon: 'bi-x-lg',
        onClick: onCancel
      },
      {
        label: confirmText,
        variant: 'primary',
        icon: 'bi-check2',
        onClick: onConfirm
      }
    ]
  }),

  delete: (
    itemName: string,
    onConfirm: () => void,
    onCancel: () => void
  ): Partial<GlobalModalProps> => ({
    type: 'error',
    title: 'Delete Confirmation',
    content: `Are you sure you want to delete "${itemName}"?`,
    description: 'This action cannot be undone. All data will be permanently deleted.',
    actions: [
      {
        label: 'Cancel',
        variant: 'outline-secondary',
        icon: 'bi-x-lg',
        onClick: onCancel
      },
      {
        label: 'Delete',
        variant: 'danger',
        icon: 'bi-trash3',
        onClick: onConfirm
      }
    ]
  }),

  success: (
    title: string,
    content: string,
    onClose: () => void,
    buttonText: string = 'OK'
  ): Partial<GlobalModalProps> => ({
    type: 'success',
    title,
    content,
    actions: [
      {
        label: buttonText,
        variant: 'success',
        icon: 'bi-check2',
        onClick: onClose
      }
    ]
  }),

  error: (
    title: string,
    content: string,
    onClose: () => void,
    buttonText: string = 'OK'
  ): Partial<GlobalModalProps> => ({
    type: 'error',
    title,
    content,
    actions: [
      {
        label: buttonText,
        variant: 'danger',
        icon: 'bi-x-lg',
        onClick: onClose
      }
    ]
  }),

  loading: (
    title: string,
    content: string
  ): Partial<GlobalModalProps> => ({
    type: 'info',
    title,
    content,
    showCloseButton: false,
    backdrop: 'static',
    keyboard: false
  })
};