import doctorFemaleImg from '../assets/doctor-female.png';
import doctorMaleImg from '../assets/doctor-male.png';
import doctorNeutralImg from '../assets/doctor-neutral.svg';

/**
 * Single source of truth for Doctor avatar resolution.
 * Strictly driven by persisted backend Doctor.Gender.
 *
 * Rules:
 * - Female ('female', '2') → doctor-female.png
 * - Male ('male', '1') → doctor-male.png
 * - Other / null / unknown → neutral professional fallback (doctor-neutral.svg)
 *
 * Strictly NO name-based guessing or manual override toggles.
 */
export function resolveDoctorAvatar(gender?: string | null): string {
  if (!gender) {
    return doctorNeutralImg;
  }

  const normalized = gender.toString().trim().toLowerCase();

  if (normalized === 'female' || normalized === '2' || normalized === 'أنثى' || normalized === 'انثى') {
    return doctorFemaleImg;
  }

  if (normalized === 'male' || normalized === '1' || normalized === 'ذكر') {
    return doctorMaleImg;
  }

  return doctorNeutralImg;
}

export { doctorFemaleImg, doctorMaleImg, doctorNeutralImg };
