import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/widgets/common/custom_title.dart';
import 'package:sawa/core/widgets/common/description.dart';
import 'package:sawa/core/widgets/icons/icon_container.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({
    super.key,
    required this.backGroundColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.description,
    this.targetScreen,
    this.statusText,
    this.isAvailable = true,
    this.onUnavailableTap,
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
  final Widget? targetScreen;
  final String? statusText;
  final bool isAvailable;
  final VoidCallback? onUnavailableTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15.r),
      child: SizedBox(
        width: double.infinity,
        height: 80.h,
        child: Center(
          child: ListTile(
          onTap: () {
            if (!isAvailable) {
              if (onUnavailableTap != null) {
                onUnavailableTap!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('هذا التدريب غير متاح حالياً.')),
                );
              }
              return;
            }
            if (targetScreen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => targetScreen!),
              );
            }
          },
          leading: Icon(
            isAvailable ? Icons.arrow_back_ios_new_rounded : Icons.lock_outline_rounded,
            size: isAvailable ? 24.r : 20.r,
            color: isAvailable ? AppColors.primaryColor : Colors.grey.shade400,
          ),
          trailing: IconContainer(
            backGroundColor: backGroundColor,
            icon: icon,
            iconColor: iconColor,
            width: width.w,
            height: height.h,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statusText != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: isAvailable ? const Color(0xffE8F5E9) : const Color(0xffFFEBEE),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    statusText!,
                    style: TextStyle(
                      fontFamily: 'Readex Pro',
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? const Color(0xff2E7D32) : const Color(0xffC62828),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4.0.r),
                  child: CustomTitle(title: title, fontSize: 13),
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Description(
                  text: description,
                  fontSize: 11,
                  align: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
