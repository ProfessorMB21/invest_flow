import 'package:cloud_firestore/cloud_firestore.dart';

enum InvestmentStatus {pending, confirmed, rejected, refunded}

class Investment {
  final String id;
  final String projectId;
  final String investorId;
  final double amount;
  final InvestmentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paymentMethod;
  final String? transactionId;
  final String? notes;
  final Map<String, dynamic>? metadata;

  Investment({
    required this.id,
    required this.projectId,
    required this.investorId,
    required this.amount,
    this.status = InvestmentStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.transactionId,
    this.notes,
    this.metadata,
  });

  factory Investment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Investment(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      investorId: data['investorId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: InvestmentStatus.values.firstWhere(
            (e) => e.toString() == 'InvestmentStatus.${data['status']}',
        orElse: () => InvestmentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'],
      transactionId: data['transactionId'],
      notes: data['notes'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'investorId': investorId,
      'amount': amount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'notes': notes,
      'metadata': metadata,
    };
  }

  Investment copyWith({
    String? id,
    String? projectId,
    String? investorId,
    double? amount,
    InvestmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentMethod,
    String? transactionId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Investment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      investorId: investorId ?? this.investorId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }
}
