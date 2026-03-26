

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String projectId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? messageType; // text, file, announcement
  final String? fileUrl;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.messageType = 'text',
    this.fileUrl,
    this.metadata,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      messageType: data['messageType'] ?? 'text',
      fileUrl: data['fileUrl'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'senderId': senderId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'messageType': messageType,
      'fileUrl': fileUrl,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    String? messageType,
    String? fileUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}