import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/screens/enter_code_screen.dart';
import 'package:sawa/screens/scan_qr_screen.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_radio_group.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';

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
                  MaterialPageRoute(
                    builder: (context) =>
                        method == 'qr' ? ScanQrScreen() : EnterCodeScreen(),
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
