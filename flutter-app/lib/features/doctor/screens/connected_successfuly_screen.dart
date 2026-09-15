import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/core/models/doctor_linking_models.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/doctor_card.dart';
import 'package:sawa/widgets/success_check_icon.dart';

class ConnectedSuccessfuly extends StatelessWidget {
  final DoctorAssignmentModel? assignment;

  const ConnectedSuccessfuly({super.key, this.assignment});

  @override
  Widget build(BuildContext context) {
    final doctorDisplayName = (assignment?.doctorName != null && assignment!.doctorName!.trim().isNotEmpty)
        ? assignment!.doctorName!.trim()
        : 'د. الطبيب المعتمد';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leading: Navigator.canPop(context) ? const BackIcon() : null,
      ),
      body: CustomPadding(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40.h),
              const Center(child: SuccessCheckIcon()),
              SizedBox(height: 24.h),
              const CustomTitle(title: 'تم إرسال طلب الربط بنجاح', fontSize: 22),
              SizedBox(height: 12.h),

              // Pending Status Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF3E0),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xffFFE0B2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Color(0xffE65100),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'قيد الانتظار - في انتظار موافقة الطبيب',
                      style: TextStyle(
                        fontFamily: 'Readex Pro',
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color: const Color(0xffE65100),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),
              Text(
                'تم إرسال طلب ربط طفلك إلى الطبيب بنجاح.\nستتمكن من مشاركة التقييمات ومتابعة الخطة العلاجية فور اعتماد الطبيب للطلب.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Readex Pro',
                  fontSize: 12.sp,
                  color: AppColors.secondaryColor,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 28.h),
              DoctorCard(docName: doctorDisplayName),
              SizedBox(height: 36.h),

              CustomElevatedButton(
                width: 175,
                height: 42,
                title: 'العودة للرئيسية',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
