import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/core/network/api_client.dart';
import 'package:sawa/core/services/session_service.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';

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

class _MockSecureStorageService extends SecureStorageService {
  final Map<String, String> _inMemory = {};

  @override
  Future<void> saveActiveSessionId(String sessionId) async {
    _inMemory['active_session_id'] = sessionId;
  }

  @override
  Future<String?> getActiveSessionId() async {
    return _inMemory['active_session_id'];
  }

  @override
  Future<void> clearActiveSessionId() async {
    _inMemory.remove('active_session_id');
  }

  @override
  Future<void> clearAuth() async {
    _inMemory.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const validChildGuid = '11111111-1111-1111-1111-111111111111';
  const validActivityGuid = '22222222-2222-2222-2222-222222222222';
  const validSessionGuid = '33333333-3333-3333-3333-333333333333';

  group('1. Session Models & Serialization Tests', () {
    test('Parses camelCase backend SessionDto correctly', () {
      final json = {
        'id': validSessionGuid,
        'childId': validChildGuid,
        'activityId': validActivityGuid,
        'domain': 'Movement',
        'status': 'Started',
        'startTimeUtc': '2026-09-10T12:00:00Z',
        'targetDifficulty': 'Beginner',
        'adaptiveSettingsJson': '{"targetCount":10}',
      };

      final session = SessionModel.fromJson(json);

      expect(session.id, equals(validSessionGuid));
      expect(session.childId, equals(validChildGuid));
      expect(session.activityId, equals(validActivityGuid));
      expect(session.domain, equals('Movement'));
      expect(session.status, equals('Started'));
      expect(session.isStarted, isTrue);
      expect(session.isCompleted, isFalse);
      expect(session.isAbandoned, isFalse);
      expect(session.targetDifficulty, equals('Beginner'));
      expect(session.adaptiveSettingsJson, equals('{"targetCount":10}'));
    });

    test('Parses PascalCase backend SessionDto defensively', () {
      final json = {
        'Id': validSessionGuid,
        'ChildId': validChildGuid,
        'ActivityId': validActivityGuid,
        'Domain': 'Speech',
        'Status': 'Completed',
        'StartTimeUtc': '2026-09-10T14:30:00Z',
        'TargetDifficulty': null,
        'AdaptiveSettingsJson': null,
      };

      final session = SessionModel.fromJson(json);

      expect(session.id, equals(validSessionGuid));
      expect(session.domain, equals('Speech'));
      expect(session.isCompleted, isTrue);
      expect(session.isStarted, isFalse);
      expect(session.targetDifficulty, isNull);
    });

    test('MetricInputModel serializes to JSON matching backend MetricInputDto', () {
      const metric = MetricInputModel(
        metricType: 'RepetitionCount',
        value: 12.0,
      );

      final json = metric.toJson();

      expect(json['metricType'], equals('RepetitionCount'));
      expect(json['value'], equals(12.0));
    });

    test('CompleteSessionRequest serializes duration, metrics, rating and notes', () {
      const request = CompleteSessionRequest(
        actualDurationSeconds: 125,
        metrics: [
          MetricInputModel(metricType: 'RepetitionCount', value: 10.0),
          MetricInputModel(metricType: 'AccuracyPercentage', value: 90.0),
        ],
        parentRating: ParentSentimentRating.medium,
        parentNotes: 'أداء ممتاز وتفاعل إيجابي',
      );

      final json = request.toJson();

      expect(json['actualDurationSeconds'], equals(125));
      expect(json['parentRating'], equals(2));
      expect(json['parentNotes'], equals('أداء ممتاز وتفاعل إيجابي'));
      expect((json['metrics'] as List).length, equals(2));
      expect((json['metrics'] as List)[0]['metricType'], equals('RepetitionCount'));
    });

    test('RecordFeedbackRequest serializes rating as integer and optional notes', () {
      const feedback = RecordFeedbackRequest(
        rating: ParentSentimentRating.easy,
        notes: 'كانت التمارين سهلة ومريحة للطفل',
      );

      final json = feedback.toJson();

      expect(json['rating'], equals(1));
      expect(json['notes'], equals('كانت التمارين سهلة ومريحة للطفل'));
    });
  });

  group('2. Session AI Analysis & Outcome Mapping Tests', () {
    test('Parses SessionAnalysisResultDto with authoritative fields', () {
      final json = {
        'id': 'analysis-111',
        'sessionId': validSessionGuid,
        'overallPerformanceScore': 87.5,
        'domainScore': 90.0,
        'supportiveObservations': 'استجابة متسقة وسرعة بديهة ملحوظة.',
        'fatigueObserved': false,
        'recommendedDifficultyAdjustment': 'Increase',
        'adaptiveParametersJson': '{"cueSpeedMs": 1000}',
        'analyzedAtUtc': '2026-09-10T12:05:00Z',
        'isFallbackResult': false,
      };

      final analysis = SessionAnalysisResultModel.fromJson(json);

      expect(analysis.id, equals('analysis-111'));
      expect(analysis.sessionId, equals(validSessionGuid));
      expect(analysis.overallPerformanceScore, equals(87.5));
      expect(analysis.domainScore, equals(90.0));
      expect(analysis.supportiveObservations, equals('استجابة متسقة وسرعة بديهة ملحوظة.'));
      expect(analysis.fatigueObserved, isFalse);
      expect(analysis.recommendedDifficultyAdjustment, equals('Increase'));
      expect(analysis.difficultyAdjustmentEnum, equals(DifficultyAdjustment.increase));
      expect(analysis.difficultyAdjustmentEnum.badgeText, equals('زيادة الصعوبة'));
      expect(analysis.isFallbackResult, isFalse);
    });

    test('Parses CompletedSessionDto with nested AI analysis and metrics list', () {
      final json = {
        'id': validSessionGuid,
        'childId': validChildGuid,
        'activityId': validActivityGuid,
        'domain': 'Attention',
        'status': 'Completed',
        'startTimeUtc': '2026-09-10T12:00:00Z',
        'endTimeUtc': '2026-09-10T12:02:30Z',
        'actualDurationSeconds': 150,
        'analysisResult': {
          'id': 'analysis-222',
          'sessionId': validSessionGuid,
          'overallPerformanceScore': 75.0,
          'domainScore': 75.0,
          'supportiveObservations': 'أداء مستقر وثبات تركيز جيد.',
          'fatigueObserved': true,
          'recommendedDifficultyAdjustment': 'Maintain',
          'adaptiveParametersJson': null,
          'analyzedAtUtc': '2026-09-10T12:02:35Z',
          'isFallbackResult': true,
        },
        'metrics': [
          {
            'id': 'metric-1',
            'sessionId': validSessionGuid,
            'metricType': 'AttentionDurationSeconds',
            'value': 45.0,
            'timestampUtc': '2026-09-10T12:01:00Z',
          }
        ],
        'parentRating': 'Medium',
        'parentNotes': 'ملاحظات تجربة الجلسة',
      };

      final completed = CompletedSessionModel.fromJson(json);

      expect(completed.id, equals(validSessionGuid));
      expect(completed.actualDurationSeconds, equals(150));
      expect(completed.analysisResult, isNotNull);
      expect(completed.analysisResult!.fatigueObserved, isTrue);
      expect(completed.analysisResult!.difficultyAdjustmentEnum, equals(DifficultyAdjustment.maintain));
      expect(completed.metrics.length, equals(1));
      expect(completed.metrics.first.localizedTitle, equals('مدة التركيز المتواصل'));
      expect(completed.parentRatingEnum, equals(ParentSentimentRating.medium));
    });
  });

  group('3. Enums & Mappings Tests', () {
    test('SupportedMetricType maps all 6 backend metric types correctly', () {
      expect(SupportedMetricType.fromKey('RepetitionCount'), equals(SupportedMetricType.repetitionCount));
      expect(SupportedMetricType.fromKey('AccuracyPercentage'), equals(SupportedMetricType.accuracyPercentage));
      expect(SupportedMetricType.fromKey('ReactionTimeMs'), equals(SupportedMetricType.reactionTimeMs));
      expect(SupportedMetricType.fromKey('SpeechClarityScore'), equals(SupportedMetricType.speechClarityScore));
      expect(SupportedMetricType.fromKey('ResponseLatencyMs'), equals(SupportedMetricType.responseLatencyMs));
      expect(SupportedMetricType.fromKey('AttentionDurationSeconds'), equals(SupportedMetricType.attentionDurationSeconds));
      expect(SupportedMetricType.fromKey('UnsupportedMetric'), isNull);
    });

    test('ParentSentimentRating maps values 1, 2, 3 and strings correctly', () {
      expect(ParentSentimentRating.fromValue(1), equals(ParentSentimentRating.easy));
      expect(ParentSentimentRating.fromValue(2), equals(ParentSentimentRating.medium));
      expect(ParentSentimentRating.fromValue(3), equals(ParentSentimentRating.difficult));
      expect(ParentSentimentRating.fromValue('Easy'), equals(ParentSentimentRating.easy));
      expect(ParentSentimentRating.fromValue('Medium'), equals(ParentSentimentRating.medium));
      expect(ParentSentimentRating.fromValue('Difficult'), equals(ParentSentimentRating.difficult));
      expect(ParentSentimentRating.fromValue(99), isNull);
    });

    test('DifficultyAdjustment maps backend values properly', () {
      expect(DifficultyAdjustment.fromString('Increase'), equals(DifficultyAdjustment.increase));
      expect(DifficultyAdjustment.fromString('Decrease'), equals(DifficultyAdjustment.decrease));
      expect(DifficultyAdjustment.fromString('Maintain'), equals(DifficultyAdjustment.maintain));
      expect(DifficultyAdjustment.fromString('unknown'), equals(DifficultyAdjustment.maintain));
    });
  });

  group('4. SessionService Validation & Guard Tests', () {
    test('Throws ApiException when childId is not a valid GUID in startSession', () async {
      final service = SessionService();
      expect(
        () => service.startSession(const StartSessionRequest(
          childId: 'not-a-guid',
          activityId: validActivityGuid,
        )),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', equals(400))),
      );
    });

    test('Throws ApiException when activityId is not a valid GUID in startSession', () async {
      final service = SessionService();
      expect(
        () => service.startSession(const StartSessionRequest(
          childId: validChildGuid,
          activityId: 'invalid-guid',
        )),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', equals(400))),
      );
    });

    test('Throws ApiException when sessionId is not a valid GUID in completeSession', () async {
      final service = SessionService();
      expect(
        () => service.completeSession(
          sessionId: 'not-a-guid',
          request: const CompleteSessionRequest(actualDurationSeconds: 60),
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', equals(400))),
      );
    });

    test('Throws ApiException when actualDurationSeconds is negative in completeSession', () async {
      final service = SessionService();
      expect(
        () => service.completeSession(
          sessionId: validSessionGuid,
          request: const CompleteSessionRequest(actualDurationSeconds: -5),
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', equals(400))),
      );
    });
  });

  group('5. SessionService Endpoints & Mock Integration Tests', () {
    test('startSession calls POST /api/sessions and parses response and saves active session', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/sessions'));
        expect(options.method, equals('POST'));
        expect(options.data['childId'], equals(validChildGuid));
        expect(options.data['activityId'], equals(validActivityGuid));

        return ResponseBody.fromString(
          '''
          {
            "id": "$validSessionGuid",
            "childId": "$validChildGuid",
            "activityId": "$validActivityGuid",
            "domain": "Movement",
            "status": "Started",
            "startTimeUtc": "2026-09-10T12:00:00Z",
            "targetDifficulty": "Beginner",
            "adaptiveSettingsJson": null
          }
          ''',
          201,
          headers: {'content-type': ['application/json']},
        );
      });

      final mockStorage = _MockSecureStorageService();
      final apiClient = ApiClient(dio: dio);
      final service = SessionService(apiClient: apiClient, storage: mockStorage);

      final session = await service.startSession(const StartSessionRequest(
        childId: validChildGuid,
        activityId: validActivityGuid,
      ));

      expect(session.id, equals(validSessionGuid));
      expect(session.status, equals('Started'));
      expect(session.domain, equals('Movement'));
      expect(await mockStorage.getActiveSessionId(), equals(validSessionGuid));
    });

    test('recordMetrics calls POST /api/sessions/{id}/metrics and parses returned list', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/sessions/$validSessionGuid/metrics'));
        expect(options.method, equals('POST'));

        return ResponseBody.fromString(
          '''
          [
            {
              "id": "metric-11",
              "sessionId": "$validSessionGuid",
              "metricType": "RepetitionCount",
              "value": 15.0,
              "timestampUtc": "2026-09-10T12:01:00Z"
            }
          ]
          ''',
          200,
          headers: {'content-type': ['application/json']},
        );
      });

      final mockStorage = _MockSecureStorageService();
      final apiClient = ApiClient(dio: dio);
      final service = SessionService(apiClient: apiClient, storage: mockStorage);

      final metrics = await service.recordMetrics(
        sessionId: validSessionGuid,
        metrics: [const MetricInputModel(metricType: 'RepetitionCount', value: 15.0)],
      );

      expect(metrics.length, equals(1));
      expect(metrics.first.metricType, equals('RepetitionCount'));
      expect(metrics.first.value, equals(15.0));
    });

    test('completeSession calls POST /api/sessions/{id}/complete, parses AI analysis, and clears active session', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/sessions/$validSessionGuid/complete'));
        expect(options.method, equals('POST'));
        expect(options.data['actualDurationSeconds'], equals(120));

        return ResponseBody.fromString(
          '''
          {
            "id": "$validSessionGuid",
            "childId": "$validChildGuid",
            "activityId": "$validActivityGuid",
            "domain": "Movement",
            "status": "Completed",
            "startTimeUtc": "2026-09-10T12:00:00Z",
            "endTimeUtc": "2026-09-10T12:02:00Z",
            "actualDurationSeconds": 120,
            "analysisResult": {
              "id": "analysis-1",
              "sessionId": "$validSessionGuid",
              "overallPerformanceScore": 88.0,
              "domainScore": 90.0,
              "supportiveObservations": "استجابة ممتازة.",
              "fatigueObserved": false,
              "recommendedDifficultyAdjustment": "Increase",
              "adaptiveParametersJson": null,
              "analyzedAtUtc": "2026-09-10T12:02:05Z",
              "isFallbackResult": false
            },
            "metrics": []
          }
          ''',
          200,
          headers: {'content-type': ['application/json']},
        );
      });

      final mockStorage = _MockSecureStorageService();
      await mockStorage.saveActiveSessionId(validSessionGuid);

      final apiClient = ApiClient(dio: dio);
      final service = SessionService(apiClient: apiClient, storage: mockStorage);

      final completed = await service.completeSession(
        sessionId: validSessionGuid,
        request: const CompleteSessionRequest(actualDurationSeconds: 120),
      );

      expect(completed.id, equals(validSessionGuid));
      expect(completed.status, equals('Completed'));
      expect(completed.analysisResult, isNotNull);
      expect(completed.analysisResult!.overallPerformanceScore, equals(88.0));
      expect(completed.analysisResult!.recommendedDifficultyAdjustment, equals('Increase'));
      expect(await mockStorage.getActiveSessionId(), isNull);
    });

    test('recordFeedback calls POST /api/sessions/{id}/feedback and parses updated session', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/sessions/$validSessionGuid/feedback'));
        expect(options.method, equals('POST'));
        expect(options.data['rating'], equals(2));

        return ResponseBody.fromString(
          '''
          {
            "id": "$validSessionGuid",
            "childId": "$validChildGuid",
            "activityId": "$validActivityGuid",
            "domain": "Movement",
            "status": "Completed",
            "startTimeUtc": "2026-09-10T12:00:00Z",
            "actualDurationSeconds": 120,
            "metrics": [],
            "parentRating": "Medium",
            "parentNotes": "جيد جدًا"
          }
          ''',
          200,
          headers: {'content-type': ['application/json']},
        );
      });

      final mockStorage = _MockSecureStorageService();
      final apiClient = ApiClient(dio: dio);
      final service = SessionService(apiClient: apiClient, storage: mockStorage);

      final result = await service.recordFeedback(
        sessionId: validSessionGuid,
        request: const RecordFeedbackRequest(
          rating: ParentSentimentRating.medium,
          notes: 'جيد جدًا',
        ),
      );

      expect(result.parentRatingEnum, equals(ParentSentimentRating.medium));
      expect(result.parentNotes, equals('جيد جدًا'));
    });

    test('abandonSession calls POST /api/sessions/{id}/abandon, parses status, and clears active session', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/sessions/$validSessionGuid/abandon'));
        expect(options.method, equals('POST'));

        return ResponseBody.fromString(
          '''
          {
            "id": "$validSessionGuid",
            "childId": "$validChildGuid",
            "activityId": "$validActivityGuid",
            "domain": "Movement",
            "status": "Abandoned",
            "startTimeUtc": "2026-09-10T12:00:00Z"
          }
          ''',
          200,
          headers: {'content-type': ['application/json']},
        );
      });

      final mockStorage = _MockSecureStorageService();
      await mockStorage.saveActiveSessionId(validSessionGuid);

      final apiClient = ApiClient(dio: dio);
      final service = SessionService(apiClient: apiClient, storage: mockStorage);

      final abandoned = await service.abandonSession(validSessionGuid);

      expect(abandoned.isAbandoned, isTrue);
      expect(abandoned.status, equals('Abandoned'));
      expect(await mockStorage.getActiveSessionId(), isNull);
    });

    test('getSessionById calls GET /api/sessions/{id} and parses SessionDetailsModel', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/sessions/$validSessionGuid'));
        expect(options.method, equals('GET'));

        return ResponseBody.fromString(
          '''
          {
            "id": "$validSessionGuid",
            "childId": "$validChildGuid",
            "activity": {
              "id": "$validActivityGuid",
              "title": "Gentle Reach & Tap",
              "domain": "Movement",
              "baseDifficulty": "Beginner"
            },
            "domain": "Movement",
            "status": "Started",
            "startTimeUtc": "2026-09-10T12:00:00Z",
            "metrics": []
          }
          ''',
          200,
          headers: {'content-type': ['application/json']},
        );
      });

      final apiClient = ApiClient(dio: dio);
      final service = SessionService(apiClient: apiClient);

      final details = await service.getSessionById(validSessionGuid);

      expect(details.id, equals(validSessionGuid));
      expect(details.activity.title, equals('Gentle Reach & Tap'));
      expect(details.domain, equals('Movement'));
    });

    test('Logout or auth reset clears activeSessionId and prevents stale session recovery', () async {
      final mockStorage = _MockSecureStorageService();
      await mockStorage.saveActiveSessionId(validSessionGuid);
      expect(await mockStorage.getActiveSessionId(), equals(validSessionGuid));

      await mockStorage.clearAuth();

      expect(await mockStorage.getActiveSessionId(), isNull);
    });
  });
}
