import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/scan_tracker_service.dart';
import '../widgets/status_banner.dart';
import '../widgets/upload_button.dart';
import '../widgets/manual_input_card.dart';
import '../widgets/recent_activity_tile.dart';

class DashboardView extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onViewAllHistory;

  const DashboardView({
    super.key,
    required this.isDesktop,
    required this.onViewAllHistory,
  });

  /// Extracts percentage value from saved threat strings (e.g. "Medium Risk • 78%")
  int? _extractScore(String threatType) {
    final RegExp regExp = RegExp(r'(\d+)%');
    final match = regExp.firstMatch(threatType);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Calculates visual color based on percentage thresholds
  Color _getRiskColor(bool isScam, String threatType) {
    final score = _extractScore(threatType);
    if (score != null) {
      if (score >= 80) return Colors.redAccent;
      if (score >= 40) return Colors.orangeAccent;
      return AppColors.safe;
    }

    final upperType = threatType.toUpperCase();
    if (!isScam) return AppColors.safe;
    if (upperType.contains('MEDIUM')) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  /// Calculates status string dynamically according to score thresholds
  String _getStatusText(bool isScam, String threatType) {
    final score = _extractScore(threatType);
    if (score != null) {
      if (score >= 80) return "High Risk • Blocked";
      if (score >= 40) return "Medium Risk • Warning";
      return "Safe • Clean";
    }

    final upperType = threatType.toUpperCase();
    if (!isScam) return "Safe • Clean";
    if (upperType.contains('MEDIUM')) return "Medium Risk • Warning";
    return "High Risk • Blocked";
  }

  /// Resolves icon according to threat severity
  IconData _getIcon(bool isScam, String threatType) {
    final score = _extractScore(threatType);
    if (score != null) {
      if (score >= 80) return Icons.gpp_bad_rounded;
      if (score >= 40) return Icons.warning_amber_rounded;
      return Icons.verified_user_rounded;
    }

    if (!isScam) return Icons.verified_user_rounded;
    if (threatType.toUpperCase().contains('MEDIUM')) return Icons.warning_amber_rounded;
    return Icons.gpp_bad_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ScanTrackerService.instance,
      builder: (context, _) {
        final tracker = ScanTrackerService.instance;

        if (!isDesktop) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StatusBanner(),
                const SizedBox(height: 20),
                _buildMetricsOverview(tracker),
                const SizedBox(height: 24),
                _buildRecentActivityHeader(),
                const SizedBox(height: 8),
                _buildActivityTiles(tracker),
                const SizedBox(height: 28),
                const Text(
                  "Quick Threat Scanner",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const UploadButton(),
                const SizedBox(height: 20),
                const ManualInputCard(),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        // Desktop Layout (2-Column Grid)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary Actions (Left Column)
            const Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UploadButton(),
                  SizedBox(height: 24),
                  ManualInputCard(),
                ],
              ),
            ),
            const SizedBox(width: 28),

            // System Insights & Logs (Right Column)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StatusBanner(),
                  const SizedBox(height: 20),
                  _buildMetricsOverview(tracker),
                  const SizedBox(height: 24),
                  _buildRecentActivityHeader(),
                  const SizedBox(height: 8),
                  _buildActivityTiles(tracker),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Recent Activity Logs",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextButton(
          onPressed: onViewAllHistory,
          child: const Text("View All", style: TextStyle(color: AppColors.accent)),
        ),
      ],
    );
  }

  Widget _buildActivityTiles(ScanTrackerService tracker) {
    final recentScans = tracker.recentScans;

    if (recentScans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Text(
            "No scan activity recorded yet.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: recentScans.take(3).map((scan) {
        return RecentActivityTile(
          title: scan.title,
          status: _getStatusText(scan.isScam, scan.threatType),
          statusColor: _getRiskColor(scan.isScam, scan.threatType),
          icon: _getIcon(scan.isScam, scan.threatType),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsOverview(ScanTrackerService tracker) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            "Scans Run",
            "${tracker.totalScans}",
            Icons.radar_rounded,
            AppColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            "Threats Blocked",
            "${tracker.scamsBlocked}",
            Icons.gpp_bad_rounded,
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 26),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}