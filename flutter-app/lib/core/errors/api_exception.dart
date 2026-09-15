import 'package:dio/dio.dart';

/// Standardized API exception and error parser for the Sawa application.
///
/// Handles ASP.NET Core RFC 7807 ProblemDetails responses, validation error dictionaries,
/// network timeouts, and connection errors, providing user-friendly Arabic messages.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? detail;
  final Map<String, List<String>>? errors;
  final bool isNetworkError;

  const ApiException({
    this.statusCode,
    required this.message,
    this.detail,
    this.errors,
    this.isNetworkError = false,
  });

  /// Extracts the first validation error message if present, or defaults to [message].
  String get firstErrorMessage {
    if (errors != null && errors!.isNotEmpty) {
      final firstKey = errors!.keys.first;
      final messages = errors![firstKey];
      if (messages != null && messages.isNotEmpty) {
        return messages.first;
      }
    }
    return detail ?? message;
  }

  /// Factory constructor to parse Dio errors into structured [ApiException].
  factory ApiException.fromDioException(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'انتهت مهلة الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.',
          isNetworkError: true,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'تعذر الاتصال بالخادم، يرجى التأكد من تشغيل الخادم والاتصال بالشبكة.',
          isNetworkError: true,
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'فشل التحقق من شهادة الأمان للاتصال بالخادم.',
          isNetworkError: true,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'تم إلغاء الطلب.',
        );

      case DioExceptionType.badResponse:
        return _parseBadResponse(dioError.response);

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: dioError.message != null && dioError.message!.isNotEmpty
              ? dioError.message!
              : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
          isNetworkError: true,
        );
    }
  }

  static ApiException _parseBadResponse(Response? response) {
    final status = response?.statusCode;
    final data = response?.data;

    String fallbackMessage = 'حدث خطأ أثناء معالجة الطلب ($status).';
    String? detail;
    Map<String, List<String>>? validationErrors;

    switch (status) {
      case 400:
        fallbackMessage = 'البيانات المدخلة غير صحيحة، يرجى التحقق والمحاولة مجدداً.';
        break;
      case 401:
        fallbackMessage = 'انتهت صلاحية الجلسة أو غير مصرح، يرجى تسجيل الدخول مجدداً.';
        break;
      case 403:
        fallbackMessage = 'عذراً، ليس لديك صلاحية الوصول إلى هذه العملية.';
        break;
      case 404:
        fallbackMessage = 'العنصر المطلوب غير موجود أو تم حذفه.';
        break;
      case 409:
        fallbackMessage = 'تعارض في البيانات، قد يكون العنصر مسجلاً بالفعل.';
        break;
      case 500:
      case 502:
      case 503:
        fallbackMessage = 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.';
        break;
    }

    if (data is Map<String, dynamic>) {
      // Parse ASP.NET Core ProblemDetails: detail, title, errors
      if (data.containsKey('detail') && data['detail'] is String) {
        detail = data['detail'] as String;
      }

      if (data.containsKey('title') && data['title'] is String) {
        fallbackMessage = data['title'] as String;
      }

      if (data.containsKey('errors') && data['errors'] is Map) {
        final rawErrors = data['errors'] as Map;
        validationErrors = {};
        rawErrors.forEach((key, val) {
          if (val is List) {
            validationErrors![key.toString()] =
                val.map((e) => e.toString()).toList();
          } else if (val is String) {
            validationErrors![key.toString()] = [val];
          }
        });
      }
    } else if (data is String && data.trim().isNotEmpty) {
      detail = data.trim();
    }

    // Determine the most specific user-facing message
    String finalMessage = fallbackMessage;
    if (validationErrors != null && validationErrors.isNotEmpty) {
      final firstKey = validationErrors.keys.first;
      final messages = validationErrors[firstKey];
      if (messages != null && messages.isNotEmpty) {
        finalMessage = messages.first;
      }
    } else if (detail != null && detail.isNotEmpty) {
      finalMessage = detail;
    }

    return ApiException(
      statusCode: status,
      message: finalMessage,
      detail: detail,
      errors: validationErrors,
    );
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
