import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:investflow/core/models/user_profile.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('profiles');

  Future<void> createOrUpdateProfile(UserProfile profile) async {
    await _collection.doc(profile.id).set(
      profile.toFirestore(),
    );
  }

  // Get user profile by ID
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final doc = await _collection.doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  // Get user profile stream in real-time
  Stream<UserProfile?> getProfileStream(String userId) {
    return _collection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user profile
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _collection.doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all investors
  Future<List<UserProfile>> getAllInvestors() async {
    final snapshot = await _collection
        .where('role', isEqualTo: 'investor')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UserProfile.fromFirestore(doc))
        .toList();
  }

  // Delete user profile
  Future<void> deleteProfile(String userId) async {
    await _collection.doc(userId).delete();
  }
}
