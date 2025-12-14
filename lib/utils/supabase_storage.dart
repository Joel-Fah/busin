import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _getSupabaseClient() {
  final client = Supabase.instance.client;
  return client;
}

Future<String> uploadFileToSupabaseStorage({
  required File file,
  required String bucket,
  required String objectPath,
  bool upsert = true,
}) async {
  final client = _getSupabaseClient();
  final storage = client.storage.from(bucket);

  if (!await file.exists()) {
    throw Exception('File Not Found : ${file.path}');
  }

  try {
    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    if (kDebugMode) {
      debugPrint(
        '[SupabaseStorage] Uploading to "$bucket" as "$objectPath" (mime: $mimeType)',
      );
    }

    await storage.uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(
        cacheControl: '3600',
        contentType: mimeType,
        upsert: upsert,
      ),
    );

    final publicUrl = storage.getPublicUrl(objectPath);
    if (kDebugMode) {
      debugPrint('[SupabaseStorage] Uploaded $objectPath -> $publicUrl');
    }
    return publicUrl;
  } on StorageException catch (e) {
    if (kDebugMode) {
      debugPrint(
        '[SupabaseStorage] StorageException: code=${e.statusCode}, message=${e.message}',
      );
    }
    final msg = e.message;
    if (msg.contains('InvalidSignature')) {
      throw Exception(
        'Supabase rejected the credentials (InvalidSignature). Verify SUPABASE_URL points to your project and SUPABASE_PUBLISHABLE_KEY is the anon key with storage insert access.',
      );
    }
    throw Exception('Error uploading to Supabase: $msg');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[SupabaseStorage] Unexpected error: $e');
    }
    throw Exception('Unexpected Supabase error: $e');
  }
}
