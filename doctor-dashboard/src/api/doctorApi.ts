import { apiClient } from './client';
import type {
  DoctorDashboardDto,
  DoctorChildCardDto,
  DoctorNotesDto,
  UpdateDoctorNotesRequest,
  DoctorLinkRequestSummaryDto,
} from './types';

export const doctorApi = {
  getDashboard: async (): Promise<DoctorDashboardDto> => {
    return apiClient.get<DoctorDashboardDto>('/api/doctor/dashboard');
  },

  getChildren: async (): Promise<DoctorChildCardDto[]> => {
    return apiClient.get<DoctorChildCardDto[]>('/api/doctor/children');
  },

  /**
   * GET /api/doctor/children/{childId}/notes
   * Retrieves clinical note and update timestamp recorded by the assigned doctor for a child.
   */
  getDoctorNotes: async (childId: string): Promise<DoctorNotesDto> => {
    return apiClient.get<DoctorNotesDto>(`/api/doctor/children/${childId}/notes`);
  },

  /**
   * PUT /api/doctor/children/{childId}/notes
   * Updates clinical note recorded by the assigned doctor for a child.
   */
  updateDoctorNotes: async (
    childId: string,
    notes: string | null
  ): Promise<DoctorNotesDto> => {
    const payload: UpdateDoctorNotesRequest = { notes };
    return apiClient.put<DoctorNotesDto>(`/api/doctor/children/${childId}/notes`, payload);
  },

  /**
   * GET /api/doctor/link-requests
   * Retrieves connection requests from parents for this doctor.
   */
  getConnectionRequests: async (): Promise<DoctorLinkRequestSummaryDto[]> => {
    return apiClient.get<DoctorLinkRequestSummaryDto[]>('/api/doctor/link-requests');
  },

  /**
   * POST /api/doctor/link-requests/{id}/approve
   * Approves a pending parent connection request.
   */
  approveConnectionRequest: async (id: string): Promise<DoctorLinkRequestSummaryDto> => {
    return apiClient.post<DoctorLinkRequestSummaryDto>(`/api/doctor/link-requests/${id}/approve`, {});
  },

  /**
   * POST /api/doctor/link-requests/{id}/reject
   * Rejects a pending parent connection request.
   */
  rejectConnectionRequest: async (id: string): Promise<DoctorLinkRequestSummaryDto> => {
    return apiClient.post<DoctorLinkRequestSummaryDto>(`/api/doctor/link-requests/${id}/reject`, {});
  },
};

