import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/scam_analysis_service.dart';
import '../../data/scan_tracker_service.dart';

class UploadButton extends StatefulWidget {
  const UploadButton({super.key});

  @override
  State<UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<UploadButton> {
  final ScamAnalysisService _analysisService = ScamAnalysisService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  String _calculateRiskLevel(int score) {
    if (score >= 80) return 'High Risk';
    if (score >= 40) return 'Medium Risk';
    return 'Safe';
  }

  Future<void> _pickAndAnalyzeScreenshot() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isLoading = true);

    try {
      final Uint8List imageBytes = await file.readAsBytes();
      final String mimeType = file.mimeType ?? 'image/png';

      final result = await _analysisService.analyzeImage(imageBytes, mimeType);

      final fileName = file.name.isNotEmpty ? file.name : 'Screenshot';
      final displayTitle = 'Image Scan: $fileName';
      
      // Range-based risk categorization
      final riskLevelLabel = _calculateRiskLevel(result.confidenceScore);
      final threatLabel = '$riskLevelLabel • ${result.confidenceScore}%';

      unawaited(
        ScanTrackerService.instance.recordNewScan(
          title: displayTitle,
          isScam: result.confidenceScore >= 40,
          threatType: threatLabel,
          description: result.summary,
          indicators: result.flags,
          ocrText: result.scannedText.isNotEmpty ? result.scannedText : result.summary,
        ).catchError((e) {
          debugPrint('Error writing scan record to Firestore: $e');
        }),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showResultDialog(ScamAnalysisResult result) {
    final score = result.confidenceScore;
    Color riskColor;
    String riskText;

    if (score >= 80) {
      riskColor = Colors.redAccent;
      riskText = 'High';
    } else if (score >= 40) {
      riskColor = Colors.orangeAccent;
      riskText = 'Medium';
    } else {
      riskColor = Colors.green;
      riskText = 'Low';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: Row(
          children: [
            Icon(
              score >= 40 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: riskColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                score >= 40 ? 'Scam Detected' : 'Appears Safe',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Risk: $riskText ($score% confidence)',
                  style: TextStyle(color: riskColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.summary,
                style: const TextStyle(color: Colors.white),
              ),
              if (result.flags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Detected Indicators:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...result.flags.map(
                  (flag) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right, size: 18, color: Colors.redAccent),
                        Expanded(
                          child: Text(
                            flag,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.accentLight)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF334155),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
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
          Text(
            "Supports PNG, JPG, or WebP (e.g. Banking SMS, Email screenshots)",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickAndAnalyzeScreenshot,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_photo_alternate_rounded),
            label: Text(_isLoading ? "Analyzing..." : "Select Screenshot"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.6),
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