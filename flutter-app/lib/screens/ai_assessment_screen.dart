import 'package:flutter/material.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/widgets/back_icon.dart';
import 'package:sawa/widgets/custom_app_bar.dart';

class AiAssessmentScreen extends StatelessWidget {
  const AiAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(leading: BackIcon()),
    );
  }
}
