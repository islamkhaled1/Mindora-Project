import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_text_styles.dart';

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
    this.isEnabled = true,
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
  final bool isEnabled;
  final bool isPhone;
  final String initialCountryCode;
  final void Function(CountryCode)? onCountryChanged;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText = widget.isPassword;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height.h,
          child: TextFormField(
            enabled: widget.isEnabled,
            maxLines: widget.maxLines,
            controller: widget.controller,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final result = widget.validator?.call(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _errorText != result) {
                  setState(() => _errorText = result);
                }
              });
              return result;
            },
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
              errorStyle: const TextStyle(height: 0, fontSize: 0),
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
                borderSide: BorderSide(
                  width: 1.5,
                  color: _errorText != null
                      ? Colors.red
                      : const Color(0xffD6D6D6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  width: 1.5,
                  color: _errorText != null
                      ? Colors.red
                      : const Color(0xffD6D6D6),
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(width: 1.5, color: Colors.red),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  width: 1.5,
                  color: Color(0xffD6D6D6),
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(width: 1.8, color: Colors.red),
              ),
            ),
          ),
        ),

        if (_errorText != null) ...[
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              _errorText!,
              maxLines: 2,
              style: AppTextStyles.font400Regular.copyWith(
                color: Colors.red,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
