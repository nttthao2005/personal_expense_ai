import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);

    return image?.path;
  }

  Future<String?> captureFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera);

    return image?.path;
  }
}
