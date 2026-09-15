import React, { useEffect, useState, useCallback } from 'react';
import {
  UserCheck,
  Check,
  X,
  Clock,
  Calendar,
  User,
  AlertCircle,
  RefreshCw,
  Loader2,
  CheckCircle2,
  XCircle,
} from 'lucide-react';
import { doctorApi } from '../api/doctorApi';
import type { DoctorLinkRequestSummaryDto } from '../api/types';
import { LoadingState } from '../components/common/LoadingState';
import { EmptyState } from '../components/common/EmptyState';
import { ErrorState } from '../components/common/ErrorState';

interface ConnectionRequestsPageProps {
  onNavigateToChild?: (childId: string) => void;
}

type FilterStatus = 'all' | 'Pending' | 'Approved' | 'Rejected';

export const ConnectionRequestsPage: React.FC<ConnectionRequestsPageProps> = ({
  onNavigateToChild,
}) => {
  const [requests, setRequests] = useState<DoctorLinkRequestSummaryDto[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<FilterStatus>('Pending');
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [feedbackMessage, setFeedbackMessage] = useState<{
    type: 'success' | 'error';
    text: string;
    childId?: string;
  } | null>(null);

  const fetchRequests = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await doctorApi.getConnectionRequests();
      setRequests(data);
    } catch (err) {
      console.error('Failed to fetch doctor link requests:', err);
      setError('تعذر تحميل طلبات الربط، يرجى التحقق من الاتصال والمحاولة مرة أخرى.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  const handleApprove = async (request: DoctorLinkRequestSummaryDto) => {
    if (actionLoadingId !== null) return;
    try {
      setActionLoadingId(request.id);
      setFeedbackMessage(null);
      const updated = await doctorApi.approveConnectionRequest(request.id);

      // Update local requests list
      setRequests((prev) =>
        prev.map((r) => (r.id === request.id ? { ...r, status: 'Approved', respondedAtUtc: updated.respondedAtUtc } : r))
      );

      setFeedbackMessage({
        type: 'success',
        text: `تم قبول طلب ربط الطفل "${request.childName}" بنجاح، وأصبح مدرجاً في قائمة أطفالك.`,
        childId: request.childId,
      });
    } catch (err) {
      console.error('Failed to approve request:', err);
      const msg = err instanceof Error ? err.message : 'فشل قبول طلب الربط.';
      setFeedbackMessage({
        type: 'error',
        text: msg,
      });
    } finally {
      setActionLoadingId(null);
    }
  };

  const handleReject = async (request: DoctorLinkRequestSummaryDto) => {
    if (actionLoadingId !== null) return;
    try {
      setActionLoadingId(request.id);
      setFeedbackMessage(null);
      const updated = await doctorApi.rejectConnectionRequest(request.id);

      // Update local requests list
      setRequests((prev) =>
        prev.map((r) => (r.id === request.id ? { ...r, status: 'Rejected', respondedAtUtc: updated.respondedAtUtc } : r))
      );

      setFeedbackMessage({
        type: 'success',
        text: `تم رفض طلب ربط الطفل "${request.childName}".`,
      });
    } catch (err) {
      console.error('Failed to reject request:', err);
      const msg = err instanceof Error ? err.message : 'فشل رفض طلب الربط.';
      setFeedbackMessage({
        type: 'error',
        text: msg,
      });
    } finally {
      setActionLoadingId(null);
    }
  };

  const formatDate = (isoString: string) => {
    try {
      const d = new Date(isoString);
      return d.toLocaleDateString('ar-EG', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    } catch {
      return isoString;
    }
  };

  const pendingCount = requests.filter((r) => r.status === 'Pending').length;
  const approvedCount = requests.filter((r) => r.status === 'Approved').length;
  const rejectedCount = requests.filter((r) => r.status === 'Rejected').length;

  const filteredRequests = requests.filter((r) => {
    if (activeFilter === 'all') return true;
    return r.status === activeFilter;
  });

  if (loading && requests.length === 0) {
    return <LoadingState variant="card" count={3} />;
  }

  if (error && requests.length === 0) {
    return <ErrorState message={error} onRetry={fetchRequests} />;
  }

  return (
    <div className="space-y-6 animate-fade-in pb-8 text-right" dir="rtl">
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs">
        <div>
          <div className="flex items-center gap-2">
            <span className="p-2 rounded-2xl bg-[#F0E8FF] text-[#8456D2] border border-[#E4D4FF]">
              <UserCheck className="w-5 h-5" />
            </span>
            <h2 className="text-xl font-black text-[#432F62]">طلبات ربط الأطفال</h2>
            {pendingCount > 0 && (
              <span className="px-2.5 py-0.5 rounded-full bg-[#BD3737] text-white text-xs font-black animate-pulse">
                {pendingCount} جديد
              </span>
            )}
          </div>
          <p className="text-xs font-semibold text-[#74728A] mt-1">
            مراجعة واعتماد طلبات أولياء الأمور لربط أطفالهم بحسابك الطبي للمتابعة السريرية
          </p>
        </div>

        <button
          onClick={fetchRequests}
          disabled={loading}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-2xl bg-[#F7FAFC] hover:bg-[#F0E8FF] text-[#432F62] text-xs font-bold border border-[#E4D4FF] transition-colors cursor-pointer self-start sm:self-auto"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-[#8456D2]' : ''}`} />
          <span>تحديث الطلبات</span>
        </button>
      </div>

      {/* Feedback Banner */}
      {feedbackMessage && (
        <div
          className={`p-4 rounded-2xl border flex items-center justify-between gap-3 text-right ${
            feedbackMessage.type === 'success'
              ? 'bg-[#E8F5E9] border-[#2E7D32]/30 text-[#1B5E20]'
              : 'bg-[#FFEBEE] border-[#BD3737]/30 text-[#BD3737]'
          }`}
        >
          <div className="flex items-center gap-2 text-xs sm:text-sm font-bold">
            {feedbackMessage.type === 'success' ? (
              <CheckCircle2 className="w-5 h-5 shrink-0" />
            ) : (
              <AlertCircle className="w-5 h-5 shrink-0" />
            )}
            <span>{feedbackMessage.text}</span>
          </div>

          {feedbackMessage.childId && onNavigateToChild && (
            <button
              onClick={() => onNavigateToChild(feedbackMessage.childId!)}
              className="px-3 py-1.5 rounded-xl bg-[#2E7D32] text-white text-xs font-bold hover:bg-[#1B5E20] transition-colors shrink-0 cursor-pointer"
            >
              عرض ملف الطفل
            </button>
          )}
        </div>
      )}

      {/* Filter Tabs */}
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => setActiveFilter('Pending')}
          className={`px-4 py-2 rounded-2xl text-xs font-bold transition-all cursor-pointer flex items-center gap-2 ${
            activeFilter === 'Pending'
              ? 'bg-[#8456D2] text-white shadow-xs'
              : 'bg-white border border-[#E4D4FF] text-[#74728A] hover:bg-[#F0E8FF]/40'
          }`}
        >
          <Clock className="w-4 h-4" />
          <span>قيد الانتظار</span>
          <span
            className={`px-2 py-0.5 rounded-full text-[10px] font-black ${
              activeFilter === 'Pending' ? 'bg-white/20 text-white' : 'bg-[#F0E8FF] text-[#8456D2]'
            }`}
          >
            {pendingCount}
          </span>
        </button>

        <button
          onClick={() => setActiveFilter('Approved')}
          className={`px-4 py-2 rounded-2xl text-xs font-bold transition-all cursor-pointer flex items-center gap-2 ${
            activeFilter === 'Approved'
              ? 'bg-[#8456D2] text-white shadow-xs'
              : 'bg-white border border-[#E4D4FF] text-[#74728A] hover:bg-[#F0E8FF]/40'
          }`}
        >
          <CheckCircle2 className="w-4 h-4" />
          <span>تمت الموافقة</span>
          <span
            className={`px-2 py-0.5 rounded-full text-[10px] font-black ${
              activeFilter === 'Approved' ? 'bg-white/20 text-white' : 'bg-[#F0E8FF] text-[#8456D2]'
            }`}
          >
            {approvedCount}
          </span>
        </button>

        <button
          onClick={() => setActiveFilter('Rejected')}
          className={`px-4 py-2 rounded-2xl text-xs font-bold transition-all cursor-pointer flex items-center gap-2 ${
            activeFilter === 'Rejected'
              ? 'bg-[#8456D2] text-white shadow-xs'
              : 'bg-white border border-[#E4D4FF] text-[#74728A] hover:bg-[#F0E8FF]/40'
          }`}
        >
          <XCircle className="w-4 h-4" />
          <span>المرفوضة</span>
          <span
            className={`px-2 py-0.5 rounded-full text-[10px] font-black ${
              activeFilter === 'Rejected' ? 'bg-white/20 text-white' : 'bg-[#F0E8FF] text-[#8456D2]'
            }`}
          >
            {rejectedCount}
          </span>
        </button>

        <button
          onClick={() => setActiveFilter('all')}
          className={`px-4 py-2 rounded-2xl text-xs font-bold transition-all cursor-pointer flex items-center gap-2 ${
            activeFilter === 'all'
              ? 'bg-[#8456D2] text-white shadow-xs'
              : 'bg-white border border-[#E4D4FF] text-[#74728A] hover:bg-[#F0E8FF]/40'
          }`}
        >
          <span>جميع الطلبات</span>
          <span
            className={`px-2 py-0.5 rounded-full text-[10px] font-black ${
              activeFilter === 'all' ? 'bg-white/20 text-white' : 'bg-[#F0E8FF] text-[#8456D2]'
            }`}
          >
            {requests.length}
          </span>
        </button>
      </div>

      {/* Requests List */}
      {filteredRequests.length === 0 ? (
        <EmptyState
          title={
            activeFilter === 'Pending'
              ? 'لا توجد طلبات ربط قيد الانتظار'
              : activeFilter === 'Approved'
              ? 'لا توجد طلبات معتمدة سابقة'
              : activeFilter === 'Rejected'
              ? 'لا توجد طلبات مرفوضة'
              : 'لا توجد أي طلبات ربط حتى الآن'
          }
          description={
            activeFilter === 'Pending'
              ? 'عندما يقوم ولي الأمر بإدخال كود الإحالة الخاص بك أو مسح رمز QR من تطبيق الهاتف، ستظهر طلبات الربط هنا للمراجعة والاعتماد.'
              : 'جميع طلبات الربط المحدثة ستظهر هنا.'
          }
          icon={<UserCheck className="w-7 h-7 text-[#8456D2]" />}
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredRequests.map((req) => {
            const isPending = req.status === 'Pending';
            const isApproved = req.status === 'Approved';
            const isProcessing = actionLoadingId === req.id;

            return (
              <div
                key={req.id}
                className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs hover:shadow-md transition-shadow flex flex-col justify-between gap-4"
              >
                {/* Top: Status & Date */}
                <div className="flex items-center justify-between gap-2 border-b border-[#F0E8FF] pb-3">
                  <div className="flex items-center gap-1.5 text-xs text-[#74728A] font-semibold">
                    <Calendar className="w-3.5 h-3.5" />
                    <span>{formatDate(req.createdAtUtc)}</span>
                  </div>

                  <span
                    className={`px-3 py-1 rounded-full text-xs font-black inline-flex items-center gap-1 ${
                      isPending
                        ? 'bg-[#FFF3E0] text-[#E65100] border border-[#FFE0B2]'
                        : isApproved
                        ? 'bg-[#E8F5E9] text-[#2E7D32] border border-[#C8E6C9]'
                        : 'bg-[#FFEBEE] text-[#BD3737] border border-[#FFCDD2]'
                    }`}
                  >
                    {isPending ? (
                      <>
                        <Clock className="w-3.5 h-3.5" />
                        <span>قيد الانتظار</span>
                      </>
                    ) : isApproved ? (
                      <>
                        <Check className="w-3.5 h-3.5" />
                        <span>معتمد ومربوط</span>
                      </>
                    ) : (
                      <>
                        <X className="w-3.5 h-3.5" />
                        <span>مرفوض</span>
                      </>
                    )}
                  </span>
                </div>

                {/* Middle: Child & Parent Info */}
                <div className="space-y-3">
                  <div className="flex items-start gap-3">
                    <div className="w-12 h-12 rounded-2xl bg-[#F0E8FF] text-[#8456D2] border border-[#E4D4FF] flex items-center justify-center font-black text-lg shrink-0">
                      {req.childGender === 'Female' ? '👧' : '👦'}
                    </div>
                    <div className="min-w-0 flex-1">
                      <h3 className="text-base font-black text-[#432F62] truncate">{req.childName}</h3>
                      <div className="flex flex-wrap items-center gap-2 mt-1 text-xs font-semibold text-[#74728A]">
                        {req.childAgeYears !== undefined && req.childAgeYears !== null && (
                          <span className="px-2 py-0.5 bg-[#F7FAFC] rounded-lg border border-[#E4D4FF]">
                            {req.childAgeYears} سنوات
                          </span>
                        )}
                        {req.childGender && (
                          <span className="px-2 py-0.5 bg-[#F7FAFC] rounded-lg border border-[#E4D4FF]">
                            {req.childGender === 'Female' ? 'أنثى' : 'ذكر'}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Parent Name */}
                  <div className="p-3 rounded-2xl bg-[#F7FAFC] border border-[#E4D4FF]/70 flex items-center gap-2.5">
                    <User className="w-4 h-4 text-[#8456D2] shrink-0" />
                    <div className="text-xs font-bold text-[#432F62]">
                      <span className="text-[#74728A]">ولي الأمر: </span>
                      <span>{req.parentName}</span>
                    </div>
                  </div>
                </div>

                {/* Actions */}
                {isPending ? (
                  <div className="flex items-center gap-2 pt-2 border-t border-[#F0E8FF]">
                    <button
                      onClick={() => handleApprove(req)}
                      disabled={actionLoadingId !== null}
                      className="flex-1 py-2.5 px-4 rounded-2xl bg-[#2E7D32] hover:bg-[#1B5E20] text-white text-xs font-black transition-all shadow-xs cursor-pointer flex items-center justify-center gap-1.5 disabled:opacity-50"
                    >
                      {isProcessing ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <>
                          <Check className="w-4 h-4" />
                          <span>قبول الطلب</span>
                        </>
                      )}
                    </button>

                    <button
                      onClick={() => handleReject(req)}
                      disabled={actionLoadingId !== null}
                      className="py-2.5 px-4 rounded-2xl bg-[#FFEBEE] hover:bg-[#FFCDD2] text-[#BD3737] text-xs font-bold border border-[#FFCDD2] transition-all cursor-pointer flex items-center justify-center gap-1.5 disabled:opacity-50"
                    >
                      {actionLoadingId === req.id ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <>
                          <X className="w-4 h-4" />
                          <span>رفض</span>
                        </>
                      )}
                    </button>
                  </div>
                ) : isApproved && onNavigateToChild ? (
                  <div className="pt-2 border-t border-[#F0E8FF]">
                    <button
                      onClick={() => onNavigateToChild(req.childId)}
                      className="w-full py-2 px-4 rounded-2xl bg-[#F0E8FF] hover:bg-[#E4D4FF] text-[#432F62] text-xs font-black border border-[#E4D4FF] transition-colors cursor-pointer flex items-center justify-center gap-1.5"
                    >
                      <span>الانتقال إلى الملف النمائي للطفل</span>
                    </button>
                  </div>
                ) : null}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
