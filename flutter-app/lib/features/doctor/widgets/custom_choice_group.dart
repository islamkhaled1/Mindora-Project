import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';

class CustomChoiceGroup extends StatefulWidget {
  const CustomChoiceGroup({
    super.key,
    required this.options,
    this.onChanged,
    this.initialValue,
  });

  final List<ChoiceOption> options;
  final String? initialValue;
  final void Function(String value)? onChanged;

  @override
  State<CustomChoiceGroup> createState() => _CustomChoiceGroupState();
}

class _CustomChoiceGroupState extends State<CustomChoiceGroup> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  void _selectOption(String value) {
    setState(() {
      selectedValue = value;
    });

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.map((option) {
        final bool isSelected = selectedValue == option.value;

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: GestureDetector(
            onTap: () => _selectOption(option.value),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xffF0E7FF) : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 16.sp,
                    color: AppColors.secondaryTextColor,
                  ),

                  SizedBox(width: 12.w),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          option.title,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.font700Bold.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),

                        SizedBox(height: 4.h),

                        Text(
                          option.subtitle,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.font500Medium.copyWith(
                            fontSize: 13.sp,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ChoiceOption {
  const ChoiceOption({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;
}
