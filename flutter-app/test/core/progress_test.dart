import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/progress_models.dart';
import 'package:sawa/core/network/api_client.dart';
import 'package:sawa/core/services/progress_service.dart';
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
  Future<void> saveActiveChildId(String childId) async {
    _inMemory['active_child_id'] = childId;
  }

  @override
  Future<String?> getActiveChildId() async {
    return _inMemory['active_child_id'];
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

  group('1. Progress Models & Serialization Tests', () {
    test('Parses camelCase backend ChildProgressSummaryDto correctly', () {
      final json = {
        'childId': validChildGuid,
        'totalCompletedSessions': 15,
        'totalPracticeMinutes': 75,
        'overallAverageScore': 86.5,
        'currentStreakDays': 4,
        'recentPerformanceTrend': 'Improving',
        'domainSummaries': [
          {
            'domain': 'Movement',
            'completedSessions': 7,
            'averageScore': 88.0,
            'latestScore': 92.5,
            'trend': 'Improving',
          },
          {
            'domain': 'Speech',
            'completedSessions': 5,
            'averageScore': 82.0,
            'latestScore': 80.0,
            'trend': 'Steady',
          },
          {
            'domain': 'Attention',
            'completedSessions': 3,
            'averageScore': 75.0,
            'latestScore': 70.0,
            'trend': 'NeedsSupport',
          },
        ],
      };

      final summary = ChildProgressSummaryModel.fromJson(json);

      expect(summary.childId, equals(validChildGuid));
      expect(summary.totalCompletedSessions, equals(15));
      expect(summary.totalPracticeMinutes, equals(75));
      expect(summary.overallAverageScore, equals(86.5));
      expect(summary.currentStreakDays, equals(4));
      expect(summary.recentPerformanceTrend, equals('Improving'));
      expect(summary.trendEnum, equals(PerformanceTrendEnum.improving));
      expect(summary.domainSummaries.length, equals(3));

      // Domain 1
      final mov = summary.domainSummaries[0];
      expect(mov.domain, equals('Movement'));
      expect(mov.domainArabicLabel, equals('حركي'));
      expect(mov.completedSessions, equals(7));
      expect(mov.averageScore, equals(88.0));
      expect(mov.latestScore, equals(92.5));
      expect(mov.trendEnum, equals(PerformanceTrendEnum.improving));

      // Domain 2
      final sp = summary.domainSummaries[1];
      expect(sp.domain, equals('Speech'));
      expect(sp.domainArabicLabel, equals('لغوي ونطق'));
      expect(sp.trendEnum, equals(PerformanceTrendEnum.steady));

      // Domain 3
      final att = summary.domainSummaries[2];
      expect(att.domain, equals('Attention'));
      expect(att.domainArabicLabel, equals('انتباه وتركيز'));
      expect(att.trendEnum, equals(PerformanceTrendEnum.needsSupport));
    });

    test('Parses PascalCase backend ChildProgressSummaryDto defensively', () {
      final json = {
        'ChildId': validChildGuid,
        'TotalCompletedSessions': 0,
        'TotalPracticeMinutes': 0,
        'OverallAverageScore': 0.0,
        'CurrentStreakDays': 0,
        'RecentPerformanceTrend': 'Steady',
        'DomainSummaries': <Map<String, dynamic>>[],
      };

      final summary = ChildProgressSummaryModel.fromJson(json);

      expect(summary.childId, equals(validChildGuid));
      expect(summary.totalCompletedSessions, equals(0));
      expect(summary.totalPracticeMinutes, equals(0));
      expect(summary.overallAverageScore, equals(0.0));
      expect(summary.currentStreakDays, equals(0));
      expect(summary.trendEnum, equals(PerformanceTrendEnum.steady));
      expect(summary.domainSummaries, isEmpty);
    });

    test('Parses SessionHistoryPointDto correctly', () {
      final json = {
        'sessionId': validSessionGuid,
        'activityTitle': 'مطابقة البطاقات',
        'domain': 'Attention',
        'score': 95.0,
        'durationSeconds': 120,
        'completedAtUtc': '2026-09-10T14:30:00Z',
      };

      final point = SessionHistoryPointModel.fromJson(json);

      expect(point.sessionId, equals(validSessionGuid));
      expect(point.activityTitle, equals('مطابقة البطاقات'));
      expect(point.domain, equals('Attention'));
      expect(point.domainArabicLabel, equals('انتباه وتركيز'));
      expect(point.score, equals(95.0));
      expect(point.durationSeconds, equals(120));
      expect(point.completedAtUtc.isUtc, isTrue);
      expect(point.completedAtUtc.year, equals(2026));
    });

    test('Verifies ActivityPerformanceModel compatibility and re-export', () {
      final json = {
        'activityId': validActivityGuid,
        'activityTitle': 'تمارين التوازن',
        'domain': 'Movement',
        'baseDifficulty': 'Beginner',
        'timesPlayed': 6,
        'totalPracticeMinutes': 48,
        'averageScore': 85.0,
        'bestScore': 95.0,
        'latestScore': 90.0,
        'averageAccuracyPercentage': 92.5,
        'averageReactionTimeMs': 450.0,
        'averageRepetitions': 10.0,
        'lastPlayedUtc': '2026-09-10T16:00:00Z',
      };

      final perf = ActivityPerformanceModel.fromJson(json);

      expect(perf.activityId, equals(validActivityGuid));
      expect(perf.activityTitle, equals('تمارين التوازن'));
      expect(perf.domainArabicLabel, equals('حركي'));
      expect(perf.difficultyArabicLabel, equals('مبتدئ'));
      expect(perf.timesPlayed, equals(6));
      expect(perf.averageAccuracyPercentage, equals(92.5));
      expect(perf.averageReactionTimeMs, equals(450.0));
      expect(perf.averageRepetitions, equals(10.0));
    });
  });

  group('2. Formatting Helpers Presentation Tests', () {
    test('Formats practice minutes non-destructively', () {
      expect(ProgressFormatters.formatPracticeMinutes(0), equals('0 دقيقة'));
      expect(ProgressFormatters.formatPracticeMinutes(45), equals('45 دقيقة'));
      expect(ProgressFormatters.formatPracticeMinutes(60), equals('ساعة واحدة'));
      expect(ProgressFormatters.formatPracticeMinutes(75), equals('ساعة واحدة و 15 دقيقة'));
      expect(ProgressFormatters.formatPracticeMinutes(120), equals('ساعتان'));
      expect(ProgressFormatters.formatPracticeMinutes(180), equals('3 ساعات'));
      expect(ProgressFormatters.formatPracticeMinutes(195), equals('3 ساعات و 15 دقيقة'));
    });

    test('Formats duration seconds non-destructively', () {
      expect(ProgressFormatters.formatDurationSeconds(0), equals('0 ثانية'));
      expect(ProgressFormatters.formatDurationSeconds(30), equals('30 ثانية'));
      expect(ProgressFormatters.formatDurationSeconds(60), equals('دقيقة واحدة'));
      expect(ProgressFormatters.formatDurationSeconds(90), equals('دقيقة واحدة و 30 ثانية'));
      expect(ProgressFormatters.formatDurationSeconds(120), equals('دقيقتان'));
      expect(ProgressFormatters.formatDurationSeconds(125), equals('دقيقتان و 5 ثوانٍ'));
    });

    test('Formats completed date into readable localized string', () {
      final dt = DateTime.utc(2026, 9, 10, 14, 30);
      final formatted = ProgressFormatters.formatCompletedDate(dt);
      expect(formatted, contains('2026/09/10'));
      expect(formatted, anyOf(contains('م'), contains('ص')));
    });
  });

  group('3. ProgressService Integration & Validation Tests', () {
    late ApiClient apiClient;
    late ProgressService service;
    late _MockSecureStorageService mockStorage;

    setUp(() {
      final dio = Dio(BaseOptions(baseUrl: 'http://test-api:5000'));
      mockStorage = _MockSecureStorageService();
      apiClient = ApiClient(dio: dio, storage: mockStorage);
      service = ProgressService(apiClient: apiClient, storage: mockStorage);
    });

    test('getChildProgress validates GUID before network call', () async {
      expect(
        () => service.getChildProgress('invalid-guid'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('getChildProgress returns ChildProgressSummaryModel on success', () async {
      apiClient.dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.method, equals('GET'));
        expect(options.path, equals('/api/children/$validChildGuid/progress'));

        final body = jsonEncode({
          'childId': validChildGuid,
          'totalCompletedSessions': 10,
          'totalPracticeMinutes': 60,
          'overallAverageScore': 85.0,
          'currentStreakDays': 3,
          'recentPerformanceTrend': 'Improving',
          'domainSummaries': [
            {
              'domain': 'Movement',
              'completedSessions': 5,
              'averageScore': 85.0,
              'latestScore': 90.0,
              'trend': 'Improving',
            }
          ],
        });

        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final summary = await service.getChildProgress(validChildGuid);
      expect(summary.childId, equals(validChildGuid));
      expect(summary.totalCompletedSessions, equals(10));
      expect(summary.trendEnum, equals(PerformanceTrendEnum.improving));
    });

    test('getProgressHistory builds query parameters and returns points', () async {
      apiClient.dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.method, equals('GET'));
        expect(options.path, equals('/api/children/$validChildGuid/progress/history'));
        expect(options.queryParameters['page'], equals(2));
        expect(options.queryParameters['pageSize'], equals(20));
        expect(options.queryParameters['domain'], equals('Speech'));
        expect(options.queryParameters['fromDate'], isNotNull);

        final body = jsonEncode([
          {
            'sessionId': validSessionGuid,
            'activityTitle': 'تكرار الكلمات',
            'domain': 'Speech',
            'score': 88.0,
            'durationSeconds': 90,
            'completedAtUtc': '2026-09-10T12:00:00Z',
          }
        ]);

        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final history = await service.getProgressHistory(
        validChildGuid,
        domain: 'Speech',
        fromDate: DateTime.utc(2026, 9, 1),
        page: 2,
        pageSize: 20,
      );

      expect(history.length, equals(1));
      expect(history[0].activityTitle, equals('تكرار الكلمات'));
      expect(history[0].score, equals(88.0));
    });

    test('getProgressHistory rejects page < 1 with 400 ApiException', () async {
      expect(
        () => service.getProgressHistory(validChildGuid, page: 0),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('getActivityPerformance fetches activity list for child', () async {
      apiClient.dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.method, equals('GET'));
        expect(
          options.path,
          equals('/api/children/$validChildGuid/activities/performance'),
        );

        final body = jsonEncode([
          {
            'activityId': validActivityGuid,
            'activityTitle': 'تتبع الأشكال',
            'domain': 'Attention',
            'baseDifficulty': 'Beginner',
            'timesPlayed': 3,
            'totalPracticeMinutes': 25,
            'averageScore': 90.0,
            'bestScore': 95.0,
            'latestScore': 92.0,
            'averageAccuracyPercentage': 95.0,
            'averageReactionTimeMs': 380.0,
            'averageRepetitions': 8.0,
            'lastPlayedUtc': '2026-09-10T15:00:00Z',
          }
        ]);

        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final perfs = await service.getActivityPerformance(validChildGuid);
      expect(perfs.length, equals(1));
      expect(perfs[0].activityTitle, equals('تتبع الأشكال'));
      expect(perfs[0].averageScore, equals(90.0));
    });

    test('Propagates HTTP 500 server error as ApiException', () async {
      apiClient.dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Internal Server Error'}),
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      expect(
        () => service.getChildProgress(validChildGuid),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(500),
        )),
      );
    });

    test('Propagates HTTP 401 Unauthorized as ApiException', () async {
      apiClient.dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Unauthorized access'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      expect(
        () => service.getChildProgress(validChildGuid),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(401),
        )),
      );
    });

    test('getActivityPerformance validates GUID before network call', () async {
      expect(
        () => service.getActivityPerformance('invalid-guid'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('getProgressHistory clamps pageSize exceeding 100 down to 100', () async {
      apiClient.dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.queryParameters['pageSize'], equals(100));
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final result = await service.getProgressHistory(validChildGuid, pageSize: 250);
      expect(result, isEmpty);
    });

    test('getProgressHistory formats toDate parameter in UTC ISO-8601', () async {
      final targetDate = DateTime.utc(2026, 9, 10, 18, 0, 0);
      apiClient.dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.queryParameters['toDate'], equals(targetDate.toIso8601String()));
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await service.getProgressHistory(validChildGuid, toDate: targetDate);
    });
  });

  group('4. Performance Trend & Pagination Logic Tests', () {
    test('PerformanceTrendEnum handles casing variations and returns null on unknown', () {
      expect(PerformanceTrendEnum.fromString('improving'), equals(PerformanceTrendEnum.improving));
      expect(PerformanceTrendEnum.fromString('IMPROVING'), equals(PerformanceTrendEnum.improving));
      expect(PerformanceTrendEnum.fromString('Steady'), equals(PerformanceTrendEnum.steady));
      expect(PerformanceTrendEnum.fromString('steady'), equals(PerformanceTrendEnum.steady));
      expect(PerformanceTrendEnum.fromString('needssupport'), equals(PerformanceTrendEnum.needsSupport));
      expect(PerformanceTrendEnum.fromString('NeedsSupport'), equals(PerformanceTrendEnum.needsSupport));
      expect(PerformanceTrendEnum.fromString('unknown_trend'), isNull);
      expect(PerformanceTrendEnum.fromString(null), isNull);
      expect(PerformanceTrendEnum.fromString(''), isNull);
    });

    test('SessionHistoryPointModel gracefully falls back when completedAtUtc is missing or malformed', () {
      final json = {
        'sessionId': validSessionGuid,
        'activityTitle': 'تمارين التنسيق',
        'domain': 'Movement',
        'score': 85.0,
        'durationSeconds': 90,
        'completedAtUtc': 'not-a-valid-date',
      };

      final point = SessionHistoryPointModel.fromJson(json);
      expect(point.sessionId, equals(validSessionGuid));
      expect(point.completedAtUtc, isNotNull);
      expect(point.completedAtUtc.isUtc, isTrue);
    });

    test('Simulates multi-page pagination flow with exhaustion detection', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      int requestedPage = 0;

      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        requestedPage = options.queryParameters['page'] as int;

        if (requestedPage == 1) {
          // Return full page of 20 items
          final items = List.generate(
            20,
            (i) => {
              'sessionId': '00000000-0000-0000-0000-${i.toString().padLeft(12, '0')}',
              'activityTitle': 'نشاط رقم $i',
              'domain': 'Movement',
              'score': 80.0 + i,
              'durationSeconds': 60,
              'completedAtUtc': '2026-09-0${(i % 9) + 1}T10:00:00Z',
            },
          );
          return ResponseBody.fromString(
            jsonEncode(items),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        } else if (requestedPage == 2) {
          // Return partial page of 5 items (exhaustion)
          final items = List.generate(
            5,
            (i) => {
              'sessionId': '11111111-0000-0000-0000-${i.toString().padLeft(12, '0')}',
              'activityTitle': 'نشاط إضافي $i',
              'domain': 'Movement',
              'score': 90.0,
              'durationSeconds': 80,
              'completedAtUtc': '2026-09-10T10:00:00Z',
            },
          );
          return ResponseBody.fromString(
            jsonEncode(items),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        return ResponseBody.fromString('[]', 200);
      });

      final service = ProgressService(apiClient: ApiClient(dio: dio));

      // Page 1
      final page1 = await service.getProgressHistory(validChildGuid, page: 1, pageSize: 20);
      expect(page1.length, equals(20));
      final bool hasMoreAfterPage1 = page1.length >= 20;
      expect(hasMoreAfterPage1, isTrue);

      // Page 2
      final page2 = await service.getProgressHistory(validChildGuid, page: 2, pageSize: 20);
      expect(page2.length, equals(5));
      final bool hasMoreAfterPage2 = page2.length >= 20;
      expect(hasMoreAfterPage2, isFalse); // Pagination exhausted
    });
  });
}
