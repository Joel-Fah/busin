import 'package:dio/dio.dart';

class LegalApi {
  final Dio _dio;
  final String baseUrl;

  /// baseUrl is the root where the legal.md file lives (e.g., a GitHub raw URL or hosting URL).
  /// Example: https://your-host.com/legal.md
  LegalApi({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  /// Fetch raw markdown for legal content.
  Future<String> fetchLegalMarkdown() async {
    try {
      final response = await _dio.get<String>(
        baseUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final data = response.data ?? '';
      if (data.trim().isEmpty) {
        throw Exception('Empty legal content');
      }
      return data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw Exception(
        'Failed to load legal content. HTTP ${status ?? 'Error'}',
      );
    } catch (e) {
      rethrow;
    }
  }
}

