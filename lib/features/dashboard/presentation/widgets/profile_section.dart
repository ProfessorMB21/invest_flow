// Flutter Imports
import 'package:flutter/material.dart';
import 'package:investflow/core/models/user_profile.dart';
import 'package:investflow/core/utils/app_colors.dart';

class ProfileSection extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onEditProfile;

  const ProfileSection({
    super.key,
    required this.user,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isNotEmpty
                            ? user.fullName
                            : 'Loading...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.email.isNotEmpty
                            ? user.email
                            : 'No email available',
                            style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          user.role.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: onEditProfile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
