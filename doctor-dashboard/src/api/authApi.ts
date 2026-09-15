import { apiClient, setStoredToken, clearStoredAuth } from './client';
import type {
  AuthResponseDto,
  CurrentUserDto,
  LoginRequest,
  RegisterDoctorRequest,
  ForgotPasswordResponse,
  VerifyOtpResponse,
  ResetPasswordResponse,
  ChangePasswordResponse,
  SendVerificationOtpResponse,
  VerifyEmailResponse,
} from './types';

export const authApi = {
  login: async (credentials: LoginRequest): Promise<AuthResponseDto> => {
    const response = await apiClient.post<AuthResponseDto>('/api/auth/login', credentials, {
      skipAuth: true,
    });
    if (response && response.token) {
      setStoredToken(response.token);
    }
    return response;
  },

  registerDoctor: async (data: RegisterDoctorRequest): Promise<AuthResponseDto> => {
    const response = await apiClient.post<AuthResponseDto>('/api/auth/register-doctor', data, {
      skipAuth: true,
    });
    if (response && response.token) {
      setStoredToken(response.token);
    }
    return response;
  },

  getMe: async (): Promise<CurrentUserDto> => {
    return apiClient.get<CurrentUserDto>('/api/auth/me');
  },

  forgotPassword: async (email: string): Promise<ForgotPasswordResponse> => {
    return apiClient.post<ForgotPasswordResponse>(
      '/api/auth/forgot-password',
      { email, platform: 'DoctorDashboard' },
      { skipAuth: true }
    );
  },

  verifyOtp: async (email: string, otp: string): Promise<VerifyOtpResponse> => {
    return apiClient.post<VerifyOtpResponse>(
      '/api/auth/verify-otp',
      { email, otp, platform: 'DoctorDashboard' },
      { skipAuth: true }
    );
  },

  resetPassword: async (
    resetToken: string,
    newPassword: string,
    confirmPassword: string
  ): Promise<ResetPasswordResponse> => {
    return apiClient.post<ResetPasswordResponse>(
      '/api/auth/reset-password',
      { resetToken, newPassword, confirmPassword, platform: 'DoctorDashboard' },
      { skipAuth: true }
    );
  },

  changePassword: async (
    currentPassword: string,
    newPassword: string,
    confirmPassword: string
  ): Promise<ChangePasswordResponse> => {
    return apiClient.post<ChangePasswordResponse>('/api/auth/change-password', {
      currentPassword,
      newPassword,
      confirmPassword,
    });
  },

  sendVerificationOtp: async (email: string): Promise<SendVerificationOtpResponse> => {
    return apiClient.post<SendVerificationOtpResponse>(
      '/api/auth/send-verification-otp',
      { email, platform: 'DoctorDashboard' },
      { skipAuth: true }
    );
  },

  verifyEmail: async (email: string, otp: string): Promise<VerifyEmailResponse> => {
    return apiClient.post<VerifyEmailResponse>(
      '/api/auth/verify-email',
      { email, otp, platform: 'DoctorDashboard' },
      { skipAuth: true }
    );
  },

  logout: (): void => {
    clearStoredAuth();
  },
};

