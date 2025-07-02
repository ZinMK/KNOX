import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RateCards extends StatelessWidget {
  final double successRate;
  final double leadRate;
  final String view; // 'today' or 'monthly'

  const RateCards({
    required this.successRate,
    required this.leadRate,
    required this.view,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildRateCard(
          context,
          label: 'sale rate',
          value: '${successRate.toStringAsFixed(1)}%',
          color: Colors.green,
          icon: Icons.check_circle,
        ),
        _buildRateCard(
          context,
          label: "lead rate",
          value: '${leadRate.toStringAsFixed(1)}%',
          color: Colors.blue,
          icon: Icons.leaderboard,
        ),
      ],
    );
  }

  Widget _buildRateCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
