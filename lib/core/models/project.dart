import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus {active, completed, cancelled, paused}

class Project {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double goalAmount;
  final double raisedAmount;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deadline;
  final String category;
  final List<String> investorIds;
  final int totalInvestors;
  final Map<String, dynamic>? metadata;

  Project({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.goalAmount,
    this.raisedAmount = 0,
    this.status = ProjectStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.deadline,
    this.category = 'General',
    this.investorIds = const [],
    this.totalInvestors = 0,
    this.metadata,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      goalAmount: (data['goalAmount'] ?? 0).toDouble(),
      raisedAmount: (data['raisedAmount'] ?? 0).toDouble(),
      status: ProjectStatus.values.firstWhere(
            (e) => e.toString() == 'ProjectStatus.${data['status']}',
        orElse: () => ProjectStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      deadline: data['deadline'] != null
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      category: data['category'] ?? 'General',
      investorIds: List<String>.from(data['investorIds'] ?? []),
      totalInvestors: data['totalInvestors'] ?? 0,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'goalAmount': goalAmount,
      'raisedAmount': raisedAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'category': category,
      'investorIds': investorIds,
      'totalInvestors': totalInvestors,
      'metadata': metadata,
    };
  }

  double get progressPercentage {
    if (goalAmount == 0) return 0;
    return (raisedAmount / goalAmount) * 100;
  }

  Project copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    double? goalAmount,
    double? raisedAmount,
    ProjectStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadline,
    String? category,
    List<String>? investorIds,
    int? totalInvestors,
    Map<String, dynamic>? metadata,
  }) {
    return Project(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      goalAmount: goalAmount ?? this.goalAmount,
      raisedAmount: raisedAmount ?? this.raisedAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      investorIds: investorIds ?? this.investorIds,
      totalInvestors: totalInvestors ?? this.totalInvestors,
      metadata: metadata ?? this.metadata,
    );
  }
}
