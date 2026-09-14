import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/buttons/custom_elevated_button.dart';
import 'package:sawa/core/widgets/common/custom_padding.dart';
import 'package:sawa/core/widgets/common/custom_radio_group.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';
import 'package:sawa/features/auth/screens/enter_code_screen.dart';

class ConnectWithDoctorScreen extends StatefulWidget {
  const ConnectWithDoctorScreen({super.key});

  @override
  State<ConnectWithDoctorScreen> createState() =>
      _ConnectWithDoctorScreenState();
}

class _ConnectWithDoctorScreenState extends State<ConnectWithDoctorScreen> {
  String? method;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
      body: CustomPadding(
        child: Column(
          children: [
            Center(child: CustomTitle(title: 'التواصل مع طبيبك', fontSize: 20)),
            SizedBox(height: 8.h),
            Center(
              child: Description(
                text: 'أدخل رمز طبيبك أو قم بمسح رمز الـ QR الخاص به.',
                fontSize: 13,
              ),
            ),
            SizedBox(height: 80.h),
            CustomRadioGroup(
              firstTitle: 'مسح رمز QR',
              firstValue: 'qr',
              secondTitle: 'إدخال الرمز',
              secondValue: 'code',
              onChanged: (value) {
                setState(() {
                  method = value;
                });
              },
            ),
            SizedBox(height: 100.h),
            CustomElevatedButton(
              title: 'متابعة',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EnterCodeScreen()),
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
