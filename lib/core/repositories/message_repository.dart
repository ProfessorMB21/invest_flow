import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:investflow/core/models/message.dart';

class MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('messages');

  // Send message
  Future<String> sendMessage(Message message) async {
    final docRef = await _collection.add(message.toFirestore());
    return docRef.id;
  }

  // Get messages by project
  Stream<List<Message>> getMessagesByProjectStream(String projectId) {
    return _collection
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .toList());
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _collection.doc(messageId).update({'isRead': true});
  }

  // Get unread count for project
  Future<int> getUnreadCount(String projectId, String userId) async {
    final snapshot = await _collection
        .where('projectId', isEqualTo: projectId)
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    await _collection.doc(messageId).delete();
  }
}
