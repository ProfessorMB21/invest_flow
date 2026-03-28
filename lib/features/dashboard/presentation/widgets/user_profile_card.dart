import 'package:flutter/material.dart';
import 'package:investflow/core/models/user_profile.dart';

class UserProfileCard extends StatelessWidget {
  final UserProfile? userProfile;
  final VoidCallback? onEdit;

  const UserProfileCard({
    super.key,
    this.userProfile,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: userProfile?.profileImageUrl != null
                  ? ClipOval(
                child: Image.network(
                  userProfile!.profileImageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30),
                ),
              )
                  : const Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProfile?.fullName ?? 'Loading...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(userProfile?.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          userProfile?.role.name.toUpperCase() ?? 'INVESTOR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getRoleColor(userProfile?.role),
                          ),
                        ),
                      ),
                      if (userProfile?.isVerified == true) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Edit Button
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                tooltip: 'Edit Profile',
              ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.investor:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
