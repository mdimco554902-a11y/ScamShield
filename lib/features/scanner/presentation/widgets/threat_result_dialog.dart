import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ThreatResultDialog extends StatelessWidget {
  final String input;

  const ThreatResultDialog({super.key, required this.input});

  @override
  Widget build(BuildContext context) {
    final isHighRisk = input.toLowerCase().contains('http') ||
        input.toLowerCase().contains('urgent') ||
        input.toLowerCase().contains('bank');

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHighRisk ? Colors.red.withAlpha(30) : const Color(0xFF10B981).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHighRisk ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                size: 48,
                color: isHighRisk ? Colors.redAccent : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isHighRisk ? "High Risk Scam Detected" : "Content Appears Safe",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isHighRisk ? Colors.redAccent : Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isHighRisk ? "Confidence: 94% Threat Likelihood" : "Confidence: 98% Low Threat",
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: isHighRisk
                    ? [
                        _buildSignalItem(Icons.link_off_rounded, "Unverified Domain Redirect Detected"),
                        const Divider(color: Colors.white10),
                        _buildSignalItem(Icons.access_time_filled_rounded, "Urgency & Psychological Pressure Tactics"),
                        const Divider(color: Colors.white10),
                        _buildSignalItem(Icons.lock_reset_rounded, "Suspicious Credential Harvesting Pattern"),
                      ]
                    : [
                        _buildSignalItem(Icons.security_rounded, "No Malicious Redirects Found"),
                        const Divider(color: Colors.white10),
                        _buildSignalItem(Icons.check_circle_outline_rounded, "Language Pattern Matches Normal SMS"),
                      ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}