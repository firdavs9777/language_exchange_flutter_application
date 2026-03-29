import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetHighlightsQuery,
  useCreateHighlightMutation,
  useDeleteHighlightMutation,
} from "../../store/slices/storiesSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Plus,
  Trash2,
  Edit2,
  Loader2,
  BookMarked,
  Image,
  X,
} from "lucide-react";

interface Highlight {
  _id: string;
  title: string;
  coverImage?: string;
  storiesCount: number;
  createdAt: string;
}

const Highlights: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const { data, isLoading, refetch } = useGetHighlightsQuery({});
  const [createHighlight, { isLoading: isCreating }] = useCreateHighlightMutation();
  const [deleteHighlight, { isLoading: isDeleting }] = useDeleteHighlightMutation();

  const highlights: Highlight[] = (data as any)?.data || [];

  const handleCreate = async () => {
    if (!newTitle.trim()) {
      toast.error(t("stories.highlights.titleRequired") || "Please enter a title", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }

    try {
      await createHighlight({ title: newTitle.trim() }).unwrap();
      toast.success(t("stories.highlights.createSuccess") || "Highlight created!", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setNewTitle("");
      setShowCreateModal(false);
      refetch();
    } catch (error) {
      toast.error(t("stories.highlights.createError") || "Failed to create highlight", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleDelete = async (highlightId: string) => {
    try {
      await deleteHighlight(highlightId).unwrap();
      toast.success(t("stories.highlights.deleteSuccess") || "Highlight deleted", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      setDeleteConfirm(null);
      refetch();
    } catch (error) {
      toast.error(t("stories.highlights.deleteError") || "Failed to delete highlight", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-pink-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-pink-500 to-purple-500 text-white p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-xl font-bold flex items-center gap-2">
                <BookMarked className="w-6 h-6" />
                {t("stories.highlights.title") || "Highlights"}
              </h1>
              <p className="text-pink-100 text-sm">
                {t("stories.highlights.subtitle") || "Your saved story collections"}
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowCreateModal(true)}
            className="p-2 bg-white/20 rounded-lg hover:bg-white/30 transition-colors"
          >
            <Plus className="w-6 h-6" />
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-pink-500 animate-spin" />
          </div>
        ) : highlights.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-pink-100 w-fit mx-auto mb-4">
              <BookMarked className="w-8 h-8 text-pink-500" />
            </div>
            <p className="text-gray-500 mb-4">
              {t("stories.highlights.noHighlights") || "No highlights yet"}
            </p>
            <button
              onClick={() => setShowCreateModal(true)}
              className="px-6 py-3 bg-gradient-to-r from-pink-500 to-purple-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
            >
              {t("stories.highlights.createFirst") || "Create Your First Highlight"}
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
            {/* Create New Button */}
            <button
              onClick={() => setShowCreateModal(true)}
              className="aspect-square flex flex-col items-center justify-center bg-white/60 backdrop-blur-sm rounded-2xl border-2 border-dashed border-pink-300 hover:border-pink-500 hover:bg-pink-50 transition-all"
            >
              <div className="p-3 rounded-full bg-pink-100 mb-2">
                <Plus className="w-6 h-6 text-pink-500" />
              </div>
              <span className="text-sm text-pink-600 font-medium">
                {t("stories.highlights.new") || "New"}
              </span>
            </button>

            {/* Highlight Cards */}
            {highlights.map((highlight) => (
              <div
                key={highlight._id}
                className="relative aspect-square bg-white/60 backdrop-blur-sm rounded-2xl border border-white/30 overflow-hidden group"
              >
                {highlight.coverImage ? (
                  <img
                    src={highlight.coverImage}
                    alt={highlight.title}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full bg-gradient-to-br from-pink-200 to-purple-200 flex items-center justify-center">
                    <Image className="w-12 h-12 text-pink-400" />
                  </div>
                )}

                {/* Overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

                {/* Content */}
                <div className="absolute bottom-0 left-0 right-0 p-3">
                  <h3 className="font-semibold text-white truncate">{highlight.title}</h3>
                  <p className="text-white/80 text-sm">
                    {highlight.storiesCount} {t("stories.highlights.stories") || "stories"}
                  </p>
                </div>

                {/* Actions */}
                <div className="absolute top-2 right-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    onClick={() => navigate(`/highlights/${highlight._id}/edit`)}
                    className="p-2 bg-white/90 rounded-lg hover:bg-white transition-colors"
                  >
                    <Edit2 className="w-4 h-4 text-gray-600" />
                  </button>
                  <button
                    onClick={() => setDeleteConfirm(highlight._id)}
                    className="p-2 bg-white/90 rounded-lg hover:bg-white transition-colors"
                  >
                    <Trash2 className="w-4 h-4 text-red-500" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Create Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-800">
                {t("stories.highlights.createNew") || "Create Highlight"}
              </h2>
              <button
                onClick={() => {
                  setShowCreateModal(false);
                  setNewTitle("");
                }}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            <input
              type="text"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder={t("stories.highlights.titlePlaceholder") || "Highlight name"}
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-pink-500 transition-colors mb-6"
              autoFocus
            />

            <div className="flex gap-3">
              <button
                onClick={() => {
                  setShowCreateModal(false);
                  setNewTitle("");
                }}
                className="flex-1 py-3 bg-gray-100 text-gray-600 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
              >
                {t("stories.highlights.cancel") || "Cancel"}
              </button>
              <button
                onClick={handleCreate}
                disabled={isCreating || !newTitle.trim()}
                className="flex-1 py-3 bg-gradient-to-r from-pink-500 to-purple-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all disabled:opacity-50"
              >
                {isCreating ? (
                  <Loader2 className="w-5 h-5 animate-spin mx-auto" />
                ) : (
                  t("stories.highlights.create") || "Create"
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md">
            <div className="text-center mb-6">
              <div className="p-4 rounded-full bg-red-100 w-fit mx-auto mb-4">
                <Trash2 className="w-8 h-8 text-red-500" />
              </div>
              <h2 className="text-xl font-bold text-gray-800 mb-2">
                {t("stories.highlights.deleteConfirm") || "Delete Highlight?"}
              </h2>
              <p className="text-gray-500">
                {t("stories.highlights.deleteWarning") || "This action cannot be undone."}
              </p>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setDeleteConfirm(null)}
                className="flex-1 py-3 bg-gray-100 text-gray-600 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
              >
                {t("stories.highlights.cancel") || "Cancel"}
              </button>
              <button
                onClick={() => handleDelete(deleteConfirm)}
                disabled={isDeleting}
                className="flex-1 py-3 bg-red-500 text-white rounded-xl font-semibold hover:bg-red-600 transition-colors disabled:opacity-50"
              >
                {isDeleting ? (
                  <Loader2 className="w-5 h-5 animate-spin mx-auto" />
                ) : (
                  t("stories.highlights.delete") || "Delete"
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Highlights;
