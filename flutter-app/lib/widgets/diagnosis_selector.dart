import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_text_styles.dart';

/// A diagnosis selector widget that shows predefined diagnosis chips
/// and an optional "Other" text field for custom diagnoses.
///
/// The final diagnosis string is assembled from the selected chips
/// and any custom text entered in the "Other" field.
class DiagnosisSelector extends StatefulWidget {
  const DiagnosisSelector({
    super.key,
    this.onChanged,
    this.validator,
    this.initialValue,
  });

  /// Called whenever the selection/text changes with the combined diagnosis string.
  final void Function(String diagnosis)? onChanged;

  /// Optional validator for FormField integration.
  final String? Function(String?)? validator;

  /// Initial diagnosis string (used if editing existing data).
  final String? initialValue;

  @override
  State<DiagnosisSelector> createState() => _DiagnosisSelectorState();
}

class _DiagnosisSelectorState extends State<DiagnosisSelector> {
  static const List<_DiagnosisOption> _options = [
    _DiagnosisOption(label: 'توحد (ASD)', value: 'توحد'),
    _DiagnosisOption(label: 'ADHD', value: 'ADHD'),
    _DiagnosisOption(label: 'إعاقة ذهنية', value: 'إعاقة ذهنية'),
    _DiagnosisOption(label: 'تأخر في النطق', value: 'تأخر في النطق'),
    _DiagnosisOption(label: 'متلازمة داون', value: 'متلازمة داون'),
    _DiagnosisOption(label: 'صعوبات التعلم', value: 'صعوبات التعلم'),
    _DiagnosisOption(label: 'شلل دماغي', value: 'شلل دماغي'),
  ];

  final Set<String> _selected = {};
  bool _showOtherField = false;
  final _otherController = TextEditingController();
  final _formFieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    // Parse initialValue: split on Arabic comma separator, match known chips,
    // put any unrecognised parts into the "Other" text field.
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      final knownValues = _options.map((o) => o.value).toSet();
      final parts = widget.initialValue!
          .split('،')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      final unrecognised = <String>[];
      for (final part in parts) {
        if (knownValues.contains(part)) {
          _selected.add(part);
        } else {
          unrecognised.add(part);
        }
      }

      if (unrecognised.isNotEmpty) {
        _otherController.text = unrecognised.join('، ');
        _showOtherField = true;
      }
    }
    _otherController.addListener(_notifyChange);
  }

  @override
  void dispose() {
    _otherController.removeListener(_notifyChange);
    _otherController.dispose();
    super.dispose();
  }

  void _toggleChip(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
    _notifyChange();
    _formFieldKey.currentState?.didChange(_buildDiagnosisString());
  }

  void _toggleOther(bool? value) {
    setState(() {
      _showOtherField = value ?? false;
      if (!_showOtherField) {
        _otherController.clear();
      }
    });
    _notifyChange();
    _formFieldKey.currentState?.didChange(_buildDiagnosisString());
  }

  String _buildDiagnosisString() {
    final parts = <String>[..._selected];
    final otherText = _otherController.text.trim();
    if (_showOtherField && otherText.isNotEmpty) {
      parts.add(otherText);
    }
    return parts.join('، ');
  }

  void _notifyChange() {
    widget.onChanged?.call(_buildDiagnosisString());
    _formFieldKey.currentState?.didChange(_buildDiagnosisString());
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _formFieldKey,
      initialValue: _buildDiagnosisString(),
      validator: widget.validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ─── Chips grid ───────────────────────────────────────────
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8.w,
              runSpacing: 8.h,
              children: _options.map((opt) {
                final isSelected = _selected.contains(opt.value);
                return GestureDetector(
                  onTap: () => _toggleChip(opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : const Color(0xffD6D6D6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                        ],
                        Text(
                          opt.label,
                          style: AppTextStyles.font400Regular.copyWith(
                            fontSize: 13.sp,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 8.h),

            // ─── "Other" toggle ───────────────────────────────────────
            GestureDetector(
              onTap: () => _toggleOther(!_showOtherField),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'أخرى (اكتب التشخيص)',
                    style: AppTextStyles.font400Regular.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(5.r),
                      border: Border.all(
                        color: _showOtherField
                            ? AppColors.primaryColor
                            : const Color(0xffD6D6D6),
                        width: 1.5,
                      ),
                      color: _showOtherField
                          ? AppColors.primaryColor
                          : Colors.white,
                    ),
                    child: _showOtherField
                        ? Icon(Icons.check, size: 14.sp, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),

            // ─── "Other" text field ───────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _showOtherField
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: TextFormField(
                  controller: _otherController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.font400Regular.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 13.sp,
                  ),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    hintText: 'اكتب التشخيص هنا...',
                    hintStyle: AppTextStyles.font400Regular.copyWith(
                      color: AppColors.secondaryColor,
                      fontSize: 13.sp,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        width: 1.5,
                        color: Color(0xffD6D6D6),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        width: 1.5,
                        color: Color(0xffD6D6D6),
                      ),
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),

            // ─── Validation error ─────────────────────────────────────
            if (state.hasError) ...[
              SizedBox(height: 4.h),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  state.errorText!,
                  style: AppTextStyles.font400Regular.copyWith(
                    color: Colors.red,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DiagnosisOption {
  const _DiagnosisOption({required this.label, required this.value});
  final String label;
  final String value;
}
