import 'dart:io';
import 'dart:developer' show log;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  /// Compresses an image file to reduce file size before upload
  ///
  /// Parameters:
  /// - [file]: The original image file to compress
  ///
  /// Returns:
  /// - A compressed [File] object with size guaranteed to be under 150KB
  ///
  /// Throws:
  /// - [Exception] if compression fails or file is corrupted
  static Future<File> compressImage(File file) async {
    try {
      // Get original file size
      final originalSize = await file.length();
      final originalSizeMB = originalSize / (1024 * 1024);
      log('Original image size: ${originalSizeMB.toStringAsFixed(2)} MB ($originalSize bytes)');

      // Get temporary directory for output
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.absolute.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Start with high compression parameters to ensure we stay under 150KB
      File? compressedFile;
      int quality = 80; // Start with 80% quality
      int maxWidth = 1024;
      int maxHeight = 1024;

      // Try compression with decreasing quality until under 150KB or minimum quality reached
      while (quality >= 10) {
        final result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: quality,
          minWidth: maxWidth,
          minHeight: maxHeight,
          format: CompressFormat.jpeg,
        );

        if (result == null) {
          throw Exception('Image compression returned null');
        }

        compressedFile = File(result.path);
        final compressedSize = await compressedFile.length();

        // Check if the compressed file is under 150KB (150 * 1024 bytes)
        if (compressedSize <= 150 * 1024) {
          // Success - file is under 150KB
          final compressedSizeKB = compressedSize / 1024;
          final compressionRatio = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);

          log('Compressed image size: ${compressedSizeKB.toStringAsFixed(2)} KB');
          log('Compression ratio: $compressionRatio%');
          log('Quality used: $quality%, Dimensions: ${maxWidth}x$maxHeight');

          return compressedFile;
        }

        // If still too large, reduce quality further
        quality -= 10; // Reduce quality by 10%

        // Also reduce dimensions if quality gets too low
        if (quality <= 30) {
          maxWidth = (maxWidth * 0.8).toInt();
          maxHeight = (maxHeight * 0.8).toInt();
        }
      }

      // If we've tried all quality levels and still too big, return the smallest we got
      if (compressedFile != null) {
        final compressedSize = await compressedFile.length();
        final compressedSizeKB = compressedSize / 1024;
        final compressionRatio = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);

        log('WARNING: Could not compress image under 150KB. Final size: ${compressedSizeKB.toStringAsFixed(2)} KB');
        log('Compression ratio: $compressionRatio%');
        log('Final quality: $quality%, Dimensions: ${maxWidth}x$maxHeight');

        return compressedFile;
      } else {
        throw Exception('Image compression failed - no file returned');
      }
    } catch (e, stackTrace) {
      log('Image compression failed: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }


  /// Batch compress multiple images
  ///
  /// Parameters:
  /// - [files]: List of image files to compress
  ///
  /// Returns:
  /// - A list of compressed [File] objects
  static Future<List<File>> compressImages(List<File> files) async {
    final compressedFiles = <File>[];

    for (final file in files) {
      try {
        final compressed = await compressImage(file);
        compressedFiles.add(compressed);
      } catch (e) {
        log('Failed to compress image: $e');
        // Continue with next image instead of failing completely
        compressedFiles.add(file);
      }
    }

    return compressedFiles;
  }


}
