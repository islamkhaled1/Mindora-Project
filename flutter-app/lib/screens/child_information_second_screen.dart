// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:iconify_flutter/iconify_flutter.dart';
// import 'package:iconify_flutter/icons/ant_design.dart';
// import 'package:iconify_flutter/icons/bxs.dart';
// import 'package:sawa/constants.dart';
// import 'package:sawa/screens/doctor_or_ai_screen.dart';
// import 'package:sawa/widgets/back_icon.dart';
// import 'package:sawa/widgets/custom_app_bar.dart';
// import 'package:sawa/widgets/custom_elevated_button.dart';
// import 'package:sawa/widgets/custom_multi_select.dart';
// import 'package:sawa/widgets/custom_padding.dart';
// import 'package:sawa/widgets/custom_radio_group.dart';
// import 'package:sawa/widgets/custom_text_field.dart';
// import 'package:sawa/widgets/custom_time_range_field.dart';
// import 'package:sawa/widgets/custom_title.dart';
// import 'package:sawa/widgets/description.dart';
// import 'package:sawa/widgets/simi_bold_title.dart';
// import 'package:iconify_flutter/icons/entypo.dart';
// import 'package:iconify_flutter/icons/material_symbols.dart';

// class ChildInformationSecondScreen extends StatefulWidget {
//   ChildInformationSecondScreen({super.key});

//   @override
//   State<ChildInformationSecondScreen> createState() =>
//       _ChildInformationSecondScreenState();
// }

// class _ChildInformationSecondScreenState
//     extends State<ChildInformationSecondScreen> {
//   TimeOfDay? startTime;

//   TimeOfDay? endTime;
//   String? hearingStatus;
//   String? visionStatus;
//   List<String> preferredActivities = [];
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: CustomAppBar(leading: BackIcon()),
//       body: CustomPadding(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Center(
//                 child: CustomTitle(
//                   title: 'بعض التفاصيل الإضافية',
//                   fontSize: 23,
//                 ),
//               ),
//               SizedBox(height: 8.h),
//               Center(
//                 child: Description(
//                   text: 'يساعدنا هذا في إنشاء أنشطة أفضل لطفلك.',
//                   fontSize: 12,
//                 ),
//               ),
//               SizedBox(height: 12.h),
//               Align(
//                 alignment: AlignmentGeometry.centerRight,
//                 child: SimiBoldTitle(
//                   title: 'مستوى الدعم المطلوب',
//                   fontSize: 12,
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
//                 child: CustomTextField(hint: 'درجة الدعم', height: 40),
//               ),
//               SizedBox(height: 4.h),
//               Align(
//                 alignment: AlignmentGeometry.centerRight,
//                 child: SimiBoldTitle(title: 'أفضل وقت للممارسة؟', fontSize: 12),
//               ),
//               Padding(
//                 padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
//                 child: CustomTimeRangeField(
//                   hint: 'حدد النطاق الزمني',
//                   suffixIcon: Iconify(
//                     Bxs.time_five,
//                     color: AppColors.primaryColor,
//                   ),
//                   onTimeRangeSelected: (from, to) {
//                     startTime = from;
//                     endTime = to;
//                   },
//                 ),
//               ),
//               SizedBox(height: 4.h),
//               Align(
//                 alignment: AlignmentGeometry.centerRight,
//                 child: SimiBoldTitle(
//                   title: 'كم من الوقت يمكنه التركيز؟',
//                   fontSize: 12,
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
//                 child: CustomTextField(
//                   hint: 'حدد المدة',
//                   height: 40,
//                   prefixIcon: Entypo.hour_glass,
//                 ),
//               ),
//               SizedBox(height: 10.h),
//               Align(
//                 alignment: AlignmentGeometry.centerRight,
//                 child: SimiBoldTitle(
//                   title: 'حالة السمع (إن وجد)',
//                   fontSize: 12,
//                 ),
//               ),
//               SizedBox(height: 6.h),
//               CustomRadioGroup(
//                 firstTitle: 'يعاني من صعوبة',
//                 firstIcon: const Iconify(
//                   MaterialSymbols.hearing_disabled,
//                   size: 20,
//                   color: AppColors.primaryColor,
//                 ),
//                 firstValue: 'difficulty',

//                 secondTitle: 'طبيعي',
//                 secondIcon: const Iconify(
//                   AntDesign.check_circle_filled,
//                   size: 25,
//                   color: AppColors.primaryColor,
//                 ),
//                 secondValue: 'normal',

