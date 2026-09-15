import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/constants/api_endpoints.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/chat_models.dart';
import 'package:sawa/core/network/api_client.dart';
import 'package:sawa/core/services/chat_service.dart';

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
  group('1. Chat Models & Serialization Tests', () {
    test('ChatMessageModel serializes to role and content JSON correctly', () {
      final message = ChatMessageModel(
        role: 'user',
        content: 'كيف أساعد طفلي على الكلام؟',
      );

      final json = message.toJson();
      expect(json['role'], equals('user'));
      expect(json['content'], equals('كيف أساعد طفلي على الكلام؟'));
      expect(message.isUser, isTrue);
      expect(message.isAssistant, isFalse);
    });

    test('ChatMessageModel parses assistant message JSON correctly', () {
      final json = {
        'role': 'assistant',
        'content': 'التشجيع والتكرار اليومي لهما أثر كبير.',
        'timestamp': '2026-09-11T10:00:00Z',
        'isFallback': false,
      };

      final message = ChatMessageModel.fromJson(json);
      expect(message.role, equals('assistant'));
      expect(message.content, equals('التشجيع والتكرار اليومي لهما أثر كبير.'));
      expect(message.isAssistant, isTrue);
      expect(message.isUser, isFalse);
      expect(message.isFallback, isFalse);
    });

    test('ChatRequestModel serializes with conversation history correctly', () {
      final request = ChatRequestModel(
        message: 'سؤال جديد',
        conversation: [
          ChatMessageModel(role: 'user', content: 'سؤال سابق'),
          ChatMessageModel(role: 'assistant', content: 'جواب سابق'),
        ],
      );

      final json = request.toJson();
      expect(json['message'], equals('سؤال جديد'));
      final conversationList = json['conversation'] as List;
      expect(conversationList.length, equals(2));
      expect(conversationList[0]['role'], equals('user'));
      expect(conversationList[1]['role'], equals('assistant'));
    });

    test('ChatResponseModel parses backend response accurately', () {
      final json = {
        'reply': 'هذه نصيحة طبية لتأهيل النطق.',
        'role': 'assistant',
        'model': 'meta-llama/llama-3.1-8b-instruct',
        'createdAtUtc': '2026-09-11T10:00:00Z',
        'isFallback': false,
      };

      final response = ChatResponseModel.fromJson(json);
      expect(response.reply, equals('هذه نصيحة طبية لتأهيل النطق.'));
      expect(response.role, equals('assistant'));
      expect(response.model, equals('meta-llama/llama-3.1-8b-instruct'));
      expect(response.isFallback, isFalse);
    });
  });

  group('2. ChatService Validation & Error Handling Tests', () {
    test('Throws ApiException when message is empty or whitespace', () async {
      final service = ChatService();

      expect(
        () => service.sendMessage(message: '   '),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('نص الرسالة مطلوب'),
        )),
      );
    });

    test('Invokes POST /api/chat with conversation and parses response', () async {
      late RequestOptions capturedOptions;

      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        capturedOptions = options;

        final responsePayload = {
          'reply': 'رد تفاعلي من نموذج Llama 3.1',
          'role': 'assistant',
          'model': 'meta-llama/llama-3.1-8b-instruct',
          'createdAtUtc': '2026-09-11T10:05:00Z',
          'isFallback': false,
        };

        return ResponseBody.fromString(
          jsonEncode(responsePayload),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final apiClient = ApiClient(dio: dio);
      final service = ChatService(apiClient: apiClient);

      final result = await service.sendMessage(
        message: 'كيف أبدأ التمارين؟',
        conversation: [
          ChatMessageModel(role: 'user', content: 'مرحبا'),
        ],
      );

      expect(capturedOptions.path, equals(ApiEndpoints.chat));
      expect(capturedOptions.method, equals('POST'));
      expect(result.reply, equals('رد تفاعلي من نموذج Llama 3.1'));
      expect(result.model, equals('meta-llama/llama-3.1-8b-instruct'));
      expect(result.isFallback, isFalse);
    });
  });
}
