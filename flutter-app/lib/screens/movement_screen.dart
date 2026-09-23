import 'package:flutter/material.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/screens/session_execution_screen.dart';

class MovementScreen extends StatelessWidget {
  final Widget? appBarTitle;
  final bool isExercise;

  const MovementScreen({
    super.key,
    this.appBarTitle,
    this.isExercise = false,
  });

  @override
  Widget build(BuildContext context) {
    return SessionExecutionScreen(
      session: SessionModel(
        id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
        childId: 'default-child',
        activityId: 'act-movement',
        domain: 'Movement',
        status: 'Started',
        startTimeUtc: DateTime.now().toUtc(),
      ),
      activity: const ActivityModel(
        id: 'act-movement',
        title: 'اتبع الحركة',
        description: 'تمرين تتبع حركة اليد والهدف بواسطة الذكاء الاصطناعي',
        domain: 'Movement',
        baseDifficulty: 'Beginner',
      ),
    );
  }
}
