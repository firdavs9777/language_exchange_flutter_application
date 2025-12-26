
import { FaChevronLeft, FaChevronRight } from "react-icons/fa";
interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  hasNextPage: boolean;
  hasPrevPage: boolean;
  totalMoments: number;
  isLoading?: boolean;
}

// Mobile-optimized Pagination Component
const Pagination: React.FC<PaginationProps> = ({
  currentPage,
  totalPages,
  onPageChange,
  hasNextPage,
  hasPrevPage,
  totalMoments,
  isLoading = false,
}) => {
  if (totalPages <= 1) return null;

  const getPageNumbers = () => {
    // More conservative pagination for mobile
    const delta = window.innerWidth < 640 ? 1 : 2;
    const rangeWithDots = [];

    // Always show first page
    if (currentPage > delta + 1) {
      rangeWithDots.push(1);
      if (currentPage > delta + 2) {
        rangeWithDots.push('...');
      }
    }

    // Show pages around current page
    for (
      let i = Math.max(1, currentPage - delta);
      i <= Math.min(totalPages, currentPage + delta);
      i++
    ) {
      rangeWithDots.push(i);
    }

    // Always show last page
    if (currentPage < totalPages - delta) {
      if (currentPage < totalPages - delta - 1) {
        rangeWithDots.push('...');
      }
      rangeWithDots.push(totalPages);
    }

    return rangeWithDots;
  };

  return (
    <div className="mt-4 sm:mt-8 px-2 sm:px-4">
      <div className="overflow-hidden rounded-xl sm:rounded-2xl bg-white/60 backdrop-blur-xl border border-white/30 shadow-xl">
        <div className="px-3 sm:px-6 py-3 sm:py-4">
          {/* Moments count */}
          <div className="text-center mb-3 sm:mb-4">
            <p className="text-xs sm:text-sm text-gray-600">
              <span className="block sm:inline">Page {currentPage} of {totalPages}</span>
              <span className="hidden sm:inline"> • </span>
              <span className="block sm:inline">({totalMoments} total moments)</span>
            </p>
          </div>

          {/* Pagination buttons */}
          <div className="flex items-center justify-center gap-1 sm:gap-2">
            {/* Previous button */}
            <button
              onClick={() => onPageChange(currentPage - 1)}
              disabled={!hasPrevPage || isLoading}
              className="group flex items-center gap-1 sm:gap-2 rounded-full bg-white/60 backdrop-blur-sm border border-white/30 px-2 py-1.5 sm:px-4 sm:py-2 text-xs sm:text-sm font-medium text-gray-700 shadow-lg transition-all duration-300 hover:bg-white/80 hover:shadow-xl hover:-translate-y-0.5 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0 focus:outline-none focus:ring-2 focus:ring-blue-400/50"
            >
              <FaChevronLeft className="h-2 w-2 sm:h-3 sm:w-3 transition-transform group-hover:-translate-x-0.5" />
              <span className="hidden sm:inline">Previous</span>
            </button>

            {/* Page numbers */}
            <div className="flex items-center gap-0.5 sm:gap-1 mx-2">
              {getPageNumbers().map((pageNum, index) => {
                if (pageNum === '...') {
                  return (
                    <span
                      key={`dots-${index}`}
                      className="px-1 sm:px-3 py-1 sm:py-2 text-xs sm:text-sm text-gray-400"
                    >
                      ...
                    </span>
                  );
                }

                const isCurrentPage = pageNum === currentPage;
                return (
                  <button
                    key={pageNum}
                    onClick={() => onPageChange(pageNum as number)}
                    disabled={isLoading}
                    className={`h-8 w-8 sm:h-10 sm:w-10 rounded-full text-xs sm:text-sm font-medium transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-blue-400/50 ${
                      isCurrentPage
                        ? 'bg-gradient-to-r from-blue-500 to-purple-600 text-white shadow-lg transform scale-105 sm:scale-110'
                        : 'bg-white/60 backdrop-blur-sm border border-white/30 text-gray-700 shadow-lg hover:bg-white/80 hover:shadow-xl hover:-translate-y-0.5 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0'
                    }`}
                  >
                    {pageNum}
                  </button>
                );
              })}
            </div>

            {/* Next button */}
            <button
              onClick={() => onPageChange(currentPage + 1)}
              disabled={!hasNextPage || isLoading}
              className="group flex items-center gap-1 sm:gap-2 rounded-full bg-white/60 backdrop-blur-sm border border-white/30 px-2 py-1.5 sm:px-4 sm:py-2 text-xs sm:text-sm font-medium text-gray-700 shadow-lg transition-all duration-300 hover:bg-white/80 hover:shadow-xl hover:-translate-y-0.5 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0 focus:outline-none focus:ring-2 focus:ring-blue-400/50"
            >
              <span className="hidden sm:inline">Next</span>
              <FaChevronRight className="h-2 w-2 sm:h-3 sm:w-3 transition-transform group-hover:translate-x-0.5" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
export default Pagination;
