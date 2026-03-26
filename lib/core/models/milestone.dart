import 'package:cloud_firestore/cloud_firestore.dart';

class Milestone {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? proofUrl;
  final Map<String, dynamic>? metadata;

  Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    required this.deadline,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
    this.proofUrl,
    this.metadata,
  });

  factory Milestone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Milestone(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      proofUrl: data['proofUrl'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'proofUrl': proofUrl,
      'metadata': metadata,
    };
  }

  bool get isOverdue {
    return !isCompleted && deadline.isBefore(DateTime.now());
  }

  int get daysRemaining {
    return deadline.difference(DateTime.now()).inDays;
  }

  Milestone copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? proofUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Milestone(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      proofUrl: proofUrl ?? this.proofUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