//                 onChanged: (value) {
//                   hearingStatus = value;
//                 },
//               ),
//               SizedBox(height: 16.h),
//               Align(
//                 alignment: AlignmentGeometry.centerRight,
//                 child: SimiBoldTitle(
//                   title: 'حالة البصر (إن وجد)',
//                   fontSize: 12,
//                 ),
//               ),
//               SizedBox(height: 6.h),
//               CustomRadioGroup(
//                 firstTitle: 'يعاني من صعوبة',
//                 firstIcon: const Iconify(
//                   MaterialSymbols.visibility_off_outline,
//                   size: 20,
//                   color: AppColors.primaryColor,
//                 ),
//                 firstValue: 'difficulty',

//                 secondTitle: 'طبيعي',
//                 secondIcon: const Iconify(
//                   AntDesign.check_circle_filled,
//                   size: 25,
//                   color: AppColors.primaryColor,
//                 ),
//                 secondValue: 'normal',

//                 onChanged: (value) {
//                   visionStatus = value;
//                 },
//               ),
//               SizedBox(height: 16.h),
//               Align(
//                 alignment: AlignmentGeometry.centerRight,
//                 child: SimiBoldTitle(title: 'نوع النشاط المفضل', fontSize: 12),
//               ),
//               SizedBox(height: 6.h),
//               CustomMultiSelect(
//                 options: [
//                   MultiSelectOption(
//                     title: 'القصص والتعلم',
//                     value: 'learning',
//                     icon: Icon(
//                       Icons.menu_book,
//                       size: 55,
//                       color: Color(0xff50366E),
//                     ),
//                   ),
//                   MultiSelectOption(
//                     title: 'الألعاب واللعب',
//                     value: 'games',
//                     icon: Icon(
//                       Icons.sports_esports,
//                       size: 55,
//                       color: Color(0xff50366E),
//                     ),
//                   ),
//                 ],
//                 onChanged: (selectedValues) {
//                   preferredActivities = selectedValues;
//                 },
//               ),
//               SizedBox(height: 16.h),
//               // CustomElevatedButton(
//               //   title: 'متابعة',
//               //   targetScreen: DoctorOrAiScreen(),
//               //   width: 165,
//               //   height: 40,
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ant_design.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/screens/doctor_or_ai_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_multi_select.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_radio_group.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import '../core/errors/api_exception.dart';
import '../core/models/child_enums.dart';
import '../core/services/children_service.dart';
import '../core/state/child_intake_state.dart';

class ChildInformationSecondScreen extends StatefulWidget {
  final ChildIntakeState? intakeState;

  ChildInformationSecondScreen({super.key, this.intakeState});

  @override
  State<ChildInformationSecondScreen> createState() =>
      _ChildInformationSecondScreenState();
}

