import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:image_picker/image_picker.dart';

enum ProofSource { camera, gallery }

/// A chosen photo, checked against the same rules the bucket enforces.
class PickedProof {
  const PickedProof({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

/// Why a photo cannot be used.
enum ProofProblem { type, tooLarge }

class ProofException implements Exception {
  const ProofException(this.problem);

  final ProofProblem problem;
}

/// Finds out what kind of image the bytes really are, from their first bytes. The file name and the
/// type the picker reports are not trusted. Null when it is not a JPEG, PNG or WebP.
String? sniffImageType(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'image/jpeg';
  if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47 && b[4] == 0x0D && b[5] == 0x0A && b[6] == 0x1A && b[7] == 0x0A) {
    return 'image/png';
  }
  if (b.length >= 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

/// Checks bytes the way the upload will, so a problem is shown now and not after a wait.
PickedProof checkProof(Uint8List bytes) {
  final type = sniffImageType(bytes);
  if (type == null || !ProofRules.contentTypes.contains(type)) throw const ProofException(ProofProblem.type);
  if (bytes.length > ProofRules.maxBytes) throw const ProofException(ProofProblem.tooLarge);
  return PickedProof(bytes: bytes, contentType: type);
}

/// Takes or chooses a photo. An interface so tests do not need a camera.
abstract interface class ProofPicker {
  /// The chosen photo, or null if the person backed out. Throws [ProofException] for an unusable file.
  Future<PickedProof?> pick(ProofSource source);
}

class ImagePickerProofPicker implements ProofPicker {
  ImagePickerProofPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedProof?> pick(ProofSource source) async {
    // Shrunk on the device: a receipt stays readable at this size and the upload stays small.
    final file = await _picker.pickImage(
      source: source == ProofSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (file == null) return null;
    return checkProof(await file.readAsBytes());
  }
}
