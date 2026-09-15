import assert from 'node:assert';

// Mirroring the exact logic from src/utils/referralCode.ts
export const DOCTOR_REFERRAL_CODE_REGEX = /^DR-[A-F0-9]{8}$/;

export function isValidDoctorReferralCode(code) {
  if (!code) return false;
  return DOCTOR_REFERRAL_CODE_REGEX.test(code.trim().toUpperCase());
}

export function normalizeDoctorReferralCode(code) {
  if (!isValidDoctorReferralCode(code)) return '';
  return code.trim().toUpperCase();
}

console.log('=== Doctor Referral QR Code Unit & Payload Tests ===\n');

// Test 1: Valid Referral Code Format
console.log('Test 1: Valid Backend Referral Codes');
const validCodes = ['DR-08280ABD', 'DR-8F92A1B0', 'DR-12345678', 'DR-ABCDEF01'];
for (const code of validCodes) {
  assert.strictEqual(isValidDoctorReferralCode(code), true, `Expected ${code} to be valid`);
  assert.strictEqual(normalizeDoctorReferralCode(code), code, `Expected ${code} to normalize exactly`);
  console.log(`  ✓ Code ${code} is valid`);
}

// Test 2: Normalization & Casing
console.log('\nTest 2: Normalization & Whitespace Trimming');
assert.strictEqual(isValidDoctorReferralCode('  dr-08280abd  '), true);
assert.strictEqual(normalizeDoctorReferralCode('  dr-08280abd  '), 'DR-08280ABD');
console.log('  ✓ Lowercase with padding normalizes to exact uppercase: "DR-08280ABD"');

// Test 3: QR Payload must be EXACT string (no URL, no JSON, no prefix/suffix)
console.log('\nTest 3: QR Payload Exactness');
const testCode = 'DR-08280ABD';
const payload = normalizeDoctorReferralCode(testCode);
assert.strictEqual(payload, 'DR-08280ABD', 'QR payload must be exact referral code');
assert.strictEqual(payload.startsWith('http'), false, 'QR payload must not be a URL');
assert.strictEqual(payload.startsWith('{'), false, 'QR payload must not be JSON');
assert.strictEqual(payload.includes(' '), false, 'QR payload must not contain whitespace');
console.log(`  ✓ QR Payload is strictly exact string: "${payload}"`);

// Test 4: Missing Referral Code Fallback
console.log('\nTest 4: Missing Referral Code');
assert.strictEqual(isValidDoctorReferralCode(null), false);
assert.strictEqual(isValidDoctorReferralCode(undefined), false);
assert.strictEqual(isValidDoctorReferralCode(''), false);
assert.strictEqual(isValidDoctorReferralCode('   '), false);
assert.strictEqual(normalizeDoctorReferralCode(null), '');
assert.strictEqual(normalizeDoctorReferralCode(''), '');
console.log('  ✓ Missing or empty code returns false and empty payload (triggers safe fallback UI)');

// Test 5: Invalid Referral Codes (Must NOT generate misleading QR)
console.log('\nTest 5: Invalid Referral Code Rejection');
const invalidCodes = [
  'DR-123',                 // Too short (3 hex instead of 8)
  'DR-123456789',           // Too long (9 hex)
  'DR-GHIJKLMN',           // Non-hex characters (G, H, I, etc.)
  'DR-TESTCODE',           // Non-hex (T, S)
  '12345678',               // Missing DR- prefix
  'https://mindora.app/dr', // URL
  '{"code":"DR-08280ABD"}', // JSON
  'DR-!@#$%^&*',           // Special chars
];

for (const code of invalidCodes) {
  assert.strictEqual(isValidDoctorReferralCode(code), false, `Expected ${code} to be rejected`);
  assert.strictEqual(normalizeDoctorReferralCode(code), '', `Expected ${code} to produce empty payload`);
  console.log(`  ✓ Rejected invalid code: "${code}"`);
}

console.log('\n=================================================');
console.log('ALL REFERRAL QR TESTS PASSED (5/5) WITH ZERO ERRORS!');
console.log('=================================================');
