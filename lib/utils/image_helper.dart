import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  /// Copies a temporary image file picked by ImagePicker into permanent app storage
  /// so that Android / iOS operating systems do not clean it up from temporary cache.
  static Future<String?> saveImagePermanently(String? tempPath, String petId) async {
    if (tempPath == null || tempPath.isEmpty) return null;

    final tempFile = File(tempPath);
    if (!await tempFile.exists()) return tempPath;

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory petPhotosDir = Directory('${appDocDir.path}/pet_photos');

      if (!await petPhotosDir.exists()) {
        await petPhotosDir.create(recursive: true);
      }

      final String fileName = 'pet_${petId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String permanentPath = '${petPhotosDir.path}/$fileName';

      final File permanentFile = await tempFile.copy(permanentPath);
      return permanentFile.path;
    } catch (e) {
      // Fallback to original path if copy fails
      return tempPath;
    }
  }
}
