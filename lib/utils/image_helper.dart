import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class ImageHelper {
  /// Converts an image file to a base64 string so it can be stored directly
  /// in Firestore, allowing it to sync across all devices easily.
  static Future<String?> imageToBase64(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    // If it's already a base64 string or a network URL, just return it
    if (imagePath.startsWith('data:image') || imagePath.startsWith('http')) {
      return imagePath;
    }

    final file = File(imagePath);
    if (!await file.exists()) return imagePath;

    try {
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Str';
    } catch (e) {
      return imagePath;
    }
  }

  /// Returns the appropriate ImageProvider (Memory, Network, or File)
  /// based on the imageUrl string format.
  static ImageProvider? getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    if (imageUrl.startsWith('data:image')) {
      final base64Str = imageUrl.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    } else if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      return FileImage(File(imageUrl));
    }
  }
}
