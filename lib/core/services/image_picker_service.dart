import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      return image?.path;
    } catch (_) {
      return null;
    }
  }
}

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});
