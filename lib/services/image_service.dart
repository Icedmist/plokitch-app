import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Picks up to [maxImages] from the gallery.
  static Future<List<XFile>> pickImages({int maxImages = 4}) async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (images.length > maxImages) {
      return images.sublist(0, maxImages);
    }
    return images;
  }

  /// Compresses an image and returns the bytes.
  static Future<Uint8List> compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    
    if (image == null) throw Exception('Failed to decode image');

    // Resize the image to a maximum width of 1024px while maintaining aspect ratio
    if (image.width > 1024) {
      image = img.copyResize(image, width: 1024);
    }

    // Encode to JPG with 80% quality
    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  }

  /// Uploads compressed image bytes to Supabase Storage and returns the public URL.
  static Future<String> uploadImage(Uint8List bytes, String bucket, String folder) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = '$folder/$fileName';

    await _supabase.storage.from(bucket).uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    final String publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);
    return publicUrl;
  }
}
