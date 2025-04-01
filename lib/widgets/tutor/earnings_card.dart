// lib/widgets/tutor/earning_card.dart
import 'package:flutter/material.dart';

class EarningsCard extends StatelessWidget {
  final double totalEarnings;
  final double availableForWithdrawal;

  const EarningsCard({super.key, 
    required this.totalEarnings,
    required this.availableForWithdrawal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Total Earnings: ₱${totalEarnings.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18)),
            Text('Available for Withdrawal: ₱${availableForWithdrawal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle withdraw
              },
              child: Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }
}