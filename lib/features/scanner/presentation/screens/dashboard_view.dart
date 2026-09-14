import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/status_banner.dart';
import '../widgets/upload_button.dart';
import '../widgets/manual_input_card.dart';
import '../widgets/recent_activity_tile.dart';

class DashboardView extends StatelessWidget {
  final bool isDesktop;
  final TextEditingController textController;
  final bool isAnalyzing;
  final Function(String?) onRunAnalysis;
  final VoidCallback onViewAllHistory;

  const DashboardView({
    super.key,
    required this.isDesktop,
    required this.textController,
    required this.isAnalyzing,
    required this.onRunAnalysis,
    required this.onViewAllHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Overview Section
            const StatusBanner(),
            const SizedBox(height: 20),
            _buildMetricsOverview(),
            const SizedBox(height: 24),
            _buildRecentActivityHeader(),
            const SizedBox(height: 8),
            _buildActivityTiles(),

            // Bottom Section: Scanner Inputs
            const SizedBox(height: 28),
            const Text(
              "Quick Threat Scanner",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            UploadButton(
              onSelectScreenshot: () => onRunAnalysis("http://secure-banking-verify-login.com"),
            ),
            const SizedBox(height: 20),
            ManualInputCard(
              controller: textController,
              isAnalyzing: isAnalyzing,
              onAnalyze: () => onRunAnalysis(null),
            ),
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
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UploadButton(
                onSelectScreenshot: () => onRunAnalysis("http://secure-banking-verify-login.com"),
              ),
              const SizedBox(height: 24),
              ManualInputCard(
                controller: textController,
                isAnalyzing: isAnalyzing,
                onAnalyze: () => onRunAnalysis(null),
              ),
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
              _buildMetricsOverview(),
              const SizedBox(height: 24),
              _buildRecentActivityHeader(),
              const SizedBox(height: 8),
              _buildActivityTiles(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Recent Activity Logs",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        TextButton(
          onPressed: onViewAllHistory,
          child: const Text("View All", style: TextStyle(color: AppColors.accent)),
        ),
      ],
    );
  }

  Widget _buildActivityTiles() {
    return const Column(
      children: [
        RecentActivityTile(
          title: "Bank Security Verification SMS",
          status: "High Risk • 94%",
          statusColor: Colors.redAccent,
          icon: Icons.gpp_bad_rounded,
        ),
        RecentActivityTile(
          title: "Package Delivery Tracking Link",
          status: "Safe • 99%",
          statusColor: Color(0xFF10B981),
          icon: Icons.verified_user_rounded,
        ),
      ],
    );
  }

  Widget _buildMetricsOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile("Scans Run", "128", Icons.radar_rounded, AppColors.accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile("Threats Blocked", "5", Icons.gpp_bad_rounded, Colors.redAccent),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color accentColor) {
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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