import React, { useState, useRef } from "react";
import { Modal, Button, Image, Row, Col } from "react-bootstrap";
import { Bounce, toast } from "react-toastify";
import "./ImageUploader.css";
import { useTranslation } from "react-i18next";

export interface ImageViewerModalProps {
  images: string[];
  show: boolean;
  onClose: () => void;
  onUploadImages: (files: File[]) => void;
  onDeleteImage?: (index: number) => void;
  onUpdateImage?: (index: number, newFile: File) => void;
}

const ImageUploadModal: React.FC<ImageViewerModalProps> = ({
  images,
  show,
  onClose,
  onUploadImages,
  onDeleteImage,
  onUpdateImage,
}) => {
  const [selectedImages, setSelectedImages] = useState<File[]>([]);
  const [dragOver, setDragOver] = useState<boolean>(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const MAX_IMAGES = 10;
  const { t } = useTranslation();

  const remainingSlots = MAX_IMAGES - (images.length + selectedImages.length);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.files && event.target.files.length > 0) {
      const filesArray = Array.from(event.target.files);

      if (filesArray.length > remainingSlots) {
        toast.warning(t('image_upload.max_upload_warning', { count: remainingSlots }), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        const allowedFiles = filesArray.slice(0, remainingSlots);
        setSelectedImages(prev => [...prev, ...allowedFiles]);
      } else {
        setSelectedImages(prev => [...prev, ...filesArray]);
      }
    }

    if (event.target) {
      event.target.value = '';
    }
  };

  const triggerFileInput = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setDragOver(true);
  };

  const handleDragLeave = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setDragOver(false);
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setDragOver(false);

    if (e.dataTransfer.files) {
      const filesArray = Array.from(e.dataTransfer.files).filter(
        file => file.type.startsWith('image/')
      );

      if (filesArray.length === 0) {
        toast.error(t('image_upload.image_drop'), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        return;
      }

      if (filesArray.length > remainingSlots) {
        toast.warning(t('image_upload.max_upload_warning', { count: remainingSlots }), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        const allowedFiles = filesArray.slice(0, remainingSlots);
        setSelectedImages(prev => [...prev, ...allowedFiles]);
      } else {
        setSelectedImages(prev => [...prev, ...filesArray]);
      }
    }
  };

  const handleUpload = async () => {
    if (selectedImages.length === 0 && images.length === 0) {
      toast.error(t("image_upload.no_images_error"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }

    onUploadImages(selectedImages);
    setSelectedImages([]);
    onClose();
  };

  const handleDeleteSelected = (index: number) => {
    setSelectedImages(prev =>
      prev.filter((_, i) => i !== index)
    );
    toast.success(t("image_upload.removed_from_selection"), {
      autoClose: 3000,
      hideProgressBar: false,
      theme: "dark",
      transition: Bounce,
    });
  };

  const handleDeleteExisting = (index: number) => {
    if (onDeleteImage) {
      onDeleteImage(index);
      toast.success(t("image_upload.deleted_success"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleUpdateExisting = (index: number, e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0] && onUpdateImage) {
      onUpdateImage(index, e.target.files[0]);
      toast.success(t('image_upload.replaced_success'), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      e.target.value = '';
    }
  };

  return (
    <Modal show={show} onHide={onClose} className="image-uploader-section" size="lg">
      <Modal.Header closeButton>
        <Modal.Title>
          <i className="bi bi-upload me-2"></i>
          {t('image_upload.image_gallery')} ({images.length + selectedImages.length}/{MAX_IMAGES})
        </Modal.Title>
      </Modal.Header>

      <Modal.Body>
        <div className="mb-4">
          <h5>{t('image_upload.current_images')}</h5>
          {images.length > 0 ? (
            <Row className="image-gallery">
              {images.map((item, index) => (
                <Col xs={6} md={4} lg={3} key={`existing-${index}`} className="mb-3">
                  <div className="image-container">
                    <Image
                      src={item}
                      alt={t('image_upload.uploaded_image_alt', { index: index + 1 })}
                      className="img-thumbnail gallery-image"
                    />
                    <div className="image-actions">
                      <label className="update-btn" title={t('image_upload.replace_image_title')}>
                        <input
                          type="file"
                          accept="image/*"
                          className="d-none"
                          onChange={(e) => handleUpdateExisting(index, e)}
                        />
                        <Button variant="outline-info" size="sm">
                          {t('image_upload.replace_image')}
                        </Button>
                      </label>
                      <Button
                        variant="outline-danger"
                        size="sm"
                        onClick={() => handleDeleteExisting(index)}
                        title={t('image_upload.delete_image_title')}
                      >
                        <i className="bi bi-trash"></i>
                      </Button>
                    </div>
                  </div>
                </Col>
              ))}
            </Row>
          ) : (
            <p className="text-muted">{t('image_upload.no_images_uploaded')}</p>
          )}
        </div>

        <div className="mb-4">
          <h5>
            {t('image_upload.new_images')} 
            {selectedImages.length > 0 && `(${selectedImages.length})`}
          </h5>
          {selectedImages.length > 0 ? (
            <Row className="image-gallery">
              {selectedImages.map((file, index) => (
                <Col xs={6} md={4} lg={3} key={`new-${index}`} className="mb-3">
                  <div className="image-container">
                    <Image
                      src={URL.createObjectURL(file)}
                      alt={t('image_upload.selected_preview_alt', { index: index + 1 })}
                      className="img-thumbnail gallery-image"
                    />
                    <div className="image-actions">
                      <Button
                        variant="outline-danger"
                        size="sm"
                        onClick={() => handleDeleteSelected(index)}
                        title={t('image_upload.remove_from_selection_title')}
                      >
                        <i className="bi bi-x-circle"></i>
                      </Button>
                    </div>
                    <div className="image-name-tag">
                      {file.name.length > 15
                        ? file.name.substring(0, 12) + '...'
                        : file.name}
                    </div>
                  </div>
                </Col>
              ))}
            </Row>
          ) : (
            <p className="text-muted">{t('image_upload.no_new_images')}</p>
          )}
        </div>

        {remainingSlots > 0 && (
          <div
            className={`upload-area ${dragOver ? 'drag-over' : ''}`}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
          >
            <i className="bi bi-plus-lg upload-icon fs-1"></i>
            <p>{t('image_upload.drop_images_here')}</p>
            <input
              ref={fileInputRef}
              type="file"
              multiple
              accept="image/*"
              onChange={handleFileChange}
              className="d-none"
            />
            <Button
              variant="outline-primary"
              onClick={triggerFileInput}
            >
              {t('image_upload.select_files')}
            </Button>
            <p className="text-muted mt-2">
              {t('image_upload.remaining_slots', { 
                count: remainingSlots,
                item: remainingSlots === 1 
                  ? t('image_upload.image') 
                  : t('image_upload.images')
              })}
            </p>
          </div>
        )}
      </Modal.Body>

      <Modal.Footer>
        <Button
          variant="secondary"
          onClick={onClose}
        >
          {t('image_upload.cancel')}
        </Button>
        <Button
          variant="success"
          onClick={handleUpload}
          disabled={selectedImages.length === 0 && images.length === 0}
        >
          {t('image_upload.save_changes')}
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default ImageUploadModal;