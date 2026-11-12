import 'package:dio/dio.dart';

/// Types of documentation pages we support.
enum DocsTopic {
  student,
  admin;

  String get fileName => switch (this) {
    DocsTopic.student => 'student',
    DocsTopic.admin => 'admin',
  };
}

class DocsApi {
  final Dio _dio;
  final String baseUrl;

  /// baseUrl is the root where the docs directory lives (e.g., a GitHub raw URL or hosting URL).
  /// Example: https://your-host.com
  /// The API will fetch: <baseUrl>/docs/<file>.md
  DocsApi({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  /// Fetch raw markdown for a given docs topic.
  Future<String> fetchMarkdown(DocsTopic topic) async {
    try {
      final response = await _dio.get<String>(
        baseUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final data = response.data ?? '';
      if (data.trim().isEmpty) {
        throw Exception('Empty docs content for ${topic.fileName}.md');
      }
      return data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw Exception(
        'Failed to load docs (${topic.fileName}.md). HTTP ${status ?? ''}',
      );
    } catch (e) {
      rethrow;
    }
  }
}
