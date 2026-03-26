import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:investflow/core/models/milestone.dart';

class MilestoneRepository {
  final FirebaseFirestore _firestore;

  MilestoneRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('milestones');

  // Create milestone
  Future<String> createMilestone(Milestone milestone) async {
    final docRef = await _collection.add(milestone.toFirestore());
    return docRef.id;
  }

  // Get milestones by project
  Stream<List<Milestone>> getMilestonesByProjectStream(String projectId) {
    return _collection
        .where('projectId', isEqualTo: projectId)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Milestone.fromFirestore(doc))
        .toList());
  }

  // Update milestone
  Future<void> updateMilestone(String milestoneId, Map<String, dynamic> data) async {
    await _collection.doc(milestoneId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Complete milestone
  Future<void> completeMilestone(String milestoneId, String proofUrl) async {
    await _collection.doc(milestoneId).update({
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
      'proofUrl': proofUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete milestone
  Future<void> deleteMilestone(String milestoneId) async {
    await _collection.doc(milestoneId).delete();
  }

  // Get overdue milestones
  Future<List<Milestone>> getOverdueMilestones(String projectId) async {
    final now = Timestamp.now();
    final snapshot = await _collection
        .where('projectId', isEqualTo: projectId)
        .where('isCompleted', isEqualTo: false)
        .where('deadline', isLessThan: now)
        .get();

    return snapshot.docs
        .map((doc) => Milestone.fromFirestore(doc))
        .toList();
  }
}
