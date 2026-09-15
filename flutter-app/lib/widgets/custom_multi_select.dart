import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';

class CustomMultiSelect extends StatefulWidget {
  const CustomMultiSelect({
    super.key,
    required this.options,
    this.onChanged,
    this.initialValues = const [],
  });

  final List<MultiSelectOption> options;
  final List<String> initialValues;
  final void Function(List<String> selectedValues)? onChanged;

  @override
  State<CustomMultiSelect> createState() => _CustomMultiSelectState();
}

class _CustomMultiSelectState extends State<CustomMultiSelect> {
  late List<String> selectedValues;

  @override
  void initState() {
    super.initState();

    // في البداية مفيش أي اختيار
    selectedValues = List.from(widget.initialValues);
  }

  void _toggleOption(String value) {
    setState(() {
      if (selectedValues.contains(value)) {
        selectedValues.remove(value);
      } else {
        selectedValues.add(value);
      }
    });

    widget.onChanged?.call(selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.options.map((option) {
        final bool isSelected = selectedValues.contains(option.value);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: GestureDetector(
              onTap: () => _toggleOption(option.value),
              child: Container(
                height: 80.h,
                decoration: BoxDecoration(
                  // Selected → بنفس اللون البنفسجي
                  // Not selected → أبيض
                  color: isSelected ? const Color(0xffF1E8FF) : Colors.white,

                  borderRadius: BorderRadius.circular(10.r),

                  // مفيش border سواء selected أو لأ
                  border: Border.all(color: Colors.transparent, width: 0),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font400Regular.copyWith(
                        color: const Color(0xff403451),
                        fontSize: 15.sp,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    option.icon,
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MultiSelectOption {
  const MultiSelectOption({
    required this.title,
    required this.icon,
    required this.value,
  });

  final String title;
  final Widget icon;
  final String value;
}
