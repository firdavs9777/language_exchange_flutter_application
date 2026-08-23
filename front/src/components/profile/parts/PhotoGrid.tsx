import React, { useState } from "react";
import { Plus, X } from "lucide-react";
import ImageModal from "../ImageViewer/ImageModal";

interface PhotoGridProps {
  images: string[];
  mode: "view" | "edit";
  onAdd?: (file: File) => void;
  onDelete?: (index: number) => void;
}

const PhotoGrid: React.FC<PhotoGridProps> = ({ images, mode, onAdd, onDelete }) => {
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const isEdit = mode === "edit";

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file && onAdd) onAdd(file);
    e.target.value = "";
  };

  return (
    <div className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl rounded-2xl p-4 shadow-lg border border-white/30 dark:border-gray-700/30">
      <h3 className="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
        Photos
      </h3>
      <div className="grid grid-cols-3 gap-3">
        {images.map((url, index) => (
          <div
            key={`${index}-${url}`}
            data-testid="photo-tile"
            className="relative aspect-square rounded-xl overflow-hidden group"
          >
            <img
              src={url}
              alt={`Photo ${index + 1}`}
              onClick={() => !isEdit && setLightboxIndex(index)}
              className={`w-full h-full object-cover ${isEdit ? "" : "cursor-pointer"}`}
            />
            {isEdit && (
              <button
                type="button"
                aria-label={`Delete photo ${index + 1}`}
                data-testid={`photo-delete-${index}`}
                onClick={() => onDelete?.(index)}
                className="absolute top-2 right-2 p-1.5 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 focus:opacity-100 transition-opacity"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        ))}

        {isEdit && (
          <label
            data-testid="photo-add"
            className="aspect-square rounded-xl border-2 border-dashed border-gray-300 dark:border-gray-600 flex flex-col items-center justify-center cursor-pointer hover:border-teal-400 hover:bg-teal-50/50 dark:hover:bg-teal-900/20 transition-colors"
          >
            <input type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
            <Plus className="w-6 h-6 text-gray-400" />
            <span className="text-xs text-gray-400 mt-1">Add Photo</span>
          </label>
        )}
      </div>

      {!isEdit && lightboxIndex !== null && (
        <ImageModal
          show={lightboxIndex !== null}
          images={images}
          currentIndex={lightboxIndex}
          onClose={() => setLightboxIndex(null)}
          onSelectImage={(i) => setLightboxIndex(i)}
        />
      )}
    </div>
  );
};

export default PhotoGrid;
