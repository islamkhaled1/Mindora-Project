import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/models/child_enums.dart';
import 'package:sawa/core/models/child_model.dart';
import 'package:sawa/core/models/child_requests.dart';
import 'package:sawa/core/state/child_intake_state.dart';

void main() {
  group('Correction 1: Preferred Activity Semantic Mapping Tests', () {
    test('Maps "games" to Games enum (1)', () {
      final result = PreferredActivityStyle.fromSelectedValues(['games']);
      expect(result, equals(PreferredActivityStyle.games));
      expect(result?.value, equals(1));
    });

    test('Maps "learning" to Stories enum (2)', () {
      final result = PreferredActivityStyle.fromSelectedValues(['learning']);
      expect(result, equals(PreferredActivityStyle.stories));
      expect(result?.value, equals(2));
    });

    test('Maps both "games" and "learning" to primary Games enum (1)', () {
      final result =
          PreferredActivityStyle.fromSelectedValues(['games', 'learning']);
      expect(result, equals(PreferredActivityStyle.games));
      expect(result?.value, equals(1));
    });

    test('Returns null for empty preferences', () {
      final result = PreferredActivityStyle.fromSelectedValues([]);
      expect(result, isNull);
    });
  });

  group('Correction 2: Support Level Explicit Mapping & Unknown Rejection Tests', () {
    test('Maps known mild keywords to SupportLevelTier.mild (1)', () {
      expect(SupportLevelTier.fromUserInput('بسيط'), equals(SupportLevelTier.mild));
      expect(SupportLevelTier.fromUserInput('خفيف'), equals(SupportLevelTier.mild));
      expect(SupportLevelTier.fromUserInput('mild'), equals(SupportLevelTier.mild));
      expect(SupportLevelTier.fromUserInput('1'), equals(SupportLevelTier.mild));
    });

    test('Maps known moderate keywords to SupportLevelTier.moderate (2)', () {
      expect(SupportLevelTier.fromUserInput('متوسط'), equals(SupportLevelTier.moderate));
      expect(SupportLevelTier.fromUserInput('moderate'), equals(SupportLevelTier.moderate));
      expect(SupportLevelTier.fromUserInput('2'), equals(SupportLevelTier.moderate));
    });

    test('Maps known high keywords to SupportLevelTier.high (3)', () {
      expect(SupportLevelTier.fromUserInput('عالي'), equals(SupportLevelTier.high));
      expect(SupportLevelTier.fromUserInput('شديد'), equals(SupportLevelTier.high));
      expect(SupportLevelTier.fromUserInput('high'), equals(SupportLevelTier.high));
      expect(SupportLevelTier.fromUserInput('3'), equals(SupportLevelTier.high));
    });

    test('Rejects unknown values with null (no silent fallback to moderate)', () {
      expect(SupportLevelTier.fromUserInput('unknown random text'), isNull);
      expect(SupportLevelTier.fromUserInput('xyz123'), isNull);
      expect(SupportLevelTier.fromUserInput(''), isNull);
      expect(SupportLevelTier.fromUserInput(null), isNull);
    });
  });

  group('Correction 3: Avatar Local Preservation & Backend Null Safety Tests', () {
    test('ChildIntakeState preserves local avatar path but sends null avatarUrl', () {
      final intakeState = ChildIntakeState(
        fullName: 'Omar Khalid',
        birthDate: DateTime(2019, 5, 20),
        diagnosis: 'Down Syndrome',
        gender: 'male',
        localAvatarPath: '/data/user/0/com.example.sawa/cache/picked_image.jpg',
        rawSupportLevelText: 'بسيط',
        focusDurationMinutes: 20,
        hearingStatus: 'normal',
        visionStatus: 'normal',
        preferredActivities: ['games'],
      );

      // Local avatar is preserved in state
      expect(intakeState.localAvatarPath, contains('picked_image.jpg'));

      final request = intakeState.toCreateChildRequest();

      // Sent avatarUrl to backend MUST be null per Correction 3
      expect(request.avatarUrl, isNull);
      expect(request.toJson().containsKey('avatarUrl'), isFalse);
    });
  });

  group('Child DTO & Response Deserialization Tests', () {
    test('CreateChildRequest serializes date as yyyy-MM-dd and enums as integers', () {
      final request = CreateChildRequest(
        fullName: 'Laila Ahmed',
        dateOfBirth: '2020-08-15',
        supportNotes: 'Extra sensory support',
        gender: 2, // Girl
        diagnosis: 'Trisomy 21',
        supportLevel: 2, // Moderate
        hearingStatus: 1, // Normal
        visionStatus: 2, // HasDifficulty
        focusDurationMinutes: 25,
        preferredPracticeTime: '10:00 AM - 11:30 AM',
        preferredActivityType: 1, // Games
      );

      final json = request.toJson();
      expect(json['fullName'], equals('Laila Ahmed'));
      expect(json['dateOfBirth'], equals('2020-08-15'));
      expect(json['gender'], equals(2));
      expect(json['supportLevel'], equals(2));
      expect(json['hearingStatus'], equals(1));
      expect(json['visionStatus'], equals(2));
      expect(json['focusDurationMinutes'], equals(25));
      expect(json['preferredActivityType'], equals(1));
      expect(json['baselineMovementLevel'], equals(1));
    });

    test('ChildModel parses camelCase backend ChildDto', () {
      final json = {
        'id': 'b1c4efcf-190b-4046-8414-d2b006b2407c',
        'parentId': 'c2d5f0e0-201c-4157-9525-e3c117c3518d',
        'fullName': 'Sami Farouk',
        'dateOfBirth': '2019-03-10',
        'supportNotes': 'Needs speech therapy',
        'currentMovementLevel': 'Beginner',
        'currentSpeechLevel': 'Beginner',
        'currentAttentionLevel': 'Beginner',
        'createdAtUtc': '2026-09-10T10:00:00Z',
        'gender': 'Boy',
        'diagnosis': 'Down Syndrome',
        'avatarUrl': null,
        'supportLevel': 'Mild',
        'hearingStatus': 'Normal',
        'visionStatus': 'Normal',
        'focusDurationMinutes': 30,
        'preferredPracticeTime': '04:00 PM - 05:00 PM',
        'preferredActivityType': 'Games',
      };

      final model = ChildModel.fromJson(json);
      expect(model.id, equals('b1c4efcf-190b-4046-8414-d2b006b2407c'));
      expect(model.parentId, equals('c2d5f0e0-201c-4157-9525-e3c117c3518d'));
      expect(model.fullName, equals('Sami Farouk'));
      expect(model.dateOfBirth?.year, equals(2019));
      expect(model.dateOfBirth?.month, equals(3));
      expect(model.dateOfBirth?.day, equals(10));
      expect(model.gender, equals('Boy'));
      expect(model.focusDurationMinutes, equals(30));
    });
  });

  group('Step 1 -> Step 2 ChildIntakeState Preservation Tests', () {
    test('State combines Step 1 and Step 2 fields seamlessly', () {
      // Step 1 collected data
      final intake = ChildIntakeState(
        fullName: 'Nour Ali',
        birthDate: DateTime(2021, 1, 15),
        diagnosis: 'Down Syndrome',
        gender: 'female',
        supportNotes: 'Loves music',
      );

      // Transition to Step 2: add Step 2 fields
      intake.rawSupportLevelText = 'عالي';
      intake.supportLevelTier = SupportLevelTier.high;
      intake.preferredPracticeTime = '02:00 PM - 03:00 PM';
      intake.focusDurationMinutes = 15;
      intake.hearingStatus = 'normal';
      intake.visionStatus = 'difficulty';
      intake.preferredActivities = ['learning'];

      final request = intake.toCreateChildRequest();
      expect(request.fullName, equals('Nour Ali'));
      expect(request.dateOfBirth, equals('2021-01-15'));
      expect(request.gender, equals(2)); // Girl
      expect(request.supportLevel, equals(3)); // High
      expect(request.hearingStatus, equals(1)); // Normal
      expect(request.visionStatus, equals(2)); // HasDifficulty
      expect(request.preferredActivityType, equals(2)); // Stories
    });

    test('Throws StateError if support level is unrecognized', () {
      final intake = ChildIntakeState(
        fullName: 'Tarek',
        birthDate: DateTime(2020, 1, 1),
        rawSupportLevelText: 'not_a_valid_support_level',
      );

      expect(
        () => intake.toCreateChildRequest(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
