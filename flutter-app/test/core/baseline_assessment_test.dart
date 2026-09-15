import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/baseline_assessment_models.dart';
import 'package:sawa/core/network/api_client.dart';
import 'package:sawa/core/services/baseline_assessment_service.dart';
import 'package:sawa/core/state/baseline_assessment_state.dart';

// Helper mock adapter to test service without actual network calls
class _MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('1. Baseline Assessment State Tests', () {
    test('Initial state starts at first task with no answers', () {
      final state = BaselineAssessmentState();
      expect(state.currentTaskIndex, equals(0));
      expect(state.totalTasks, equals(8));
      expect(state.isFirstTask, isTrue);
      expect(state.isLastTask, isFalse);
      expect(state.isCurrentTaskAnswered, isFalse);
      expect(state.allTasksAnswered, isFalse);
    });

    test('Selecting option records answer and marks current task answered', () {
      final state = BaselineAssessmentState();
      final currentTask = state.currentTask;

      expect(state.getSelectedOptionIndex(currentTask.id), isNull);
      state.selectOption(currentTask.id, 2); // 75.0 points

      expect(state.getSelectedOptionIndex(currentTask.id), equals(2));
      expect(state.isCurrentTaskAnswered, isTrue);
      expect(state.getTaskPoints(currentTask.id), equals(75.0));
    });

    test('Navigation next and previous respects boundaries', () {
      final state = BaselineAssessmentState();

      // At start, previous does nothing
      state.previousTask();
      expect(state.currentTaskIndex, equals(0));

      // Advance through tasks
      for (int i = 0; i < 7; i++) {
        state.nextTask();
      }
      expect(state.currentTaskIndex, equals(7));
      expect(state.isLastTask, isTrue);

      // Past the end does nothing
      state.nextTask();
      expect(state.currentTaskIndex, equals(7));

      // Back navigation
      state.previousTask();
      expect(state.currentTaskIndex, equals(6));
    });

    test('allTasksAnswered requires all 8 tasks to be answered', () {
      final state = BaselineAssessmentState();

      for (int i = 0; i < 7; i++) {
        state.selectOption(state.tasks[i].id, 1);
      }
      expect(state.allTasksAnswered, isFalse);

      state.selectOption(state.tasks[7].id, 1);
      expect(state.allTasksAnswered, isTrue);
    });
  });

  group('2. Deterministic Scoring Tests', () {
    test('Minimum possible score yields exactly 25.0 across all domains and overall', () {
      final state = BaselineAssessmentState();

      // Answer all 8 tasks with option 0 (25.0 points each)
      for (final task in state.tasks) {
        state.selectOption(task.id, 0);
      }

      expect(state.allTasksAnswered, isTrue);
      expect(state.motorScore, equals(25.0));
      expect(state.communicationScore, equals(25.0));
      expect(state.cognitiveScore, equals(25.0));
      expect(state.emotionalScore, equals(25.0));
      expect(state.overallScore, equals(25.0));
    });

    test('Maximum possible score yields exactly 100.0 across all domains and overall', () {
      final state = BaselineAssessmentState();

      // Answer all 8 tasks with option 3 (100.0 points each)
      for (final task in state.tasks) {
        state.selectOption(task.id, 3);
      }

      expect(state.allTasksAnswered, isTrue);
      expect(state.motorScore, equals(100.0));
      expect(state.communicationScore, equals(100.0));
      expect(state.cognitiveScore, equals(100.0));
      expect(state.emotionalScore, equals(100.0));
      expect(state.overallScore, equals(100.0));
    });

    test('Mixed answers calculate exact domain averages and overall arithmetic mean', () {
      final state = BaselineAssessmentState();

      // Motor: Task 1 = 50.0 (idx 1), Task 2 = 75.0 (idx 2) -> Average = 62.5
      state.selectOption('motor_fine', 1);
      state.selectOption('motor_gross', 2);

      // Communication: Task 3 = 100.0 (idx 3), Task 4 = 50.0 (idx 1) -> Average = 75.0
      state.selectOption('comm_expressive', 3);
      state.selectOption('comm_receptive', 1);

      // Cognitive: Task 5 = 75.0 (idx 2), Task 6 = 75.0 (idx 2) -> Average = 75.0
      state.selectOption('cog_attention', 2);
      state.selectOption('cog_problem_solving', 2);

      // Emotional: Task 7 = 100.0 (idx 3), Task 8 = 100.0 (idx 3) -> Average = 100.0
      state.selectOption('emo_social', 3);
      state.selectOption('emo_regulation', 3);

      expect(state.motorScore, equals(62.5));
      expect(state.communicationScore, equals(75.0));
      expect(state.cognitiveScore, equals(75.0));
      expect(state.emotionalScore, equals(100.0));

      // Overall: (62.5 + 75.0 + 75.0 + 100.0) / 4 = 312.5 / 4 = 78.125 -> rounded to 78.1
      expect(state.overallScore, equals(78.1));
    });

    test('Repeated calculations are 100% deterministic with zero randomness', () {
      final state = BaselineAssessmentState();
      state.selectOption('motor_fine', 0);
      state.selectOption('motor_gross', 1);
      state.selectOption('comm_expressive', 2);
      state.selectOption('comm_receptive', 3);
      state.selectOption('cog_attention', 1);
      state.selectOption('cog_problem_solving', 2);
      state.selectOption('emo_social', 3);
      state.selectOption('emo_regulation', 0);

      final score1 = state.overallScore;
      final score2 = state.overallScore;
      final score3 = state.overallScore;

      expect(score1, equals(score2));
      expect(score2, equals(score3));
    });

    test('Changing an answer in one domain only affects that domain and overall', () {
      final state = BaselineAssessmentState();
      for (final task in state.tasks) {
        state.selectOption(task.id, 1); // all 50.0
      }

      expect(state.motorScore, equals(50.0));
      expect(state.communicationScore, equals(50.0));
      expect(state.cognitiveScore, equals(50.0));
      expect(state.emotionalScore, equals(50.0));

      // Modify only motor task 1 to 100.0 (idx 3)
      state.selectOption('motor_fine', 3);

      // Motor changes to (100.0 + 50.0)/2 = 75.0
      expect(state.motorScore, equals(75.0));
      // Others remain 50.0
      expect(state.communicationScore, equals(50.0));
      expect(state.cognitiveScore, equals(50.0));
      expect(state.emotionalScore, equals(50.0));
      // Overall becomes (75.0 + 50 + 50 + 50)/4 = 225/4 = 56.25 -> 56.3
      expect(state.overallScore, equals(56.3));
    });
  });

  group('3. Request Model Serialization Tests', () {
    test('toRequest throws StateError when tasks are not fully answered', () {
      final state = BaselineAssessmentState();
      expect(() => state.toRequest(), throwsStateError);
    });

    test('toRequest serializes exact decimal properties matching ASP.NET Core contract', () {
      final state = BaselineAssessmentState();
      for (final task in state.tasks) {
        state.selectOption(task.id, 2); // all 75.0
      }

      final request = state.toRequest();
      final json = request.toJson();

      expect(json['overallScore'], equals(75.0));
      expect(json['cognitiveScore'], equals(75.0));
      expect(json['communicationScore'], equals(75.0));
      expect(json['motorScore'], equals(75.0));
      expect(json['emotionalScore'], equals(75.0));
    });
  });

  group('4. Response Model Deserialization Tests', () {
    test('Parses camelCase backend BaselineAssessmentDto payload', () {
      final json = {
        'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'childId': 'f1e2d3c4-b5a6-0987-fedc-ba0987654321',
        'overallScore': 78.5,
        'cognitiveScore': 80.0,
        'communicationScore': 75.0,
        'motorScore': 85.0,
        'emotionalScore': 74.0,
        'completedAtUtc': '2026-09-10T10:00:00Z',
      };

      final model = BaselineAssessmentModel.fromJson(json);

      expect(model.id, equals('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
      expect(model.childId, equals('f1e2d3c4-b5a6-0987-fedc-ba0987654321'));
      expect(model.overallScore, equals(78.5));
      expect(model.cognitiveScore, equals(80.0));
      expect(model.communicationScore, equals(75.0));
      expect(model.motorScore, equals(85.0));
      expect(model.emotionalScore, equals(74.0));
      expect(model.completedAtUtc.isUtc, isTrue);
    });

    test('Parses PascalCase backend BaselineAssessmentDto defensively', () {
      final json = {
        'Id': 'd0187aa4-c095-46aa-a39a-5ca4703ad8f1',
        'ChildId': 'c3b2a100-1111-2222-3333-444455556666',
        'OverallScore': 65,
        'CognitiveScore': 70,
        'CommunicationScore': 60,
        'MotorScore': 65,
        'EmotionalScore': 65,
        'CompletedAtUtc': '2026-09-10T11:30:00Z',
      };

      final model = BaselineAssessmentModel.fromJson(json);

      expect(model.id, equals('d0187aa4-c095-46aa-a39a-5ca4703ad8f1'));
      expect(model.childId, equals('c3b2a100-1111-2222-3333-444455556666'));
      expect(model.overallScore, equals(65.0));
      expect(model.cognitiveScore, equals(70.0));
      expect(model.communicationScore, equals(60.0));
      expect(model.motorScore, equals(65.0));
      expect(model.emotionalScore, equals(65.0));
    });
  });

  group('5. Baseline Assessment Service & Guard Tests', () {
    test('Throws ApiException when childId is empty or whitespace before making network call', () async {
      final service = BaselineAssessmentService();
      const request = RecordBaselineAssessmentRequest(
        overallScore: 50.0,
        cognitiveScore: 50.0,
        communicationScore: 50.0,
        motorScore: 50.0,
        emotionalScore: 50.0,
      );

      expect(
        () => service.recordBaselineAssessment(childId: '', request: request),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );

      expect(
        () => service.recordBaselineAssessment(childId: '   ', request: request),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('Successfully posts to /api/children/{childId}/baseline-assessment and parses response', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(
          options.path,
          equals('/api/children/test-child-123/baseline-assessment'),
        );
        expect(options.method, equals('POST'));

        return ResponseBody.fromString(
          '''
          {
            "id": "assess-guid-111",
            "childId": "test-child-123",
            "overallScore": 85.0,
            "cognitiveScore": 85.0,
            "communicationScore": 85.0,
            "motorScore": 85.0,
            "emotionalScore": 85.0,
            "completedAtUtc": "2026-09-10T12:00:00Z"
          }
          ''',
          201,
          headers: {
            'content-type': ['application/json']
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final service = BaselineAssessmentService(apiClient: apiClient);

      const request = RecordBaselineAssessmentRequest(
        overallScore: 85.0,
        cognitiveScore: 85.0,
        communicationScore: 85.0,
        motorScore: 85.0,
        emotionalScore: 85.0,
      );

      final result = await service.recordBaselineAssessment(
        childId: 'test-child-123',
        request: request,
      );

      expect(result.id, equals('assess-guid-111'));
      expect(result.childId, equals('test-child-123'));
      expect(result.overallScore, equals(85.0));
    });
  });
}
