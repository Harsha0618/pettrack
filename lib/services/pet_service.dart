// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:pettrack/models/pet_model.dart';
// import 'package:uuid/uuid.dart';

// class PetService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final CollectionReference _petsCollection = 
//       FirebaseFirestore.instance.collection('pets');

//   // Upload pet image to Firebase Storage
//   Future<String> uploadPetImage(File imageFile, String userId) async {
//     final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final Reference storageRef = _storage.ref().child('pet_images/$fileName');
    
//     final UploadTask uploadTask = storageRef.putFile(imageFile);
//     final TaskSnapshot taskSnapshot = await uploadTask;
    
//     final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
//     return downloadUrl;
//   }

//   // Add a new pet to Firestore
//   Future<String> addPet(PetModel pet, File imageFile) async {
//     try {
//       // Upload image first
//       final String imageUrl = await uploadPetImage(imageFile, pet.userId);
      
//       // Create pet with image URL
//       final petWithImage = PetModel(
//         name: pet.name,
//         breed: pet.breed,
//         color: pet.color,
//         location: pet.location,
//         imageUrl: imageUrl,
//         status: pet.status,
//         timestamp: pet.timestamp,
//         userId: pet.userId,
//         latitude: pet.latitude,
//         longitude: pet.longitude,
//         description: pet.description,
//         tags: pet.tags,
//       );
      
//       // Add to Firestore
//       final DocumentReference docRef = await _petsCollection.add(petWithImage.toMap());
//       return docRef.id;
//     } catch (e) {
//       print('Error adding pet: $e');
//       rethrow;
//     }
//   }

//   // Get all pets
//   Stream<List<PetModel>> getPets() {
//     return _petsCollection
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return PetModel.fromMap(
//           doc.data() as Map<String, dynamic>,
//           doc.id,
//         );
//       }).toList();
//     });
//   }

//   // Get pets by status (lost or found)
//   Stream<List<PetModel>> getPetsByStatus(String status) {
//     return _petsCollection
//         .where('status', isEqualTo: status)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return PetModel.fromMap(
//           doc.data() as Map<String, dynamic>,
//           doc.id,
//         );
//       }).toList();
//     });
//   }

//   // Get pets by user ID
//   Stream<List<PetModel>> getPetsByUserId(String userId) {
//     return _petsCollection
//         .where('userId', isEqualTo: userId)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return PetModel.fromMap(
//           doc.data() as Map<String, dynamic>,
//           doc.id,
//         );
//       }).toList();
//     });
//   }

//   // Get a single pet by ID
//   Future<PetModel?> getPetById(String petId) async {
//     try {
//       final DocumentSnapshot doc = await _petsCollection.doc(petId).get();
//       if (doc.exists) {
//         return PetModel.fromMap(
//           doc.data() as Map<String, dynamic>,
//           doc.id,
//         );
//       }
//       return null;
//     } catch (e) {
//       print('Error getting pet: $e');
//       return null;
//     }
//   }

//   // Update a pet
//   Future<void> updatePet(String petId, Map<String, dynamic> data) async {
//     try {
//       await _petsCollection.doc(petId).update(data);
//     } catch (e) {
//       print('Error updating pet: $e');
//       rethrow;
//     }
//   }

//   // Delete a pet
//   Future<void> deletePet(String petId, String imageUrl) async {
//     try {
//       // Delete image from storage if it exists
//       if (imageUrl.isNotEmpty) {
//         try {
//           final Reference ref = _storage.refFromURL(imageUrl);
//           await ref.delete();
//         } catch (e) {
//           print('Error deleting image: $e');
//           // Continue with pet deletion even if image deletion fails
//         }
//       }
      
//       // Delete pet document
//       await _petsCollection.doc(petId).delete();
//     } catch (e) {
//       print('Error deleting pet: $e');
//       rethrow;
//     }
//   }
// }

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pettrack/models/pet_model.dart';
import 'package:pettrack/services/cloudinary_service.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Add a new pet
  Future<void> addPet(PetModel pet, File imageFile) async {
    try {
      // Upload image to Cloudinary
      String imageUrl = await _cloudinaryService.uploadImage(imageFile);
      
      // Create pet with image URL
      PetModel petWithImage = PetModel(
        name: pet.name,
        breed: pet.breed,
        color: pet.color,
        location: pet.location,
        imageUrl: imageUrl,
        status: pet.status,
        timestamp: pet.timestamp,
        userId: pet.userId,
        latitude: pet.latitude,
        longitude: pet.longitude,
        description: pet.description,
      );
      
      // Add to Firestore
      await _firestore.collection('pets').add(petWithImage.toMap());
    } catch (e) {
      print('Error in addPet: $e');
      rethrow;
    }
  }

  // Delete pet (only removes from Firestore, image stays in Cloudinary)
  Future<void> deletePet(String petId, String imageUrl) async {
    try {
      // Delete from Firestore
      await _firestore.collection('pets').doc(petId).delete();
      
      // Note: Image will remain in Cloudinary
      // For production, you might want to:
      // 1. Keep a list of "deleted" images for manual cleanup
      // 2. Implement server-side deletion
      // 3. Use Cloudinary's auto-delete features
      
      if (imageUrl.isNotEmpty) {
        String publicId = _cloudinaryService.extractPublicIdFromUrl(imageUrl);
        print('Pet deleted. Image public ID for manual cleanup: $publicId');
      }
      
    } catch (e) {
      print('Error deleting pet: $e');
      rethrow;
    }
  }

  // ... rest of your existing methods remain the same
  
  Stream<List<PetModel>> getPetsByStatus(String status) {
    return _firestore
        .collection('pets')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          List<PetModel> pets = snapshot.docs
              .map((doc) => PetModel.fromMap(doc.data(), doc.id))
              .toList();
          
          pets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return pets;
        });
  }

  Future<PetModel?> getPetById(String petId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('pets').doc(petId).get();
      if (doc.exists) {
        return PetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting pet by ID: $e');
      rethrow;
    }
  }

  Stream<List<PetModel>> getUserPets(String userId) {
    return _firestore
        .collection('pets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          List<PetModel> pets = snapshot.docs
              .map((doc) => PetModel.fromMap(doc.data(), doc.id))
              .toList();
          
          pets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return pets;
        });
  }

  Stream<List<PetModel>> getAllPets() {
    return _firestore
        .collection('pets')
        .snapshots()
        .map((snapshot) {
          List<PetModel> pets = snapshot.docs
              .map((doc) => PetModel.fromMap(doc.data(), doc.id))
              .toList();
          
          pets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return pets;
        });
  }
    // <--- Add it here! --->
  Future<List<PetModel>> getAllPetsOnce() async {
    final snapshot = await _firestore.collection('pets').get();
    return snapshot.docs
        .map((doc) => PetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}