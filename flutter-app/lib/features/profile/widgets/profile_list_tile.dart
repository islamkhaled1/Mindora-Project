import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/common/simi_bold_title.dart';
import 'package:sawa/core/widgets/icons/icon_container.dart';

class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetScreen,
  });
  final String title;
  final String description;
  final String icon;
  final Widget targetScreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.r),
      child: ListTile(
        leading: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.primaryColor,
          size: 30,
        ),
        trailing: Padding(
          padding: EdgeInsets.only(top: 8.0.r),
          child: IconContainer(
            width: 50,
            height: 35,
            backGroundColor: AppColors.circleAvatarColor,
            iconColor: AppColors.primaryColor,
            icon: icon,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SimiBoldTitle(title: title, fontSize: 16),
            Description(text: description, fontSize: 14),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        },
      ),
    );
  }
}
