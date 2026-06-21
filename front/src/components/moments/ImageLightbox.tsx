import React, { useCallback, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { FaChevronLeft, FaChevronRight, FaTimes } from "react-icons/fa";
import "./ImageLightbox.scss";

interface ImageLightboxProps {
  images: string[];
  initialIndex?: number;
  open: boolean;
  onClose: () => void;
  alt?: string;
}

const ImageLightbox: React.FC<ImageLightboxProps> = ({
  images,
  initialIndex = 0,
  open,
  onClose,
  alt,
}) => {
  const { t } = useTranslation();
  const [index, setIndex] = useState(initialIndex);

  useEffect(() => {
    if (open) setIndex(initialIndex);
  }, [open, initialIndex]);

  const next = useCallback(() => {
    setIndex((i) => (i + 1) % images.length);
  }, [images.length]);

  const prev = useCallback(() => {
    setIndex((i) => (i - 1 + images.length) % images.length);
  }, [images.length]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
      else if (e.key === "ArrowRight") next();
      else if (e.key === "ArrowLeft") prev();
    };
    window.addEventListener("keydown", onKey);
    // Lock body scroll while open.
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [open, onClose, next, prev]);

  if (!open || images.length === 0) return null;

  const closeLabel = t("moments_section.lightbox.close") || "Close image viewer";
  const prevLabel = t("moments_section.lightbox.previous") || "Previous image";
  const nextLabel = t("moments_section.lightbox.next") || "Next image";

  return (
    <div
      className="moment-lightbox"
      role="dialog"
      aria-modal="true"
      aria-label={closeLabel}
      onClick={onClose}
    >
      <button
        type="button"
        className="moment-lightbox__close"
        aria-label={closeLabel}
        onClick={onClose}
      >
        <FaTimes />
      </button>

      <div
        className="moment-lightbox__stage"
        onClick={(e) => e.stopPropagation()}
      >
        <img
          key={index}
          src={images[index]}
          alt={alt ? `${alt} ${index + 1}` : `Image ${index + 1}`}
          className="moment-lightbox__image"
        />

        {images.length > 1 && (
          <>
            <button
              type="button"
              className="moment-lightbox__nav moment-lightbox__nav--prev"
              aria-label={prevLabel}
              onClick={prev}
            >
              <FaChevronLeft />
            </button>
            <button
              type="button"
              className="moment-lightbox__nav moment-lightbox__nav--next"
              aria-label={nextLabel}
              onClick={next}
            >
              <FaChevronRight />
            </button>
          </>
        )}
      </div>

      {images.length > 1 && (
        <div className="moment-lightbox__counter">
          {index + 1} / {images.length}
        </div>
      )}
    </div>
  );
};

export default ImageLightbox;
