// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sawa/app_text_styles.dart';
// import 'package:sawa/constants.dart';

// class CustomTimeRangeField extends StatefulWidget {
//   const CustomTimeRangeField({
//     super.key,
//     this.height = 50,
//     required this.hint,
//     required this.suffixIcon,
//     this.onTimeRangeSelected,
//   });

//   final String hint;
//   final double height;
//   final Widget suffixIcon;

//   final void Function(TimeOfDay from, TimeOfDay to)? onTimeRangeSelected;

//   @override
//   State<CustomTimeRangeField> createState() => _CustomTimeRangeFieldState();
// }

// class _CustomTimeRangeFieldState extends State<CustomTimeRangeField> {
//   final TextEditingController _controller = TextEditingController();

//   TimeOfDay? _fromTime;
//   TimeOfDay? _toTime;

//   Future<void> _selectTimeRange() async {
//     final TimeOfDay? from = await showTimePicker(
//       context: context,
//       initialTime: _fromTime ?? TimeOfDay.now(),
//     );

//     if (from == null) return;

//     final TimeOfDay? to = await showTimePicker(
//       context: context,
//       initialTime: _toTime ?? from,
//     );

//     if (to == null) return;

//     setState(() {
//       _fromTime = from;
//       _toTime = to;

//       _controller.text = '${from.format(context)} - ${to.format(context)}';
//     });

//     widget.onTimeRangeSelected?.call(from, to);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: widget.height.h,
//       child: TextFormField(
//         controller: _controller,
//         readOnly: true,
//         onTap: _selectTimeRange,
//         textAlign: TextAlign.right,
//         decoration: InputDecoration(
//           fillColor: Colors.white,
//           filled: true,

//           hintText: widget.hint,

//           hintStyle: AppTextStyles.font400Regular.copyWith(
//             color: AppColors.secondaryColor,
//           ),

//           // الـ icon على اليمين
//           suffixIcon: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: widget.suffixIcon,
//           ),

//           suffixIconConstraints: BoxConstraints(
//             minWidth: 40.w,
//             minHeight: 40.h,
//           ),

//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: const BorderSide(width: 1.5, color: Color(0xffD6D6D6)),
//           ),

//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: const BorderSide(width: 1.5, color: Color(0xffD6D6D6)),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';

class CustomTimeRangeField extends StatefulWidget {
  const CustomTimeRangeField({
    super.key,
    this.height = 50,
    required this.hint,
    required this.suffixIcon,
    this.controller,
    this.validator,
    this.onTimeRangeSelected,
  });

  final String hint;
  final double height;
  final Widget suffixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(TimeOfDay from, TimeOfDay to)? onTimeRangeSelected;

  @override
  State<CustomTimeRangeField> createState() => _CustomTimeRangeFieldState();
}

class _CustomTimeRangeFieldState extends State<CustomTimeRangeField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  Future<void> _selectTimeRange() async {
    final TimeOfDay? from = await showTimePicker(
      context: context,
      initialTime: _fromTime ?? TimeOfDay.now(),
    );

    if (from == null) return;

    final TimeOfDay? to = await showTimePicker(
      context: context,
      initialTime: _toTime ?? from,
    );

    if (to == null) return;

    setState(() {
      _fromTime = from;
      _toTime = to;

      _controller.text = '${from.format(context)} - ${to.format(context)}';
    });

    widget.onTimeRangeSelected?.call(from, to);
  }

  @override
  void dispose() {
    // نعمل dispose بس لو الـ controller اتعمل جوه الـ widget نفسها
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
        onTap: _selectTimeRange,
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

          // الـ icon على اليمين
          suffixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: widget.suffixIcon,
          ),

          suffixIconConstraints: BoxConstraints(
            minWidth: 40.w,
            minHeight: 40.h,
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
