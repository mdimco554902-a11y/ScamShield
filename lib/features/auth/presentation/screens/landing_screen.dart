import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Modern dark background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- TOP NAVIGATION BAR ---
              _buildTopNavBar(context),

              // --- HERO SECTION ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent.withAlpha(100)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.security, color: AppColors.accentLight, size: 16),
                              SizedBox(width: 8),
                              Text(
                                "Next-Gen Phishing Protection",
                                style: TextStyle(
                                  color: AppColors.accentLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Main Title & Subtitle
                        const Text(
                          "Stop Scams Before\nThey Reach You.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "ScamShield uses AI visual recognition and link analysis to catch fraudulent text messages, fake bank pages, and malicious screenshots in real time.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Single Primary Action Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text(
                            "Get Started",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- LIVE STATS STRIP ---
              Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatTile(number: "99.4%", label: "Detection Accuracy"),
                        _StatTile(number: "< 2s", label: "Scan Speed"),
                        _StatTile(number: "24/7", label: "Live Protection"),
                      ],
                    ),
                  ),
                ),
              ),

              // --- FEATURES SECTION ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
                color: AppColors.background,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        const Text(
                          "Why Choose ScamShield?",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Comprehensive safety designed for everyday users.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                        const SizedBox(height: 40),

                        // Responsive Grid/List
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 700;

                            if (isWide) {
                              return const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _FeatureCard(
                                      icon: Icons.add_a_photo_outlined,
                                      title: "Screenshot Scanner",
                                      description:
                                          "Upload any text message or email screenshot. Our OCR AI extracts hidden links instantly.",
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _FeatureCard(
                                      icon: Icons.link_off_rounded,
                                      title: "URL Threat Inspector",
                                      description:
                                          "Paste unknown links to test them against real-time global security databases before clicking.",
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _FeatureCard(
                                      icon: Icons.verified_user_outlined,
                                      title: "Zero Data Logging",
                                      description:
                                          "Your privacy comes first. Scanned texts are evaluated safely without storing personal identities.",
                                    ),
                                  ),
                                ],
                              );
                            }

                            return const Column(
                              children: [
                                _FeatureCard(
                                  icon: Icons.add_a_photo_outlined,
                                  title: "Screenshot Scanner",
                                  description:
                                      "Upload any text message or email screenshot. Our OCR AI extracts hidden links instantly.",
                                ),
                                SizedBox(height: 16),
                                _FeatureCard(
                                  icon: Icons.link_off_rounded,
                                  title: "URL Threat Inspector",
                                  description:
                                      "Paste unknown links to test them against real-time global security databases before clicking.",
                                ),
                                SizedBox(height: 16),
                                _FeatureCard(
                                  icon: Icons.verified_user_outlined,
                                  title: "Zero Data Logging",
                                  description:
                                      "Your privacy comes first. Scanned texts are evaluated safely without storing personal identities.",
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar with Brand and Auth Navigation
  Widget _buildTopNavBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
      child: Row(
        children: [
          // Logo & App Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.accentLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "ScamShield",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Sign In Text Button
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              "Sign In",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Sign Up Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: const Text(
              "Sign Up",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for live statistics strip
class _StatTile extends StatelessWidget {
  final String number;
  final String label;

  const _StatTile({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.accentLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }
}

// Widget for feature cards
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}