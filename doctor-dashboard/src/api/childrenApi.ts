import { apiClient } from './client';
import type {
  ChildDetailsDto,
  ChildProgressSummaryDto,
  SessionHistoryPointDto,
  ActivityPerformanceDto,
} from './types';

export interface ProgressHistoryQueryParams {
  domain?: string;
  fromDate?: string;
  toDate?: string;
  page?: number;
  pageSize?: number;
}

export const childrenApi = {
  /**
   * GET /api/children/{childId}
   * Fetches detailed profile of the child (requires Parent ownership or active Doctor assignment).
   */
  getChildDetails: (childId: string): Promise<ChildDetailsDto> =>
    apiClient.get<ChildDetailsDto>(`/api/children/${childId}`),

  /**
   * GET /api/children/{childId}/progress
   * Fetches aggregate progress summary and domain breakdowns.
   */
  getChildProgress: (childId: string): Promise<ChildProgressSummaryDto> =>
    apiClient.get<ChildProgressSummaryDto>(`/api/children/${childId}/progress`),

  /**
   * GET /api/children/{childId}/progress/history
   * Fetches historical session scores and activity timeline.
   */
  getChildProgressHistory: (
    childId: string,
    params?: ProgressHistoryQueryParams
  ): Promise<SessionHistoryPointDto[]> => {
    const searchParams = new URLSearchParams();
    if (params?.domain) searchParams.append('domain', params.domain);
    if (params?.fromDate) searchParams.append('fromDate', params.fromDate);
    if (params?.toDate) searchParams.append('toDate', params.toDate);
    if (params?.page) searchParams.append('page', params.page.toString());
    if (params?.pageSize) searchParams.append('pageSize', params.pageSize.toString());

    const query = searchParams.toString();
    const endpoint = `/api/children/${childId}/progress/history${query ? `?${query}` : ''}`;
    return apiClient.get<SessionHistoryPointDto[]>(endpoint);
  },

  /**
   * GET /api/children/{childId}/activities/performance
   * Fetches cumulative activity-level metrics and scores for this child.
   */
  getChildActivityPerformance: (childId: string): Promise<ActivityPerformanceDto[]> =>
    apiClient.get<ActivityPerformanceDto[]>(`/api/children/${childId}/activities/performance`),
};
