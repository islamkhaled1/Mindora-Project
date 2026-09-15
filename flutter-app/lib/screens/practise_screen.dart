import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/screens/practise_instruction_attention.dart';
import 'package:sawa/screens/practise_instruction_movement.dart';
import 'package:sawa/screens/practise_instruction_speech.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';
import 'package:sawa/widgets/custom_elevated_button.dart';
import 'package:sawa/widgets/custom_list_tile.dart';
import 'package:sawa/widgets/custom_padding.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/icon_container.dart';
import 'package:sawa/widgets/image_circle_avatar.dart';
import 'package:iconify_flutter/icons/bx.dart';
import 'package:sawa/widgets/state_badge.dart';

class PractiseScreen extends StatelessWidget {
  const PractiseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        height: 75.h,
        leading: BackIcon(),
        title: Column(
          children: [
            CustomTitle(title: 'تمارين اليوم', fontSize: 22),
            SizedBox(height: 10.h),
            Description(
              text: 'تمارين مختارة لعمر بناءً على خطته العلاجية',
              fontSize: 12,
            ),
          ],
        ),
        actions: [ImageCircleAvatar(image: 'assets/images/kid_image.png')],
      ),
      body: SingleChildScrollView(
        child: CustomPadding(
          child: Column(
            children: [
              SizedBox(height: 24.h),
              StateBadge(time: '10', exrecisesCount: '3'),
              SizedBox(height: 24.h),
              Container(
                width: double.infinity,
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomTitle(title: 'اليوم نركز على', fontSize: 20),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconContainer(
                          backGroundColor: AppColors.circleAvatarColor,
                          icon: Bx.bxs_message_rounded_dots,
                          iconColor: AppColors.primaryColor,
                          label: 'التواصل',
                        ),
                        IconContainer(
                          backGroundColor: Color(0xffEEF3EE),
                          icon: AppIcons.brain,
                          iconColor: Color(0xff6DAA60),
                          label: 'الفهم والإدراك',
                        ),
                        IconContainer(
                          backGroundColor: Color(0xffFDF4E9),
                          icon: AppIcons.running,
                          iconColor: Color(0xffFDB62C),
                          label: 'الحركة',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 26.h),

              CustomListTile(
                icon: Bx.bxs_message_rounded_dots,
                backGroundColor: AppColors.circleAvatarColor,
                iconColor: AppColors.primaryColor,
                title: 'قولها معايا',
                description: 'استمع للكلمة وحاول نطقها معا.',
                targetScreen: PractiseInstructionSpeech(),
              ),
              SizedBox(height: 16.h),
              CustomListTile(
                icon: AppIcons.brain,
                backGroundColor: AppColors.lightGreen,
                iconColor: AppColors.darkGreen,
                title: 'اسمع وابحث',
                description: 'استمع للتعليمات وابحث عن الصورة الصحيحة.',
                targetScreen: PractiseInstructionAttention(),
              ),
              SizedBox(height: 16.h),
              CustomListTile(
                icon: AppIcons.running,
                backGroundColor: AppColors.lightOrange,
                iconColor: AppColors.dartOrange,
                title: 'اتبع الحركة',
                description: 'شاهد الحركة وحاول تنفيذها.',
                targetScreen: PractiseInstructionMovement(),
              ),
              SizedBox(height: 26.h),
              CustomElevatedButton(
                title: 'إبدأ تمارين اليوم',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PractiseInstructionSpeech(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
