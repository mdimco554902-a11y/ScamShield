import 'package:flutter/material.dart';
import '../widgets/upload_button.dart';
import '../widgets/manual_input_card.dart';

class ScannerView extends StatelessWidget {
  final TextEditingController textController;
  final bool isAnalyzing;
  final Function(String?) onRunAnalysis;

  const ScannerView({
    super.key,
    required this.textController,
    required this.isAnalyzing,
    required this.onRunAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}