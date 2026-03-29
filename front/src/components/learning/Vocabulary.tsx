import React, { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetVocabularyQuery,
  useAddVocabularyMutation,
  useDeleteVocabularyMutation,
} from "../../store/slices/learningSlice";
import { Bounce, toast } from "react-toastify";
import {
  ArrowLeft,
  Search,
  Plus,
  BookOpen,
  Trash2,
  Filter,
  X,
  Loader2,
  Volume2,
} from "lucide-react";

interface VocabularyItem {
  _id: string;
  word: string;
  translation: string;
  language: string;
  pronunciation?: string;
  srsLevel: number;
  nextReviewDate: string;
}

const SRS_LEVELS = [
  { level: 0, label: "New", color: "bg-gray-400" },
  { level: 1, label: "Apprentice", color: "bg-pink-500" },
  { level: 2, label: "Guru", color: "bg-purple-500" },
  { level: 3, label: "Master", color: "bg-blue-500" },
  { level: 4, label: "Enlightened", color: "bg-teal-500" },
  { level: 5, label: "Burned", color: "bg-yellow-500" },
];

const Vocabulary: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [searchQuery, setSearchQuery] = useState("");
  const [filterLevel, setFilterLevel] = useState<number | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newWord, setNewWord] = useState({ word: "", translation: "", pronunciation: "" });

  const { data, isLoading, refetch } = useGetVocabularyQuery({});
  const [addVocabulary, { isLoading: isAdding }] = useAddVocabularyMutation();
  const [deleteVocabulary] = useDeleteVocabularyMutation();

  const vocabulary: VocabularyItem[] = Array.isArray(data?.data) ? data.data : [];

  const filteredVocabulary = useMemo(() => {
    let filtered = vocabulary;

    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (item) =>
          item.word.toLowerCase().includes(query) ||
          item.translation.toLowerCase().includes(query)
      );
    }

    if (filterLevel !== null) {
      filtered = filtered.filter((item) => item.srsLevel === filterLevel);
    }

    return filtered;
  }, [vocabulary, searchQuery, filterLevel]);

  const handleAddWord = async () => {
    if (!newWord.word.trim() || !newWord.translation.trim()) {
      toast.error(t("learning.vocabulary.fillFields") || "Please fill in all fields", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }

    try {
      await addVocabulary({
        word: newWord.word,
        translation: newWord.translation,
        pronunciation: newWord.pronunciation,
      }).unwrap();

      toast.success(t("learning.vocabulary.wordAdded") || "Word added successfully", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });

      setNewWord({ word: "", translation: "", pronunciation: "" });
      setShowAddModal(false);
      refetch();
    } catch (error) {
      toast.error(t("learning.vocabulary.addError") || "Failed to add word", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deleteVocabulary(id).unwrap();
      toast.success(t("learning.vocabulary.wordDeleted") || "Word deleted", {
        position: "top-right",
        autoClose: 2000,
        theme: "dark",
        transition: Bounce,
      });
      refetch();
    } catch (error) {
      toast.error(t("learning.vocabulary.deleteError") || "Failed to delete", {
        position: "top-right",
        autoClose: 3000,
        theme: "dark",
        transition: Bounce,
      });
    }
  };

  const getSrsLevelInfo = (level: number) => {
    return SRS_LEVELS.find((l) => l.level === level) || SRS_LEVELS[0];
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-teal-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-600 to-indigo-600 text-white p-6 pb-20">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-xl font-bold">
                {t("learning.vocabulary.title") || "Vocabulary"}
              </h1>
              <p className="text-purple-200 text-sm">
                {vocabulary.length} {t("learning.vocabulary.wordsTotal") || "words"}
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowAddModal(true)}
            className="p-2 bg-white/20 rounded-lg hover:bg-white/30 transition-colors"
          >
            <Plus className="w-6 h-6" />
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 -mt-14 pb-8 max-w-2xl mx-auto">
        {/* Search & Filter */}
        <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 shadow-xl border border-white/30 mb-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder={t("learning.vocabulary.searchPlaceholder") || "Search words..."}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            </div>
            <button
              onClick={() => setFilterLevel(filterLevel === null ? 0 : null)}
              className={`p-2 rounded-lg transition-colors ${
                filterLevel !== null
                  ? "bg-purple-100 text-purple-600"
                  : "bg-gray-100 text-gray-600"
              }`}
            >
              <Filter className="w-5 h-5" />
            </button>
          </div>

          {/* SRS Level Filters */}
          <div className="flex gap-2 overflow-x-auto pb-2">
            <button
              onClick={() => setFilterLevel(null)}
              className={`px-3 py-1 rounded-full text-sm whitespace-nowrap transition-colors ${
                filterLevel === null
                  ? "bg-purple-600 text-white"
                  : "bg-gray-100 text-gray-600"
              }`}
            >
              {t("learning.vocabulary.all") || "All"}
            </button>
            {SRS_LEVELS.map((level) => (
              <button
                key={level.level}
                onClick={() => setFilterLevel(level.level)}
                className={`px-3 py-1 rounded-full text-sm whitespace-nowrap transition-colors ${
                  filterLevel === level.level
                    ? `${level.color} text-white`
                    : "bg-gray-100 text-gray-600"
                }`}
              >
                {level.label}
              </button>
            ))}
          </div>
        </div>

        {/* Word List */}
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="w-10 h-10 text-purple-500 animate-spin mb-4" />
            <p className="text-gray-500">{t("common.loading") || "Loading..."}</p>
          </div>
        ) : filteredVocabulary.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20">
            <div className="p-6 rounded-full bg-purple-100 mb-6">
              <BookOpen className="w-12 h-12 text-purple-500" />
            </div>
            <h3 className="text-xl font-semibold text-gray-800 mb-2">
              {searchQuery
                ? t("learning.vocabulary.noResults") || "No words found"
                : t("learning.vocabulary.noWords") || "No vocabulary yet"}
            </h3>
            <p className="text-gray-500 text-center max-w-sm mb-6">
              {t("learning.vocabulary.startAdding") ||
                "Start adding words to build your vocabulary"}
            </p>
            {!searchQuery && (
              <button
                onClick={() => setShowAddModal(true)}
                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
              >
                <Plus className="w-5 h-5" />
                {t("learning.vocabulary.addWord") || "Add Word"}
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-3">
            {filteredVocabulary.map((item) => {
              const levelInfo = getSrsLevelInfo(item.srsLevel);
              return (
                <div
                  key={item._id}
                  className="bg-white/60 backdrop-blur-sm rounded-xl p-4 border border-white/30"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span
                          className={`px-2 py-0.5 rounded-full text-xs text-white ${levelInfo.color}`}
                        >
                          {levelInfo.label}
                        </span>
                      </div>
                      <p className="text-lg font-semibold text-gray-800">{item.word}</p>
                      <p className="text-gray-600">{item.translation}</p>
                      {item.pronunciation && (
                        <div className="flex items-center gap-1 mt-1 text-sm text-gray-400">
                          <Volume2 className="w-4 h-4" />
                          <span>{item.pronunciation}</span>
                        </div>
                      )}
                    </div>
                    <button
                      onClick={() => handleDelete(item._id)}
                      className="p-2 text-gray-400 hover:text-red-500 transition-colors"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Add Word Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center">
          <div className="bg-white w-full sm:w-96 sm:rounded-2xl rounded-t-2xl p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold">
                {t("learning.vocabulary.addWord") || "Add Word"}
              </h3>
              <button
                onClick={() => setShowAddModal(false)}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {t("learning.vocabulary.word") || "Word"}
                </label>
                <input
                  type="text"
                  value={newWord.word}
                  onChange={(e) => setNewWord({ ...newWord, word: e.target.value })}
                  placeholder={t("learning.vocabulary.wordPlaceholder") || "Enter word"}
                  className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {t("learning.vocabulary.translation") || "Translation"}
                </label>
                <input
                  type="text"
                  value={newWord.translation}
                  onChange={(e) => setNewWord({ ...newWord, translation: e.target.value })}
                  placeholder={t("learning.vocabulary.translationPlaceholder") || "Enter translation"}
                  className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {t("learning.vocabulary.pronunciation") || "Pronunciation (optional)"}
                </label>
                <input
                  type="text"
                  value={newWord.pronunciation}
                  onChange={(e) => setNewWord({ ...newWord, pronunciation: e.target.value })}
                  placeholder={t("learning.vocabulary.pronunciationPlaceholder") || "Enter pronunciation"}
                  className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>
              <button
                onClick={handleAddWord}
                disabled={isAdding}
                className="w-full py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-xl font-semibold hover:shadow-lg transition-all disabled:opacity-50"
              >
                {isAdding
                  ? t("learning.vocabulary.adding") || "Adding..."
                  : t("learning.vocabulary.addWord") || "Add Word"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Vocabulary;
