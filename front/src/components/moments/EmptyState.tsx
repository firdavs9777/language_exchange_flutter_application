import { FaPlus } from "react-icons/fa";
interface EmptyStateProps {
  t: (key: string) => string;
  handleAddMoment: () => void;
}

const EmptyState: React.FC<EmptyStateProps> = ({ t, handleAddMoment }) => (
  <div className="mx-2 sm:mx-4 my-6 sm:my-8 text-center">
    <div className="relative overflow-hidden rounded-2xl sm:rounded-3xl bg-gradient-to-br from-blue-50/80 to-purple-50/50 backdrop-blur-xl border border-white/30 shadow-xl py-12 sm:py-16 px-4 sm:px-8">
      <div className="absolute inset-0 bg-gradient-to-r from-blue-500/5 to-purple-500/5"></div>
      <div className="relative">
        <div className="mx-auto mb-6 sm:mb-8 flex h-16 w-16 sm:h-20 sm:w-20 items-center justify-center rounded-full bg-gradient-to-r from-blue-500 to-purple-600 shadow-lg animate-pulse">
          <FaPlus className="h-6 w-6 sm:h-8 sm:w-8 text-white" />
        </div>
        <h3 className="text-lg sm:text-xl font-bold text-gray-800 mb-2 sm:mb-3">
          {t("moments_section.no_moments")}
        </h3>
        <p className="text-sm sm:text-base text-gray-600 mb-6 sm:mb-8 max-w-sm mx-auto leading-relaxed">
          {t("moments_section.first_to_moment")}
        </p>
        <button
          onClick={handleAddMoment}
          className="group inline-flex items-center gap-2 sm:gap-3 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 px-6 py-3 sm:px-8 sm:py-4 text-sm sm:text-base font-semibold text-white shadow-lg transition-all duration-300 hover:shadow-xl hover:scale-105 hover:from-blue-600 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-blue-400/50"
        >
          <FaPlus className="h-3 w-3 sm:h-4 sm:w-4 transition-transform group-hover:rotate-90" />
          <span>{t("moments_section.share_moment")}</span>
        </button>
      </div>
    </div>
  </div>
);
export default EmptyState;
