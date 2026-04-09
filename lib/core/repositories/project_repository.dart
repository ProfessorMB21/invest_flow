import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:investflow/core/models/project.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('projects');

  // Create project
  Future<String> createProject(Project project) async {
    final docRef = await _collection.add(project.toFirestore());
    return docRef.id;
  }

  // Get project by ID
  Future<Project?> getProject(String projectId) async {
    try {
      final doc = await _collection.doc(projectId).get();
      if (doc.exists) {
        return Project.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting project: $e');
      return null;
    }
  }

  // Get all projects stream
  Stream<List<Project>> getAllProjectsStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromFirestore(doc))
        .toList());
  }

  // Get projects by owner
  Stream<List<Project>> getProjectsByOwnerStream(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromFirestore(doc))
        .toList());
  }

  // Get active projects only
  Stream<List<Project>> getActiveProjectsStream() {
    return _collection
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromFirestore(doc))
        .toList());
  }

  // Get projects where user is investor
  Stream<List<Project>> getProjectsByInvestorStream(String investorId) {
    return _collection
        .where('investorIds', arrayContains: investorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList());
  }

  // Get active projects that user is invested in
  Stream<List<Project>> getActiveProjectsStreamForUser(String userId) {
    return _collection
        .where('investorIds', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList());
  }

  // Update project
  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    await _collection.doc(projectId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update raised amount
  Future<void> updateRaisedAmount(String projectId, double amount) async {
    await _collection.doc(projectId).update({
      'raisedAmount': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add investor to project
  Future<void> addInvestorToProject(String projectId, String investorId) async {
    await _collection.doc(projectId).update({
      'investorIds': FieldValue.arrayUnion([investorId]),
      'totalInvestors': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete project
  Future<void> deleteProject(String projectId) async {
    await _collection.doc(projectId).delete();
  }

  // Get project stats
Future<Map<String, dynamic>> getProjectStats(String projectId) async {
    final projectDoc = await _collection.doc(projectId).get();
    if (!projectDoc.exists) return {};

    final project = Project.fromFirestore(projectDoc);
    final investmentSnapshot = await _firestore
      .collection('investments')
      .where('projectId', isEqualTo: projectId)
      .where('status', isEqualTo: 'confirmed')
      .get();

    double totalInvested = 0;
    for (var doc in investmentSnapshot.docs) {
      final data = doc.data();
      totalInvested += (data['amount'] ?? 0).toDouble();
    }

    return {
      'raiseAmount': totalInvested,
      'investorCount': investmentSnapshot.docs.length,
      'progressPercent': project.goalAmount > 0
          ? (totalInvested / project.goalAmount * 100).clamp(0, 100)
          : 0,
    };
  }
}

