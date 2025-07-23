import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static const String _cloudName = 'drd7v274z'; // Your cloud name
  static const String _uploadPreset = 'pettrack_preset'; // Your upload preset
  
  final CloudinaryPublic _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset);

  Future<String> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'pettrack', // Optional: organize images in folders
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Note: Unsigned uploads cannot delete images directly
  // You would need to implement server-side deletion or use signed uploads
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Fned uploads, we cannot delete images directly from the client
      // This is a security feature of Cloudinary
      print('Image deletion not supported with unsigned uploads: $imageUrl');
      
      // Options for deletion:
      // 1. Implement server-side deletion using your backend
      // 2. Use Cloudinary's auto-delete features
      // 3. Manually delete from Cloudinary dashboard
      // 4. Set up auto-deletion policies in Cloudinary
      
    } catch (e) {
      print('Error with image deletion: $e');
      // Don't throw error for deletion failures
    }
  }

  // Helper method to extract public ID (useful for future server-side deletion)
  String extractPublicIdFromUrl(String url) {
    // Extract public ID from Cloudinary URL
    // Example URL: https://res.cloudinary.com/demo/image/upload/v1234567890/pettrack/sample.jpg
    // Public ID would be: pettrack/sample
    
    try {
      Uri uri = Uri.parse(url);
      List<String> pathSegments = uri.pathSegments;
      
      // Find the upload segment and get everything after it
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
        // Skip version if present (starts with 'v' followed by numbers)
        int startIndex = uploadIndex + 1;
        if (pathSegments[startIndex].startsWith('v') && 
            pathSegments[startIndex].length > 1 &&
            int.tryParse(pathSegments[startIndex].substring(1)) != null) {
          startIndex++;
        }
        
        // Join remaining segments and remove file extension
        String publicId = pathSegments.sublist(startIndex).join('/');
        return publicId.split('.').first;
      }
    } catch (e) {
      print('Error extracting public ID: $e');
    }
    
    return '';
  }
}