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
import 'package:iconify_flutter/icons/bxs.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/doctor_or_ai_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_multi_select.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_radio_group.dart';
import 'package:sawa/widgets/custom_text_field.dart';
import 'package:sawa/widgets/custom_time_range_field.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:iconify_flutter/icons/entypo.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';

class ChildInformationSecondScreen extends StatefulWidget {
  ChildInformationSecondScreen({super.key});

  @override
  State<ChildInformationSecondScreen> createState() =>
      _ChildInformationSecondScreenState();
}

class _ChildInformationSecondScreenState
    extends State<ChildInformationSecondScreen> {
  final _formKey = GlobalKey<FormState>();

  final _supportLevelController = TextEditingController();
  final _timeRangeController = TextEditingController();
  final _focusDurationController = TextEditingController();

  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? hearingStatus;
  String? visionStatus;
  List<String> preferredActivities = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _supportLevelController.dispose();
    _timeRangeController.dispose();
    _focusDurationController.dispose();
    super.dispose();
  }

  String? _validateSupportLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل درجة الدعم';
    }
    return null;
  }

  String? _validateTimeRange(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك حدد النطاق الزمني';
    }
    return null;
  }

  String? _validateFocusDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك حدد المدة';
    }
    return null;
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: API Call
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DoctorOrAiScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'درجة الدعم',
                    height: 50,
                    controller: _supportLevelController,
                    validator: _validateSupportLevel,
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'أفضل وقت للممارسة؟',
                    fontSize: 12,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTimeRangeField(
                    hint: 'حدد النطاق الزمني',
                    suffixIcon: Iconify(
                      Bxs.time_five,
                      color: AppColors.primaryColor,
                    ),
                    controller: _timeRangeController,
                    validator: _validateTimeRange,
                    onTimeRangeSelected: (from, to) {
                      setState(() {
                        startTime = from;
                        endTime = to;
                      });
                    },
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: SimiBoldTitle(
                    title: 'كم من الوقت يمكنه التركيز؟',
                    fontSize: 12,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
                  child: CustomTextField(
                    hint: 'حدد المدة',
                    height: 50,
                    prefixIcon: Entypo.hour_glass,
                    controller: _focusDurationController,
                    validator: _validateFocusDuration,
                  ),
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
