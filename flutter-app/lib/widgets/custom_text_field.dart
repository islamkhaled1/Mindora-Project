// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:iconify_flutter/iconify_flutter.dart';
// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:sawa/app_text_styles.dart';
// import 'package:sawa/constants.dart';

// class CustomTextField extends StatefulWidget {
//   const CustomTextField({
//     super.key,
//     required this.hint,
//     this.height = 50,
//     this.icon,
//     this.prefixIcon,
//     this.isPassword = false,
//     this.controller,
//     this.validator,
//     this.keyboardType,
//     this.isPhone = false,
//     this.initialCountryCode = 'EG',
//     this.onCountryChanged,
//   });
//   final double height;
//   final String hint;
//   final dynamic icon;
//   final dynamic prefixIcon;
//   final bool isPassword;
//   final TextEditingController? controller;
//   final String? Function(String?)? validator;
//   final TextInputType? keyboardType;

//   // Phone / country code support
//   final bool isPhone;
//   final String initialCountryCode;
//   final void Function(CountryCode)? onCountryChanged;

//   @override
//   State<CustomTextField> createState() => _CustomTextFieldState();
// }

// class _CustomTextFieldState extends State<CustomTextField> {
//   late bool _obscureText = widget.isPassword;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: widget.height.h,
//       child: TextFormField(
//         controller: widget.controller,
//         validator: widget.validator,
//         obscureText: widget.isPassword ? _obscureText : false,
//         keyboardType: widget.isPhone
//             ? TextInputType.phone
//             : widget.keyboardType,
//         textAlign: TextAlign.right,
//         decoration: InputDecoration(
//           fillColor: Colors.white,
//           filled: true,
//           hintText: widget.hint,
//           hintStyle: AppTextStyles.font400Regular.copyWith(
//             color: AppColors.secondaryColor,
//           ),
//           suffixIcon: widget.icon != null
//               ? Padding(
//                   padding: const EdgeInsets.all(10.0),
//                   child: Iconify(
//                     widget.icon!,
//                     size: 25,
//                     color: AppColors.primaryColor,
//                   ),
//                 )
//               : null,
//           suffixIconConstraints: const BoxConstraints(
//             minWidth: 20,
//             minHeight: 20,
//           ),
//           prefixIcon: widget.isPassword
//               ? IconButton(
//                   icon: Icon(
//                     _obscureText
//                         ? Icons.visibility_off_outlined
//                         : Icons.visibility_outlined,
//                     color: AppColors.secondaryColor,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _obscureText = !_obscureText;
//                     });
//                   },
//                 )
//               : widget.isPhone
//               ? IntrinsicHeight(
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CountryCodePicker(
//                         onChanged: widget.onCountryChanged,
//                         initialSelection: widget.initialCountryCode,
//                         showFlag: false,
//                         showDropDownButton: true,
//                         padding: EdgeInsets.zero,
//                         textStyle: AppTextStyles.font400Regular.copyWith(
//                           color: AppColors.primaryColor,
//                         ),
//                       ),
//                       const VerticalDivider(
//                         color: Color(0xffD6D6D6),
//                         thickness: 1,
//                         width: 16,
//                         indent: 12,
//                         endIndent: 12,
//                       ),
//                     ],
//                   ),
//                 )
//               : (widget.prefixIcon != null
//                     ? Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Iconify(
//                           widget.prefixIcon,
//                           size: 30,
//                           color: AppColors.primaryColor,
//                         ),
//                       )
//                     : null),
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
import 'package:iconify_flutter/iconify_flutter.dart';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/app_colors.dart';

class CustomTextField extends StatefulWidget {
  CustomTextField({
    super.key,
    required this.hint,
    this.height = 50,
    this.icon,
    this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.isPhone = false,
    this.initialCountryCode = 'EG',
    this.onCountryChanged,
    this.maxLines = 1,
  });

  final double height;
  final String hint;
  final dynamic icon;
  final dynamic prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  final bool isPhone;
  final String initialCountryCode;
  final void Function(CountryCode)? onCountryChanged;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height.h,
      child: TextFormField(
        maxLines: widget.maxLines,
        controller: widget.controller,
        validator: widget.validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.isPhone
            ? TextInputType.phone
            : widget.keyboardType,
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
          suffixIcon: widget.icon != null
              ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Iconify(
                    widget.icon!,
                    size: 25,
                    color: AppColors.primaryColor,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          prefixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.secondaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : widget.isPhone
              ? IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountryCodePicker(
                        onChanged: widget.onCountryChanged,
                        initialSelection: widget.initialCountryCode,
                        showFlag: false,
                        showDropDownButton: true,
                        padding: EdgeInsets.zero,
                        textStyle: AppTextStyles.font400Regular.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const VerticalDivider(
                        color: Color(0xffD6D6D6),
                        thickness: 1,
                        width: 16,
                        indent: 12,
                        endIndent: 12,
                      ),
                    ],
                  ),
                )
              : (widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Iconify(
                          widget.prefixIcon,
                          size: 30,
                          color: AppColors.primaryColor,
                        ),
                      )
                    : null),
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
