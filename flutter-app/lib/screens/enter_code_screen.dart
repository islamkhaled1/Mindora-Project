import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/connected_successfuly_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_note.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_text_field.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/simi_bold_title.dart';
import 'package:iconify_flutter/icons/radix_icons.dart';

class EnterCodeScreen extends StatelessWidget {
  const EnterCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: Column(
          children: [
            Center(child: CustomTitle(title: 'إدخال رمز الطبيب', fontSize: 20)),
            SizedBox(height: 8.h),
            Center(child: Description(text: 'أدخل رمز طبيبك', fontSize: 13)),
            SizedBox(height: 64.h),
            Align(
              alignment: AlignmentGeometry.centerRight,
              child: SimiBoldTitle(title: 'رمز الطبيب', fontSize: 12),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 4.0.r, top: 8.0.r),
              child: CustomTextField(hint: 'أدخل الرمز', height: 40),
            ),
            SizedBox(height: 32.h),
            CustomNote(
              title: 'يمكنك الحصول على الرمز من طبيبك أو العيادة.',
              icon: RadixIcons.info_circled,
            ),
            SizedBox(height: 50.h),
            CustomElevatedButton(
              title: 'متابعة',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConnectedSuccessfuly(),
                  ),
                );
              },
              width: 165,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
