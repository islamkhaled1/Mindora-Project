import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/network/api_client.dart';
import 'package:sawa/core/services/activity_service.dart';

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
  group('1. ActivityModel Deserialization Tests', () {
    test('Parses camelCase backend ActivityDto correctly', () {
      final json = {
        'id': 'a1111111-2222-3333-4444-555555555555',
        'title': 'Gentle Reach & Tap',
        'description':
            'Interactive visual targets appear to guide bilateral arm reaching.',
        'domain': 'Movement',
        'baseDifficulty': 'Beginner',
        'adaptiveSettingsJson':
            '{"targetCount": 10, "cueSpeedMs": 1200, "targetSizePx": 80}',
        'createdAtUtc': '2026-09-04T12:00:00Z',
      };

      final activity = ActivityModel.fromJson(json);

      expect(activity.id, equals('a1111111-2222-3333-4444-555555555555'));
      expect(activity.title, equals('Gentle Reach & Tap'));
      expect(
        activity.description,
        equals(
            'Interactive visual targets appear to guide bilateral arm reaching.'),
      );
      expect(activity.domain, equals('Movement'));
      expect(activity.baseDifficulty, equals('Beginner'));
      expect(
        activity.adaptiveSettingsJson,
        equals('{"targetCount": 10, "cueSpeedMs": 1200, "targetSizePx": 80}'),
      );
      expect(activity.domainArabicLabel, equals('حركي'));
      expect(activity.difficultyArabicLabel, equals('مبتدئ'));
      expect(activity.domainIcon, equals(Icons.directions_run_rounded));
      expect(activity.createdAtUtc, isNotNull);
    });

    test('Parses PascalCase backend ActivityDto defensively', () {
      final json = {
        'Id': 'b2222222-3333-4444-5555-666666666666',
        'Title': 'Vowel Safari Sounds',
        'Description': 'Playful phoneme repetition game encouraging vowel articulation.',
        'Domain': 'Speech',
        'BaseDifficulty': 'Intermediate',
        'AdaptiveSettingsJson': null,
        'CreatedAtUtc': '2026-09-05T08:30:00Z',
      };

      final activity = ActivityModel.fromJson(json);

      expect(activity.id, equals('b2222222-3333-4444-5555-666666666666'));
      expect(activity.title, equals('Vowel Safari Sounds'));
      expect(activity.domain, equals('Speech'));
      expect(activity.baseDifficulty, equals('Intermediate'));
      expect(activity.adaptiveSettingsJson, isNull);
      expect(activity.domainArabicLabel, equals('لغوي ونطق'));
      expect(activity.difficultyArabicLabel, equals('متوسط'));
      expect(activity.domainIcon, equals(Icons.record_voice_over_rounded));
    });

    test('Handles null adaptiveSettingsJson and missing dates safely', () {
      final json = {
        'id': 'c3333333-4444-5555-6666-777777777777',
        'title': 'Gaze & Star Focus',
        'description': 'Visual attention exercise tracking focus duration.',
        'domain': 'Attention',
        'baseDifficulty': 'Advanced',
      };

      final activity = ActivityModel.fromJson(json);

      expect(activity.id, equals('c3333333-4444-5555-6666-777777777777'));
      expect(activity.domainArabicLabel, equals('انتباه وتركيز'));
      expect(activity.difficultyArabicLabel, equals('متقدم'));
      expect(activity.domainIcon, equals(Icons.psychology_rounded));
      expect(activity.adaptiveSettingsJson, isNull);
      expect(activity.createdAtUtc, isNull);
    });

    test('Serializes to JSON matching backend contract without fabricated fields', () {
      const activity = ActivityModel(
        id: 'test-id',
        title: 'Test Title',
        description: 'Test Description',
        domain: 'Movement',
        baseDifficulty: 'Beginner',
      );

      final json = activity.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['title'], equals('Test Title'));
      expect(json['description'], equals('Test Description'));
      expect(json['domain'], equals('Movement'));
      expect(json['baseDifficulty'], equals('Beginner'));
      expect(json.containsKey('duration'), isFalse);
      expect(json.containsKey('instructions'), isFalse);
      expect(json.containsKey('calories'), isFalse);
    });
  });

  group('2. ActivityPerformanceModel Deserialization Tests', () {
    test('Parses ActivityPerformanceDto with complete metrics', () {
      final json = {
        'activityId': 'act-guid-1',
        'activityTitle': 'Gentle Reach & Tap',
        'domain': 'Movement',
        'baseDifficulty': 'Beginner',
        'timesPlayed': 5,
        'totalPracticeMinutes': 25,
        'averageScore': 88.5,
        'bestScore': 95.0,
        'latestScore': 90.0,
        'averageAccuracyPercentage': 92.4,
        'averageReactionTimeMs': 450.0,
        'averageRepetitions': 12.0,
        'lastPlayedUtc': '2026-09-08T10:00:00Z',
      };

      final perf = ActivityPerformanceModel.fromJson(json);

      expect(perf.activityId, equals('act-guid-1'));
      expect(perf.activityTitle, equals('Gentle Reach & Tap'));
      expect(perf.domain, equals('Movement'));
      expect(perf.baseDifficulty, equals('Beginner'));
      expect(perf.timesPlayed, equals(5));
      expect(perf.totalPracticeMinutes, equals(25));
      expect(perf.averageScore, equals(88.5));
      expect(perf.bestScore, equals(95.0));
      expect(perf.latestScore, equals(90.0));
      expect(perf.averageAccuracyPercentage, equals(92.4));
      expect(perf.averageReactionTimeMs, equals(450.0));
      expect(perf.averageRepetitions, equals(12.0));
      expect(perf.domainArabicLabel, equals('حركي'));
      expect(perf.difficultyArabicLabel, equals('مبتدئ'));
    });

    test('Parses ActivityPerformanceDto with null optional telemetry metrics', () {
      final json = {
        'ActivityId': 'act-guid-2',
        'ActivityTitle': 'Vowel Safari Sounds',
        'Domain': 'Speech',
        'BaseDifficulty': 'Intermediate',
        'TimesPlayed': 1,
        'TotalPracticeMinutes': 3,
        'AverageScore': 75.0,
        'BestScore': 75.0,
        'LatestScore': 75.0,
        'AverageAccuracyPercentage': null,
        'AverageReactionTimeMs': null,
        'AverageRepetitions': null,
        'LastPlayedUtc': '2026-09-09T15:20:00Z',
      };

      final perf = ActivityPerformanceModel.fromJson(json);

      expect(perf.activityId, equals('act-guid-2'));
      expect(perf.timesPlayed, equals(1));
      expect(perf.averageAccuracyPercentage, isNull);
      expect(perf.averageReactionTimeMs, isNull);
      expect(perf.averageRepetitions, isNull);
    });
  });

  group('3. Domain and Difficulty Enums Tests', () {
    test('ActivityDomainEnum fromString normalizes case and matches backend values', () {
      expect(ActivityDomainEnum.fromString('Movement'), equals(ActivityDomainEnum.movement));
      expect(ActivityDomainEnum.fromString('movement'), equals(ActivityDomainEnum.movement));
      expect(ActivityDomainEnum.fromString('Speech'), equals(ActivityDomainEnum.speech));
      expect(ActivityDomainEnum.fromString('SPEECH'), equals(ActivityDomainEnum.speech));
      expect(ActivityDomainEnum.fromString('Attention'), equals(ActivityDomainEnum.attention));
      expect(ActivityDomainEnum.fromString('attention'), equals(ActivityDomainEnum.attention));
      expect(ActivityDomainEnum.fromString('UnknownDomain'), isNull);
      expect(ActivityDomainEnum.fromString(null), isNull);
      expect(ActivityDomainEnum.fromString('  '), isNull);
    });

    test('ActivityDifficultyEnum fromString normalizes case and matches backend values', () {
      expect(ActivityDifficultyEnum.fromString('Beginner'), equals(ActivityDifficultyEnum.beginner));
      expect(ActivityDifficultyEnum.fromString('beginner'), equals(ActivityDifficultyEnum.beginner));
      expect(ActivityDifficultyEnum.fromString('Intermediate'), equals(ActivityDifficultyEnum.intermediate));
      expect(ActivityDifficultyEnum.fromString('advanced'), equals(ActivityDifficultyEnum.advanced));
      expect(ActivityDifficultyEnum.fromString('ADVANCED'), equals(ActivityDifficultyEnum.advanced));
      expect(ActivityDifficultyEnum.fromString('Easy'), isNull);
      expect(ActivityDifficultyEnum.fromString('Hard'), isNull);
      expect(ActivityDifficultyEnum.fromString(null), isNull);
    });
  });

  group('4. ActivityService Unit & Integration Tests', () {
    test('Throws ApiException when activityId is empty in getActivityById', () async {
      final service = ActivityService();
      expect(
        () => service.getActivityById(''),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('Throws ApiException when childId is empty in getChildActivityPerformance', () async {
      final service = ActivityService();
      expect(
        () => service.getChildActivityPerformance('   '),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('getActivities without query parameters calls GET /api/activities and parses list', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/activities'));
        expect(options.method, equals('GET'));
        expect(options.queryParameters, isEmpty);

        return ResponseBody.fromString(
          '''
          [
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "title": "Gentle Reach & Tap",
              "description": "Coordination exercise",
              "domain": "Movement",
              "baseDifficulty": "Beginner",
              "adaptiveSettingsJson": null,
              "createdAtUtc": "2026-09-04T12:00:00Z"
            },
            {
              "id": "22222222-2222-2222-2222-222222222222",
              "title": "Vowel Safari Sounds",
              "description": "Speech exercise",
              "domain": "Speech",
              "baseDifficulty": "Beginner",
              "adaptiveSettingsJson": null,
              "createdAtUtc": "2026-09-04T12:00:00Z"
            }
          ]
          ''',
          200,
          headers: {
            'content-type': ['application/json']
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final service = ActivityService(apiClient: apiClient);

      final list = await service.getActivities();

      expect(list.length, equals(2));
      expect(list[0].title, equals('Gentle Reach & Tap'));
      expect(list[0].domainArabicLabel, equals('حركي'));
      expect(list[1].title, equals('Vowel Safari Sounds'));
      expect(list[1].domainArabicLabel, equals('لغوي ونطق'));
    });

    test('getActivities with domain and difficulty sets backend query parameters', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/activities'));
        expect(options.method, equals('GET'));
        expect(options.queryParameters['domain'], equals('Movement'));
        expect(options.queryParameters['difficulty'], equals('Beginner'));

        return ResponseBody.fromString(
          '''
          [
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "title": "Gentle Reach & Tap",
              "description": "Coordination exercise",
              "domain": "Movement",
              "baseDifficulty": "Beginner",
              "adaptiveSettingsJson": null,
              "createdAtUtc": "2026-09-04T12:00:00Z"
            }
          ]
          ''',
          200,
          headers: {
            'content-type': ['application/json']
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final service = ActivityService(apiClient: apiClient);

      final list = await service.getActivities(
        domain: 'Movement',
        difficulty: 'Beginner',
      );

      expect(list.length, equals(1));
      expect(list.first.title, equals('Gentle Reach & Tap'));
    });

    test('getActivityById calls GET /api/activities/{id} and parses ActivityModel', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(
          options.path,
          equals('/api/activities/33333333-3333-3333-3333-333333333333'),
        );
        expect(options.method, equals('GET'));

        return ResponseBody.fromString(
          '''
          {
            "id": "33333333-3333-3333-3333-333333333333",
            "title": "Gaze & Star Focus",
            "description": "Attention exercise",
            "domain": "Attention",
            "baseDifficulty": "Intermediate",
            "adaptiveSettingsJson": "{\\"sustainTargetSeconds\\": 30}",
            "createdAtUtc": "2026-09-04T12:00:00Z"
          }
          ''',
          200,
          headers: {
            'content-type': ['application/json']
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final service = ActivityService(apiClient: apiClient);

      final activity = await service.getActivityById('33333333-3333-3333-3333-333333333333');

      expect(activity.id, equals('33333333-3333-3333-3333-333333333333'));
      expect(activity.title, equals('Gaze & Star Focus'));
      expect(activity.domainArabicLabel, equals('انتباه وتركيز'));
      expect(activity.difficultyArabicLabel, equals('متوسط'));
      expect(activity.adaptiveSettingsJson, contains('sustainTargetSeconds'));
    });

    test('getChildActivityPerformance calls GET /api/children/{childId}/activities/performance and parses list', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        expect(
          options.path,
          equals('/api/children/child-123/activities/performance'),
        );
        expect(options.method, equals('GET'));

        return ResponseBody.fromString(
          '''
          [
            {
              "activityId": "act-1",
              "activityTitle": "Gentle Reach & Tap",
              "domain": "Movement",
              "baseDifficulty": "Beginner",
              "timesPlayed": 3,
              "totalPracticeMinutes": 15,
              "averageScore": 90.0,
              "bestScore": 95.0,
              "latestScore": 92.0,
              "averageAccuracyPercentage": 89.0,
              "averageReactionTimeMs": 520.0,
              "averageRepetitions": 10.0,
              "lastPlayedUtc": "2026-09-09T10:00:00Z"
            }
          ]
          ''',
          200,
          headers: {
            'content-type': ['application/json']
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final service = ActivityService(apiClient: apiClient);

      final performanceList =
          await service.getChildActivityPerformance('child-123');

      expect(performanceList.length, equals(1));
      expect(performanceList[0].activityTitle, equals('Gentle Reach & Tap'));
      expect(performanceList[0].timesPlayed, equals(3));
      expect(performanceList[0].averageScore, equals(90.0));
      expect(performanceList[0].domainArabicLabel, equals('حركي'));
    });
  });
}
