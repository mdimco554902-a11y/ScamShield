import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/scam_analysis_service.dart';

class ThreatResultDialog extends StatelessWidget {
  final ScamAnalysisResult result;

  const ThreatResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color primaryColor;
    switch (result.riskLevel.toUpperCase()) {
      case 'HIGH':
        primaryColor = Colors.redAccent;
        break;
      case 'MEDIUM':
        primaryColor = Colors.orangeAccent;
        break;
      default:
        primaryColor = const Color(0xFF10B981);
    }

    return AlertDialog(
      backgroundColor: theme.cardColor,
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
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.isScam ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                size: 48,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.isScam ? "${result.riskLevel} Risk Scam Detected" : "Content Appears Safe",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: result.isScam ? primaryColor : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Confidence: ${result.confidenceScore}% ${result.isScam ? 'Threat Likelihood' : 'Low Threat'}",
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.summary,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            if (result.flags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: result.flags.asMap().entries.map((entry) {
                    final index = entry.key;
                    final flag = entry.value;
                    return Column(
                      children: [
                        if (index > 0)
                          Divider(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        _buildSignalItem(
                          result.isScam ? Icons.report_problem_rounded : Icons.check_circle_outline_rounded,
                          flag,
                          isDark,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
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
                child: const Text(
                  "Done",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalItem(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}