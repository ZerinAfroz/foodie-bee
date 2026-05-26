import 'package:cloudinary_public/cloudinary_public.dart';
import '../config/cloudinary_config.dart';

class StorageService {
  static final _cloudinary = CloudinaryPublic(
    CloudinaryConfig.cloudName,
    CloudinaryConfig.uploadPreset,
  );

  static Future<String> uploadFoodImage(String filePath) async {
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        filePath,
        resourceType: CloudinaryResourceType.Image,
        folder: 'foodie_bee/food_listings',
      ),
    );
    return response.secureUrl;
  }
}
