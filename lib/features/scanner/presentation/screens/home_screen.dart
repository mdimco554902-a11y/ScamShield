import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../widgets/threat_result_dialog.dart';
import 'dashboard_view.dart';
import 'scanner_view.dart';
import 'history_view.dart';
import 'settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isAnalyzing = false;
  int _selectedIndex = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (route) => false,
      );
    });
  }

  void _runAnalysis([String? sampleInput]) async {
    final text = sampleInput ?? _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please paste a URL or text to analyze."),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    showDialog(
      context: context,
      builder: (context) => ThreatResultDialog(input: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (isDesktop) _buildSidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopHeader(showLogo: !isDesktop),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(28.0),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: _buildActiveView(isDesktop),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  backgroundColor: const Color(0xFF0F172A),
                  selectedItemColor: AppColors.accent,
                  unselectedItemColor: const Color(0xFF64748B),
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                    BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scanner'),
                    BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
                    BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildActiveView(bool isDesktop) {
    switch (_selectedIndex) {
      case 0:
        return DashboardView(
          isDesktop: isDesktop,
          textController: _textController,
          isAnalyzing: _isAnalyzing,
          onRunAnalysis: _runAnalysis,
          onViewAllHistory: () => setState(() => _selectedIndex = 2),
        );
      case 1:
        return ScannerView(
          textController: _textController,
          isAnalyzing: _isAnalyzing,
          onRunAnalysis: _runAnalysis,
        );
      case 2:
        return const HistoryView();
      case 3:
        return const SettingsView();
      default:
        return DashboardView(
          isDesktop: isDesktop,
          textController: _textController,
          isAnalyzing: _isAnalyzing,
          onRunAnalysis: _runAnalysis,
          onViewAllHistory: () => setState(() => _selectedIndex = 2),
        );
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  "ScamShield",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarNavItem(0, Icons.dashboard_rounded, "Dashboard"),
          _buildSidebarNavItem(1, Icons.qr_code_scanner_rounded, "Scanner"),
          _buildSidebarNavItem(2, Icons.history_rounded, "History"),
          _buildSidebarNavItem(3, Icons.settings_rounded, "Settings"),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 20),
              label: const Text("Sign Out", style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withAlpha(40) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? AppColors.accent : const Color(0xFF64748B), size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader({required bool showLogo}) {
    String headerTitle = "Security Dashboard Overview";
    if (_selectedIndex == 1) headerTitle = "Threat Scanner Workspace";
    if (_selectedIndex == 2) headerTitle = "Threat Activity History";
    if (_selectedIndex == 3) headerTitle = "Application Settings";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
      child: Row(
        children: [
          if (showLogo) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              "ScamShield Security",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ] else ...[
            Text(
              headerTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
          const Spacer(),
          if (showLogo)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
              onPressed: _handleLogout,
              tooltip: "Logout",
            ),
        ],
      ),
    );
  }
}