import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/widgets/custom_title.dart';
import 'package:sawa/widgets/description.dart';
import 'package:sawa/widgets/icon_container.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({
    super.key,
    required this.backGroundColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.targetScreen,
    this.width = 50,
    this.height = 30,
  });
  final Color backGroundColor;
  final Color iconColor;
  final String icon;
  final double width;
  final double height;
  final String title;
  final String description;
  final Widget targetScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Center(
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen),
            );
          },
          leading: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryColor,
          ),
          trailing: IconContainer(
            backGroundColor: backGroundColor,
            icon: icon,
            iconColor: iconColor,
            width: width.w,
            height: height.h,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 4.0.r),
                child: CustomTitle(title: title, fontSize: 14),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Description(
                  text: description,
                  fontSize: 12,
                  align: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
