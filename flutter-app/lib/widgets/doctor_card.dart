import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/widgets/medium_title.dart';
import 'package:sawa/widgets/simi_bold_title.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.docName});
  final String docName;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.h,
      decoration: BoxDecoration(
        color: const Color(0xffF1E8FF),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/doctor_female.png'),
          ),

          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SimiBoldTitle(title: docName, fontSize: 22),
                  SizedBox(height: 8.h),
                  MediumTitle(
                    title: 'أخصائي رعاية أطفال متلازمة داون',
                    fontSize: 11,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
