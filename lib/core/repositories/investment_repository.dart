import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:investflow/core/models/investment.dart';

class InvestmentRepository {
  final FirebaseFirestore _firestore;

  InvestmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('investments');

  // Create investment
  Future<String> createInvestment(Investment investment) async {
    final docRef = await _collection.add(investment.toFirestore());
    return docRef.id;
  }

  // Get investment by ID
  Future<Investment?> getInvestment(String investmentId) async {
    try {
      final doc = await _collection.doc(investmentId).get();
      if (doc.exists) {
        return Investment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting investment: $e');
      return null;
    }
  }

  // Get investments by project
  Stream<List<Investment>> getInvestmentsByProjectStream(String projectId) {
    return _collection
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Investment.fromFirestore(doc))
        .toList());
  }

  // Get investments by investor
  Stream<List<Investment>> getInvestmentsByInvestorStream(String investorId) {
    return _collection
        .where('investorId', isEqualTo: investorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Investment.fromFirestore(doc))
        .toList());
  }

  // Get total invested by investor in project
  Future<double> getTotalInvested(String projectId, String investorId) async {
    final snapshot = await _collection
        .where('projectId', isEqualTo: projectId)
        .where('investorId', isEqualTo: investorId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0).toDouble();
    }
    return total;
  }

  // Update investment status
  Future<void> updateInvestmentStatus(String investmentId, InvestmentStatus status) async {
    await _collection.doc(investmentId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete investment
  Future<void> deleteInvestment(String investmentId) async {
    await _collection.doc(investmentId).delete();
  }
}
