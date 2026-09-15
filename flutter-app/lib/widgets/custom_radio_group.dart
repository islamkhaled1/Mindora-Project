import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';

class CustomRadioGroup extends StatefulWidget {
  const CustomRadioGroup({
    super.key,
    required this.firstTitle,
    this.firstIcon,
    required this.firstValue,
    required this.secondTitle,
    this.secondIcon,
    required this.secondValue,
    this.onChanged,
    this.initialValue = 'normal',
  });

  final String firstTitle;
  final Widget? firstIcon;
  final String firstValue;

  final String secondTitle;
  final Widget? secondIcon;
  final String secondValue;

  final String? initialValue;

  final void Function(String value)? onChanged;

  @override
  State<CustomRadioGroup> createState() => _CustomRadioGroupState();
}

class _CustomRadioGroupState extends State<CustomRadioGroup> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();

    selectedValue = widget.initialValue ?? widget.firstValue;
  }

  void _selectOption(String value) {
    setState(() {
      selectedValue = value;
    });

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildOption(
            title: widget.firstTitle,
            icon: widget.firstIcon,
            value: widget.firstValue,
          ),
        ),

        SizedBox(width: 14.w),

        Expanded(
          child: _buildOption(
            title: widget.secondTitle,
            icon: widget.secondIcon,
            value: widget.secondValue,
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required String title,
    Widget? icon,
    required String value,
  }) {
    final bool isSelected = selectedValue == value;

    return GestureDetector(
      onTap: () => _selectOption(value),
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffF1E8FF) : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              SizedBox(width: 6.w),
              icon,
              SizedBox(width: 6.w),
            ],

            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.font400Regular.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
