// Flutter Imports
import 'package:flutter/material.dart';
import 'package:investflow/core/utils/app_colors.dart';

class FundBalanceCard extends StatelessWidget {
  final double balance;
  final bool isLoading;

  const FundBalanceCard({
    super.key,
    required this.balance,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              Colors.blue[900]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Fund Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.attach_money,
                  color: Colors.white70,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isLoading
                  ? 'Loading...'
                  : '\$${balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            if (!isLoading && balance == 0) ...[
              const SizedBox(height: 4),
              Text(
                'Balance will update when you create projects or make investments',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
