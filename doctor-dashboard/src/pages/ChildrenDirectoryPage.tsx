import React, { useEffect, useState, useCallback } from 'react';
import { Search } from 'lucide-react';
import type { AssignedChild } from '../types';
import { childrenService } from '../services/childrenService';
import { FilterPills, type FilterStatus } from '../components/children/FilterPills';
import { ChildCard } from '../components/children/ChildCard';
import { LoadingState } from '../components/common/LoadingState';
import { EmptyState } from '../components/common/EmptyState';
import { ErrorState } from '../components/common/ErrorState';

interface ChildrenDirectoryPageProps {
  onSelectChild: (childId: string) => void;
  externalSearch?: string;
}

export const ChildrenDirectoryPage: React.FC<ChildrenDirectoryPageProps> = ({
  onSelectChild,
  externalSearch = '',
}) => {
  const [rawChildren, setRawChildren] = useState<AssignedChild[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [fetchIndex, setFetchIndex] = useState(0);

  const [search, setSearch] = useState(externalSearch);
  const [prevExternalSearch, setPrevExternalSearch] = useState(externalSearch);
  const [filter, setFilter] = useState<FilterStatus>('all');

  // Sync state if external search prop changes (derived during render)
  if (externalSearch !== prevExternalSearch) {
    setPrevExternalSearch(externalSearch);
    setSearch(externalSearch);
  }

  const handleRetry = useCallback(() => {
    setLoading(true);
    setError(null);
    setFetchIndex((i) => i + 1);
  }, []);

  useEffect(() => {
    let isMounted = true;

    childrenService
      .getDoctorChildren()
      .then((apiChildren) => {
        if (!isMounted) return;
        setRawChildren(apiChildren);
        setError(null);
        setLoading(false);
      })
      .catch((err) => {
        if (!isMounted) return;
        const message =
          err instanceof Error ? err.message : 'تعذر تحميل قائمة الأطفال، يرجى المحاولة لاحقاً.';
        setError(message);
        console.error('Error fetching doctor children:', err);
        setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [fetchIndex]);

  // Compute dynamic filter counts from the real API-loaded dataset
  const counts = childrenService.calculateFilterCounts(rawChildren);

  // Compute filtered children list based on search and status filter
  const filteredChildren = childrenService.filterChildren(rawChildren, search, filter);

  const handleClearFilters = () => {
    setSearch('');
    setFilter('all');
  };

  if (loading && rawChildren.length === 0) {
    return (
      <div className="space-y-6 animate-fade-in">
        {/* Top Controls Skeleton */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="space-y-2">
            <div className="h-7 bg-[#F0E8FF]/80 rounded-2xl w-36 animate-pulse" />
            <div className="h-3.5 bg-[#F0E8FF]/50 rounded-xl w-64 animate-pulse" />
          </div>
          <div className="h-10 bg-white rounded-2xl w-full sm:w-72 border border-[#E4D4FF] animate-pulse" />
        </div>

        {/* Filter Pills Skeleton */}
        <div className="flex flex-wrap gap-2.5 mb-6">
          <div className="h-9 w-28 bg-white rounded-2xl border border-[#E4D4FF] animate-pulse" />
          <div className="h-9 w-24 bg-white rounded-2xl border border-[#E4D4FF] animate-pulse" />
          <div className="h-9 w-24 bg-white rounded-2xl border border-[#E4D4FF] animate-pulse" />
          <div className="h-9 w-24 bg-white rounded-2xl border border-[#E4D4FF] animate-pulse" />
        </div>

        {/* Child Cards Grid Skeleton */}
        <LoadingState variant="grid" count={6} />
      </div>
    );
  }

  if (error) {
    return <ErrorState message={error} onRetry={handleRetry} />;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Top Controls: Page Title + Search Input */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-[#432F62]">الأطفال</h2>
          <p className="text-xs font-semibold text-[#74728A] mt-0.5">
            دليل الأطفال المتابعين والتقييمات النمائية الدورية
          </p>
        </div>

        {/* Search Bar */}
        <div className="relative w-full sm:w-72">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="البحث باسم الطفل..."
            className="w-full bg-white hover:bg-[#FAF8FF] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-4 pr-10 py-2.5 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all shadow-xs"
          />
          <Search className="w-4 h-4 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
        </div>
      </div>

      {/* Dynamic Filter Pills */}
      <FilterPills
        currentFilter={filter}
        onFilterChange={setFilter}
        counts={counts}
      />

      {/* Children Grid & Empty States */}
      {rawChildren.length === 0 ? (
        /* Case 1: Doctor has 0 assigned children in the system */
        <EmptyState
          title="لا يوجد أطفال معينون حالياً"
          description="لم يتم ربط أي أطفال بحسابك السريري بعد. يمكنك مشاركة كود الإحالة الخاص بك مع أولياء الأمور للبدء."
        />
      ) : filteredChildren.length === 0 ? (
        /* Case 2: Search or filter returned 0 results */
        <EmptyState
          title="لم يتم العثور على أطفال"
          description="لا توجد نتائج تطابق معايير البحث أو الفلتر المحددة حالياً."
          actionText="إعادة ضبط الفلاتر"
          onAction={handleClearFilters}
        />
      ) : (
        /* Case 3: Display filtered children cards */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filteredChildren.map((child) => (
            <ChildCard
              key={child.id}
              child={child}
              onSelect={onSelectChild}
            />
          ))}
        </div>
      )}
    </div>
  );
};
