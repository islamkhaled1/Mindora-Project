import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';

class CustomDateField extends StatefulWidget {
  const CustomDateField({
    super.key,
    this.height = 50,
    required this.hint,
    required this.prefixIcon,
    this.controller,
    this.validator,
    this.onDateSelected,
  });

  final String hint;
  final double height;
  final Widget prefixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(DateTime)? onDateSelected;

  @override
  State<CustomDateField> createState() => _CustomDateFieldState();
}

class _CustomDateFieldState extends State<CustomDateField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _controller.text =
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });

      widget.onDateSelected?.call(pickedDate);
    }
  }

  @override
  void dispose() {
    // نعمل dispose بس لو الـ controller اتعمل جوه الـ widget نفسها
    // (يعني مفيش controller اتبعت من بره)
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height.h,
      child: TextFormField(
        controller: _controller,
        validator: widget.validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        readOnly: true,
        onTap: _selectDate,
        textAlign: TextAlign.right,
        style: AppTextStyles.font400Regular.copyWith(
          color: AppColors.primaryColor,
        ),
        decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,

          hintText: widget.hint,

          hintStyle: AppTextStyles.font400Regular.copyWith(
            color: AppColors.secondaryColor,
          ),

          errorMaxLines: 2,
          errorStyle: AppTextStyles.font400Regular.copyWith(
            color: Colors.red,
            fontSize: 11.sp,
          ),

          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: widget.prefixIcon,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 40.w,
            minHeight: 40.h,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 1.5, color: Color(0xffD6D6D6)),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 1.5, color: Color(0xffD6D6D6)),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 1.5, color: Colors.red),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 1.8, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
