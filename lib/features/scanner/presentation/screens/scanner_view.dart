import 'package:flutter/material.dart';
import '../widgets/upload_button.dart';
import '../widgets/manual_input_card.dart';

/// Layout shell for the Threat Scanner Workspace tab.
/// Delegates image scanning to [UploadButton] and text analysis to [ManualInputCard].
class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UploadButton(),
          SizedBox(height: 24),
          ManualInputCard(),
        ],
      ),
    );
  }
}