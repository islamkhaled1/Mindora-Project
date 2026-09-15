import React, { useState } from 'react';
import { Save, CheckCircle2, Clock, Loader2, AlertCircle, RotateCcw } from 'lucide-react';

const MAX_NOTES_LENGTH = 2000;

interface DoctorNotesSectionProps {
  initialNotes?: string;
  updatedAt?: string;
  onSave: (notes: string) => Promise<{ notes: string; updatedAt: string }>;
  isLoading?: boolean;
  fetchError?: string | null;
  onRetryFetch?: () => void;
}

export const DoctorNotesSection: React.FC<DoctorNotesSectionProps> = ({
  initialNotes = '',
  updatedAt,
  onSave,
  isLoading = false,
  fetchError = null,
  onRetryFetch,
}) => {
  const [notes, setNotes] = useState(initialNotes);
  const [prevInitialNotes, setPrevInitialNotes] = useState(initialNotes);
  const [lastUpdated, setLastUpdated] = useState<string | undefined>(updatedAt);
  const [prevUpdatedAt, setPrevUpdatedAt] = useState<string | undefined>(updatedAt);
  const [isSaving, setIsSaving] = useState(false);
  const [showSuccessToast, setShowSuccessToast] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  // Sync state during render if props change externally
  if (initialNotes !== prevInitialNotes) {
    setPrevInitialNotes(initialNotes);
    setNotes(initialNotes);
  }
  if (updatedAt !== prevUpdatedAt) {
    setPrevUpdatedAt(updatedAt);
    setLastUpdated(updatedAt);
  }

  const isDirty = notes !== initialNotes;
  const isTooLong = notes.length > MAX_NOTES_LENGTH;
  const charsRemaining = MAX_NOTES_LENGTH - notes.length;

  const handleCancel = () => {
    setNotes(initialNotes);
    setSaveError(null);
  };

  const handleSave = async () => {
    if (isTooLong || !isDirty || isSaving) return;

    try {
      setIsSaving(true);
      setSaveError(null);
      const res = await onSave(notes);
      setLastUpdated(res.updatedAt);
      setPrevUpdatedAt(res.updatedAt);
      setPrevInitialNotes(res.notes);
      setShowSuccessToast(true);
      setTimeout(() => setShowSuccessToast(false), 3000);
    } catch (err) {
      console.error('Failed to save notes:', err);
      const msg =
        err instanceof Error ? err.message : 'تعذر حفظ الملاحظة، يرجى المحاولة لاحقاً.';
      setSaveError(msg);
      setTimeout(() => setSaveError(null), 6000);
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs animate-pulse space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div className="space-y-1.5">
            <div className="h-5 bg-[#F0E8FF] rounded-xl w-32" />
            <div className="h-3 bg-[#F0E8FF]/60 rounded-lg w-56" />
          </div>
          <div className="h-7 bg-[#F0E8FF] rounded-xl w-40" />
        </div>
        <div className="h-28 bg-[#F7FAFC] border border-[#E4D4FF] rounded-2xl" />
        <div className="flex justify-between items-center pt-1">
          <div className="h-3 bg-[#F0E8FF]/60 rounded w-48" />
          <div className="h-10 bg-[#F0E8FF] rounded-2xl w-32" />
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs">
      {/* Section Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-4">
        <div>
          <h3 className="text-lg font-black text-[#432F62]">ملاحظات الطبيب</h3>
          <p className="text-xs text-[#74728A] font-semibold mt-0.5">
            سجل الملاحظات والتوصيات الخاصة بمتابعة ودعم الطفل (الحد الأقصى 2000 حرف)
          </p>
        </div>

        {/* Timestamp */}
        {lastUpdated && (
          <div className="flex items-center gap-1.5 text-xs text-[#432F62] font-bold bg-[#F0E8FF] px-3.5 py-1.5 rounded-xl border border-[#E4D4FF]">
            <Clock className="w-3.5 h-3.5 text-[#8456D2]" />
            <span>آخر تحديث: {lastUpdated}</span>
          </div>
        )}
      </div>

      {/* Fetch Error Banner with Retry */}
      {fetchError && (
        <div className="mb-4 flex items-center justify-between p-3 rounded-2xl bg-[#FFD4CA] border border-[#BD3737]/40 text-[#BD3737] text-xs font-bold animate-fade-in">
          <div className="flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{fetchError}</span>
          </div>
          {onRetryFetch && (
            <button
              onClick={onRetryFetch}
              className="px-3 py-1 rounded-xl bg-white text-[#BD3737] hover:bg-[#FAF8FF] transition-all cursor-pointer font-black text-xs shadow-2xs"
            >
              إعادة المحاولة
            </button>
          )}
        </div>
      )}

      {/* Textarea Input */}
      <div className="relative mb-2">
        <textarea
          rows={4}
          value={notes}
          disabled={isSaving}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="اكتب ملاحظاتك وتوصياتك لمتابعة ودعم الطفل..."
          className={`w-full p-4 rounded-2xl bg-[#F7FAFC] border ${
            isTooLong ? 'border-[#BD3737] focus:border-[#BD3737]' : 'border-[#E4D4FF] focus:border-[#8456D2]'
          } text-sm text-[#432F62] placeholder-[#74728A] focus:outline-none focus:bg-white transition-all resize-y leading-relaxed font-semibold disabled:opacity-70 disabled:cursor-not-allowed`}
        />
      </div>

      {/* Counter & Length Validation */}
      <div className="flex items-center justify-between text-xs mb-4">
        {isTooLong ? (
          <span className="text-[#BD3737] font-bold flex items-center gap-1">
            <AlertCircle className="w-3.5 h-3.5" />
            تجاوزت الحد الأقصى للملاحظات بمقدار {Math.abs(charsRemaining)} حرف.
          </span>
        ) : (
          <span className="text-[#74728A] font-medium">
            {isDirty ? 'لديك تعديلات غير محفوظة' : 'يتم حفظ الملاحظات وتحديثها في سجل متابعة الطفل'}
          </span>
        )}
        <span
          className={`font-mono text-xs font-bold ${
            isTooLong ? 'text-[#BD3737]' : charsRemaining < 200 ? 'text-[#FDB62C]' : 'text-[#74728A]'
          }`}
        >
          {notes.length} / {MAX_NOTES_LENGTH}
        </span>
      </div>

      {/* Footer Controls: Status Toast + Action Buttons */}
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div>
          {showSuccessToast ? (
            <div className="flex items-center gap-1.5 text-xs font-black text-[#6DAA60] bg-[#EEF3EE] px-3 py-1.5 rounded-xl border border-[#6DAA60]/40 animate-fade-in">
              <CheckCircle2 className="w-4 h-4" />
              <span>تم حفظ الملاحظة بنجاح</span>
            </div>
          ) : saveError ? (
            <div className="flex items-center gap-1.5 text-xs font-bold text-[#BD3737] bg-[#FFD4CA] px-3 py-1.5 rounded-xl border border-[#BD3737]/40 animate-fade-in">
              <AlertCircle className="w-4 h-4" />
              <span>{saveError}</span>
            </div>
          ) : null}
        </div>

        <div className="flex items-center gap-2.5 mr-auto">
          {/* Cancel / Reset Button */}
          {isDirty && (
            <button
              onClick={handleCancel}
              disabled={isSaving}
              className="flex items-center gap-1.5 px-4 py-2.5 rounded-2xl bg-[#F0E8FF] hover:bg-[#E4D4FF] text-[#432F62] text-xs font-bold transition-all cursor-pointer border border-[#E4D4FF] disabled:opacity-60 disabled:cursor-not-allowed"
            >
              <RotateCcw className="w-3.5 h-3.5 text-[#8456D2]" />
              <span>تراجع عن التعديل</span>
            </button>
          )}

          {/* Save Button */}
          <button
            onClick={handleSave}
            disabled={isSaving || !isDirty || isTooLong}
            className="flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-[#432F62] hover:bg-[#8456D2] active:scale-98 text-white text-sm font-black shadow-xs hover:shadow-md transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isSaving ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>جارٍ الحفظ...</span>
              </>
            ) : (
              <>
                <Save className="w-4 h-4" />
                <span>حفظ الملاحظة</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
