import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class UploadButton extends StatelessWidget {
  final VoidCallback onSelectScreenshot;

  const UploadButton({
    super.key,
    required this.onSelectScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              size: 44,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Drop Screenshot or Click to Upload",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Supports PNG, JPG, or WebP (e.g. Banking SMS, Email screenshots)",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onSelectScreenshot,
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: const Text("Select Screenshot"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}