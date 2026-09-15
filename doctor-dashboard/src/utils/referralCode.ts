/**
 * Verified Backend Doctor Referral Code Format:
 * Generated in Backend via `$"DR-{Guid.NewGuid().ToString("N")[..8].ToUpperInvariant()}"`
 * Example: DR-08280ABD
 */
export const DOCTOR_REFERRAL_CODE_REGEX = /^DR-[A-F0-9]{8}$/;

/**
 * Strictly validates that the referral code matches the verified backend format.
 * Format: "DR-" followed by exactly 8 hexadecimal characters.
 */
export function isValidDoctorReferralCode(code?: string | null): boolean {
  if (!code) return false;
  return DOCTOR_REFERRAL_CODE_REGEX.test(code.trim().toUpperCase());
}

/**
 * Normalizes a referral code for QR encoding or display.
 * Returns empty string if invalid.
 */
export function normalizeDoctorReferralCode(code?: string | null): string {
  if (!isValidDoctorReferralCode(code)) return '';
  return code!.trim().toUpperCase();
}
