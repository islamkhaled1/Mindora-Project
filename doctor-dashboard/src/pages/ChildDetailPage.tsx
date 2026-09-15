import React, { useEffect, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import type { AssignedChild, WeeklyRoutineTarget, LastSessionTaskItem } from '../types';
import { childrenService, formatDoctorNotesTimestamp } from '../services/childrenService';
import { ChildHeaderCard } from '../components/child-details/ChildHeaderCard';
import { WeeklyRoutineSection } from '../components/child-details/WeeklyRoutineSection';
import { LastSessionTable } from '../components/child-details/LastSessionTable';
import { DoctorNotesSection } from '../components/child-details/DoctorNotesSection';
import { LoadingState } from '../components/common/LoadingState';
import { ErrorState } from '../components/common/ErrorState';

interface ChildDetailPageProps {
  childId?: string;
  onBack?: () => void;
}

export const ChildDetailPage: React.FC<ChildDetailPageProps> = ({ childId, onBack }) => {
  const { id: paramId } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const effectiveChildId = childId || paramId;

  const handleBack = () => {
    if (onBack) {
      onBack();
    } else {
      navigate('/children');
    }
  };

  const [child, setChild] = useState<AssignedChild | null>(null);
  const [weeklyRoutine, setWeeklyRoutine] = useState<WeeklyRoutineTarget[]>([]);
  const [lastSessionTasks, setLastSessionTasks] = useState<LastSessionTaskItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [fetchIndex, setFetchIndex] = useState(0);

  // Doctor notes state backed by real backend API
  const [currentDoctorNotes, setCurrentDoctorNotes] = useState<string>('');
  const [notesUpdatedAt, setNotesUpdatedAt] = useState<string | undefined>(undefined);
  const [notesLoading, setNotesLoading] = useState<boolean>(true);
  const [notesError, setNotesError] = useState<string | null>(null);

  const handleRetry = useCallback(() => {
    setLoading(true);
    setError(null);
    setFetchIndex((i) => i + 1);
  }, []);

  const loadNotesOnly = useCallback(() => {
    if (!effectiveChildId) return;
    setNotesLoading(true);
    setNotesError(null);
    childrenService
      .getDoctorNotes(effectiveChildId)
      .then((notesDto) => {
        setCurrentDoctorNotes(notesDto.notes || '');
        setNotesUpdatedAt(formatDoctorNotesTimestamp(notesDto.updatedAtUtc));
        setNotesLoading(false);
      })
      .catch((err) => {
        console.warn('Could not load doctor notes for child', effectiveChildId, err);
        setNotesError('تعذر تحميل ملاحظات الطبيب، يمكنك المحاولة مرة أخرى.');
        setNotesLoading(false);
      });
  }, [effectiveChildId]);

  useEffect(() => {
    if (!effectiveChildId) {
      setLoading(false);
      setError('معرف الطفل غير صالح أو غير موجود.');
      return;
    }

    let isMounted = true;

    childrenService
      .getChildFullProfile(effectiveChildId)
      .then((profile) => {
        if (!isMounted) return;
        setChild(profile.child);
        setWeeklyRoutine(profile.weeklyRoutine);
        setLastSessionTasks(profile.lastSessionTasks);
        setCurrentDoctorNotes(profile.doctorNotes?.notes || '');
        setNotesUpdatedAt(formatDoctorNotesTimestamp(profile.doctorNotes?.updatedAtUtc));
        setError(null);
        setLoading(false);
        setNotesLoading(false);
      })
      .catch((err) => {
        if (!isMounted) return;
        const message =
          err instanceof Error
            ? err.message
            : 'لم يتم العثور على بيانات الطفل المطلوب أو حدث خطأ أثناء الاتصال بالخادم.';
        setError(message);
        console.error('Error fetching child full profile:', err);
        setLoading(false);
        setNotesLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [effectiveChildId, fetchIndex]);

  // Real backend persistence for Doctor Notes via PUT /api/doctor/children/{childId}/notes
  const handleSaveNotes = async (notes: string) => {
    if (!effectiveChildId) {
      throw new Error('Child ID is missing');
    }
    const updatedDto = await childrenService.updateDoctorNotes(effectiveChildId, notes.trim() || null);
    const formattedDate = formatDoctorNotesTimestamp(updatedDto.updatedAtUtc);

    setCurrentDoctorNotes(updatedDto.notes || '');
    setNotesUpdatedAt(formattedDate || undefined);

    return {
      notes: updatedDto.notes || '',
      updatedAt: formattedDate || '',
    };
  };

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in pb-8">
        {/* Back Button Skeleton */}
        <div className="h-9 w-36 bg-white rounded-2xl border border-[#E4D4FF] animate-pulse" />
        
        {/* ChildHeaderCard Skeleton */}
        <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs animate-pulse space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-full bg-[#F0E8FF]" />
              <div className="space-y-2">
                <div className="h-6 bg-[#F0E8FF] rounded-xl w-48" />
                <div className="h-4 bg-[#F0E8FF]/60 rounded-lg w-64" />
              </div>
            </div>
            <div className="flex gap-4">
              <div className="w-28 h-16 bg-[#F7FAFC] border border-[#E4D4FF] rounded-2xl" />
              <div className="w-36 h-16 bg-[#F7FAFC] border border-[#E4D4FF] rounded-2xl" />
            </div>
          </div>
        </div>

        {/* WeeklyRoutineSection Skeleton */}
        <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs animate-pulse">
          <div className="h-5 bg-[#F0E8FF] rounded-lg w-44 mb-4" />
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="p-4 rounded-2xl bg-[#F7FAFC] border border-[#E4D4FF] h-40" />
            ))}
          </div>
        </div>

        {/* LastSessionTable Skeleton */}
        <LoadingState variant="table" />
      </div>
    );
  }

  if (error || !child) {
    return (
      <div className="space-y-4 animate-fade-in">
        <button
          onClick={handleBack}
          className="inline-flex items-center gap-2 text-sm font-bold text-[#8456D2] hover:text-[#432F62] bg-white px-4 py-2 rounded-2xl border border-[#E4D4FF] shadow-2xs hover:shadow-xs transition-all cursor-pointer"
        >
          <ArrowRight className="w-4 h-4" />
          <span>العودة إلى الأطفال</span>
        </button>
        <ErrorState
          message={error || 'الملف غير متوفر أو ليس لديك صلاحية الوصول إليه'}
          onRetry={handleRetry}
        />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in pb-8">
      {/* Back Button matching screenshot (arrow right in RTL) */}
      <button
        onClick={handleBack}
        className="inline-flex items-center gap-2 text-sm font-bold text-[#8456D2] hover:text-[#432F62] bg-white px-4 py-2 rounded-2xl border border-[#E4D4FF] shadow-2xs hover:shadow-xs transition-all cursor-pointer"
      >
        <ArrowRight className="w-4 h-4" />
        <span>العودة إلى الأطفال</span>
      </button>

      {/* Child Profile & Key Metrics Header Card */}
      <ChildHeaderCard child={child} />

      {/* Proposed Weekly Routine / Plan (Read-Only) */}
      <WeeklyRoutineSection targets={weeklyRoutine} />

      {/* Last Session Tasks Details */}
      <LastSessionTable tasks={lastSessionTasks} />

      {/* Doctor Notes Section with Real API Persistence */}
      <DoctorNotesSection
        initialNotes={currentDoctorNotes}
        updatedAt={notesUpdatedAt}
        onSave={handleSaveNotes}
        isLoading={notesLoading}
        fetchError={notesError}
        onRetryFetch={loadNotesOnly}
      />
    </div>
  );
};
