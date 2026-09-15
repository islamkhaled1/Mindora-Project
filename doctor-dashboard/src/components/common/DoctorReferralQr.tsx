import React, { useState, useRef } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { Copy, Check, Download, AlertCircle, QrCode } from 'lucide-react';
import { isValidDoctorReferralCode, normalizeDoctorReferralCode } from '../../utils/referralCode';

export interface DoctorReferralQrProps {
  referralCode?: string | null;
  size?: number;
  showCard?: boolean;
  showActions?: boolean;
  className?: string;
}

export const DoctorReferralQr: React.FC<DoctorReferralQrProps> = ({
  referralCode,
  size = 180,
  showCard = true,
  showActions = true,
  className = '',
}) => {
  const [copied, setCopied] = useState(false);
  const qrRef = useRef<HTMLDivElement>(null);

  const isValid = isValidDoctorReferralCode(referralCode);
  const cleanCode = normalizeDoctorReferralCode(referralCode);

  const handleCopy = () => {
    if (!isValid) return;
    navigator.clipboard.writeText(cleanCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownload = () => {
    if (!isValid || !qrRef.current) return;
    const svgElement = qrRef.current.querySelector('svg');
    if (!svgElement) return;

    const svgData = new XMLSerializer().serializeToString(svgElement);
    const svgBlob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
    const svgUrl = URL.createObjectURL(svgBlob);

    const downloadLink = document.createElement('a');
    downloadLink.href = svgUrl;
    downloadLink.download = `doctor-referral-${cleanCode}.svg`;
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
    URL.revokeObjectURL(svgUrl);
  };

  // Safe fallback state for missing or invalid referral code
  if (!isValid) {
    return (
      <div
        dir="rtl"
        className={`flex flex-col items-center justify-center p-6 text-center bg-[#F7FAFC] rounded-2xl border border-[#E4D4FF] ${className}`}
      >
        <AlertCircle className="w-8 h-8 text-[#BD3737] mb-2" />
        <p className="text-sm font-bold text-[#432F62]">رمز الإحالة غير متاح حاليًا</p>
        <p className="text-xs text-[#74728A] mt-1 font-medium">
          يرجى التأكد من تسجيل الدخول بحساب طبيب معتمد.
        </p>
      </div>
    );
  }

  const qrContent = (
    <div dir="rtl" className="flex flex-col items-center text-center select-none">
      {/* Title */}
      <div className="flex items-center gap-1.5 text-[#432F62] font-black text-sm mb-3">
        <QrCode className="w-4 h-4 text-[#8456D2]" />
        <span>رمز الإحالة للطبيب</span>
      </div>

      {/* Code Display + Copy Button */}
      <div className="flex items-center gap-2 px-3.5 py-1.5 bg-[#F0E8FF] border border-[#E4D4FF] rounded-xl mb-4 shadow-2xs">
        <span className="font-mono text-base font-extrabold text-[#8456D2] tracking-wider">
          {cleanCode}
        </span>
        <button
          onClick={handleCopy}
          title="نسخ الرمز"
          className="p-1 hover:bg-[#E4D4FF] rounded-lg transition-colors cursor-pointer text-[#8456D2]"
          aria-label="نسخ كود الإحالة"
        >
          {copied ? (
            <Check className="w-4 h-4 text-[#6DAA60]" />
          ) : (
            <Copy className="w-4 h-4" />
          )}
        </button>
        {copied && (
          <span className="text-[11px] text-[#6DAA60] font-bold">تم النسخ!</span>
        )}
      </div>

      {/* QR Code Container with Frame: Payload is strictly cleanCode (e.g. DR-XXXXXXXX) */}
      <div
        ref={qrRef}
        className="p-4 bg-white rounded-2xl border-2 border-[#E4D4FF] shadow-xs flex items-center justify-center"
      >
        <QRCodeSVG
          value={cleanCode}
          size={size}
          level="M"
          marginSize={1}
          className="rounded-lg"
        />
      </div>

      {/* Neutral Instruction (Zero treatment/diagnosis/clinical claims) */}
      <p className="text-xs text-[#74728A] font-semibold mt-3 max-w-[220px] leading-relaxed">
        امسح رمز QR لربط الطفل بهذا الطبيب
      </p>

      {/* Action Buttons: Copy & Download SVG */}
      {showActions && (
        <div className="flex items-center gap-2 mt-4 w-full">
          <button
            onClick={handleCopy}
            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl bg-[#F0E8FF] hover:bg-[#E4D4FF] text-[#432F62] text-xs font-bold transition-colors cursor-pointer shadow-2xs border border-[#E4D4FF]"
          >
            {copied ? (
              <>
                <Check className="w-3.5 h-3.5 text-[#6DAA60]" />
                <span className="text-[#6DAA60]">تم النسخ</span>
              </>
            ) : (
              <>
                <Copy className="w-3.5 h-3.5 text-[#8456D2]" />
                <span>نسخ الرمز</span>
              </>
            )}
          </button>
          <button
            onClick={handleDownload}
            title="تحميل رمز QR بصيغة SVG"
            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl bg-white hover:bg-[#F0E8FF]/60 text-[#432F62] text-xs font-bold transition-colors cursor-pointer shadow-2xs border border-[#E4D4FF]"
          >
            <Download className="w-3.5 h-3.5 text-[#8456D2]" />
            <span>تحميل QR</span>
          </button>
        </div>
      )}
    </div>
  );

  if (!showCard) {
    return <div className={className}>{qrContent}</div>;
  }

  return (
    <div
      className={`bg-white rounded-3xl border border-[#E4D4FF] p-5 shadow-sm ${className}`}
    >
      {qrContent}
    </div>
  );
};
