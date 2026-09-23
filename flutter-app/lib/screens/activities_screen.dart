import 'package:flutter/material.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/screens/practise_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  final String? initialDomain;
  final bool showBackButton;
  final List<ActivityModel>? initialActivities;

  const ActivitiesScreen({
    super.key,
    this.initialDomain,
    this.showBackButton = true,
    this.initialActivities,
  });

  @override
  Widget build(BuildContext context) {
    return PractiseScreen(
      showBackButton: showBackButton,
    );
  }
}
