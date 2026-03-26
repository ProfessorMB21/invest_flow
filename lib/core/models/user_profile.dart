import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {admin, investor}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool isVerified;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = UserRole.investor,
    required this.createdAt,
    this.updatedAt,
    this.phoneNumber,
    this.profileImageUrl,
    this.isVerified = false,
    this.metadata,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.investor,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      isVerified: data['isVerified'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'metadata': metadata,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isVerified,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      metadata: metadata ?? this.metadata,
    );
  }
}
