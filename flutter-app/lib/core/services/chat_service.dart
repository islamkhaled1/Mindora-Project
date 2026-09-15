import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../models/chat_models.dart';
import '../network/api_client.dart';

/// Dedicated service for AI assistant communications with the ASP.NET Core backend.
/// Uses authenticated ApiClient with automatic Bearer token propagation.
class ChatService {
  final ApiClient _apiClient;

  ChatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  ApiClient get apiClient => _apiClient;

  /// Sends a message and current conversational turns to the backend AI endpoint (`POST /api/chat`).
  Future<ChatResponseModel> sendMessage({
    required String message,
    List<ChatMessageModel> conversation = const [],
  }) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'نص الرسالة مطلوب ولا يمكن أن يكون فارغاً.',
      );
    }

    final requestModel = ChatRequestModel(
      message: cleanMessage,
      conversation: conversation.isNotEmpty ? conversation : null,
    );

    try {
      final response = await _apiClient.post(
        ApiEndpoints.chat,
        data: requestModel.toJson(),
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final rawData = response.data;
      if (rawData is Map) {
        return ChatResponseModel.fromJson(
          Map<String, dynamic>.from(rawData),
        );
      }

      throw const ApiException(
        message: 'تنسيق استجابة غير متوقع من خادم المحادثة.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'تعذر الاتصال بالمساعد الذكي: ${e.toString()}',
      );
    }
  }
}
