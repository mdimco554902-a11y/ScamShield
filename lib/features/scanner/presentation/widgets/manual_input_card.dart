import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scam_shield/features/scanner/data/scam_analysis_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/scan_tracker_service.dart';

class ManualInputCard extends StatefulWidget {
  const ManualInputCard({super.key});

  @override
  State<ManualInputCard> createState() => _ManualInputCardState();
}

class _ManualInputCardState extends State<ManualInputCard> {
  final TextEditingController _controller = TextEditingController();
  final ScamAnalysisService _analysisService = ScamAnalysisService();

  bool _isAnalyzing = false;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _controller.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_analysisService.remainingCooldownSeconds <= 0) {
        timer.cancel();
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _analyzeText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste text to analyze.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isAnalyzing = true);

    try {
      final result = await _analysisService.analyzeText(text);

      final displayTitle = text.length > 32 ? '${text.substring(0, 32)}...' : text;
      final threatLabel = '${result.riskLevel} Risk • ${result.confidenceScore}%';

      // Pass description, indicators, and original text to Firestore scan record
      ScanTrackerService.instance.recordNewScan(
        title: displayTitle,
        isScam: result.isScam,
        threatType: threatLabel,
        description: result.summary,
        indicators: result.flags,
        scannedText: text, // <-- Pass full original text here
      );

      _controller.clear();

      if (!mounted) return;
      _showResultDialog(result);
    } catch (e) {
      final cleanError = e.toString().replaceAll('Exception: ', '');

      if (_analysisService.remainingCooldownSeconds > 0) {
        _startCooldownTicker();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanError),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showResultDialog(ScamAnalysisResult result) {
    Color riskColor;
    switch (result.riskLevel.toUpperCase()) {
      case 'HIGH':
        riskColor = Colors.redAccent;
        break;
      case 'MEDIUM':
        riskColor = Colors.orangeAccent;
        break;
      default:
        riskColor = Colors.green;
        break;
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
              result.isScam ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: riskColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.isScam ? 'Scam Detected' : 'Appears Safe',
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
                  'Risk: ${result.riskLevel} (${result.confidenceScore}% confidence)',
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
                            style: const TextStyle(color: Color(0xFF94A3B8)),
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
    final cooldownSecs = _analysisService.remainingCooldownSeconds;
    final bool isButtonDisabled = _isAnalyzing || cooldownSecs > 0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Manual Threat Inspection",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Paste suspicious URL, SMS text, or email body...",
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isButtonDisabled ? null : _analyzeText,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: const Color(0xFF334155),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      cooldownSecs > 0
                          ? "Wait ${cooldownSecs}s"
                          : "Analyze Text & Links",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}