class _ChildInformationSecondScreenState
    extends State<ChildInformationSecondScreen> {
  final _formKey = GlobalKey<FormState>();

  late final ChildIntakeState _intakeState =
      widget.intakeState ?? ChildIntakeState();

  SupportLevelTier? _selectedSupportTier;
  String? _selectedPracticeSlot; // e.g. 'صباحاً'
  int? _selectedFocusMinutes;   // e.g. 15
  String? hearingStatus;
  String? visionStatus;
  List<String> preferredActivities = [];
  bool _isLoading = false;

  // ─── Preset options ───────────────────────────────────────────────
  static const List<_PracticeSlot> _practiceSlots = [
    _PracticeSlot(label: '🌅 صباحاً',  value: 'صباحاً'),
    _PracticeSlot(label: '☀️ ظهراً',   value: 'ظهراً'),
    _PracticeSlot(label: '🌆 مساءً',   value: 'مساءً'),
    _PracticeSlot(label: '🌙 ليلاً',   value: 'ليلاً'),
  ];

  static const List<int> _focusOptions = [5, 10, 15, 20, 30, 45];

  @override
  void dispose() {
    super.dispose();
  }



  Future<void> _handleContinue() async {
    // Validate support tier selection first
    if (_selectedSupportTier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مستوى الدعم المطلوب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final parsedFocusDuration = _selectedFocusMinutes;

    setState(() => _isLoading = true);

    try {
      // Populate Step 2 data into intakeState
      _intakeState.rawSupportLevelText = _selectedSupportTier!.arabicLabel;
      _intakeState.supportLevelTier = _selectedSupportTier;
      _intakeState.preferredPracticeTime = _selectedPracticeSlot;
      _intakeState.focusDurationMinutes = parsedFocusDuration;
      _intakeState.hearingStatus = hearingStatus;
      _intakeState.visionStatus = visionStatus;
      _intakeState.preferredActivities = preferredActivities;

      final request = _intakeState.toCreateChildRequest();

      final childrenService = ChildrenService();
      await childrenService.createChild(request);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DoctorOrAiScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.firstErrorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('StateError: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: CustomTitle(
                    title: 'بعض التفاصيل الإضافية',
                    fontSize: 23,
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Description(
                    text: 'يساعدنا هذا في إنشاء أنشطة أفضل لطفلك.',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 12.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'مستوى الدعم المطلوب',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: SupportLevelTier.values.reversed.map((tier) {
                    final isSelected = _selectedSupportTier == tier;
                    final colors = {
                      SupportLevelTier.mild: const Color(0xff6DAA60),
                      SupportLevelTier.moderate: const Color(0xffFDB62C),
                      SupportLevelTier.high: const Color(0xffCF6F69),
                    };
                    final activeColor = colors[tier]!;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSupportTier = tier;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 56.h,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isSelected
                                    ? activeColor
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
                            child: Center(
                              child: Text(
                                tier.arabicLabel,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
                // ─── Practice time slot ───────────────────────────────
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'أفضل وقت للممارسة؟',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: _practiceSlots.map((slot) {
                    final isSelected = _selectedPracticeSlot == slot.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPracticeSlot = slot.value;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
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
                            child: Center(
                              child: Text(
                                slot.label,
                                textAlign: TextAlign.center,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),
                // ─── Focus duration chips ─────────────────────────────
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'كم من الوقت يمكنه التركيز؟',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _focusOptions.map((minutes) {
                    final isSelected = _selectedFocusMinutes == minutes;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFocusMinutes = minutes;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondaryTextColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondaryTextColor
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
                        child: Text(
                          '$minutes دقيقة',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'حالة السمع (إن وجد)',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 6.h),
                CustomRadioGroup(
                  firstTitle: 'يعاني من صعوبة',
                  firstIcon: Iconify(
                    MaterialSymbols.hearing_disabled,
                    size: 20.sp,
                    color: AppColors.primaryColor,
                  ),
                  firstValue: 'difficulty',

                  secondTitle: 'طبيعي',
                  secondIcon: Iconify(
                    AntDesign.check_circle_filled,
                    size: 25.sp,
                    color: AppColors.primaryColor,
                  ),
                  secondValue: 'normal',

                  onChanged: (value) {
                    setState(() {
                      hearingStatus = value;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'حالة البصر (إن وجد)',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 6.h),
                CustomRadioGroup(
                  firstTitle: 'يعاني من صعوبة',
                  firstIcon: Iconify(
                    MaterialSymbols.visibility_off_outline,
                    size: 20.sp,
                    color: AppColors.primaryColor,
                  ),
                  firstValue: 'difficulty',

                  secondTitle: 'طبيعي',
                  secondIcon: Iconify(
                    AntDesign.check_circle_filled,
                    size: 25.sp,
                    color: AppColors.primaryColor,
                  ),
                  secondValue: 'normal',

                  onChanged: (value) {
                    setState(() {
                      visionStatus = value;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'نوع النشاط المفضل',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 6.h),
                CustomMultiSelect(
                  options: [
                    MultiSelectOption(
                      title: 'القصص والتعلم',
                      value: 'learning',
                      icon: Icon(
                        Icons.menu_book,
                        size: 55.sp,
                        color: Color(0xff50366E),
                      ),
                    ),
                    MultiSelectOption(
                      title: 'الألعاب واللعب',
                      value: 'games',
                      icon: Icon(
                        Icons.sports_esports,
                        size: 55.sp,
                        color: Color(0xff50366E),
                      ),
                    ),
                  ],
                  onChanged: (selectedValues) {
                    setState(() {
                      preferredActivities = selectedValues;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                CustomElevatedButton(
                  title: 'متابعة',
                  isLoading: _isLoading,
                  onPressed: _handleContinue,
                  width: 165,
                  height: 40,
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple data class for a practice time slot option.
class _PracticeSlot {
  const _PracticeSlot({required this.label, required this.value});
  final String label;
  final String value;
}
