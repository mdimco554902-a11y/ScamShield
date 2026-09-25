import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

class ScamAnalysisResult {
  final bool isScam;
  final String riskLevel; // 'HIGH', 'MEDIUM', 'LOW'
  final int confidenceScore; // Represents Threat Probability (0-100)
  final String summary;
  final String scannedText; // Raw text extracted from image or input message
  final List<String> flags;

  ScamAnalysisResult({
    required this.isScam,
    required this.riskLevel,
    required this.confidenceScore,
    required this.summary,
    required this.scannedText,
    required this.flags,
  });

  factory ScamAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ScamAnalysisResult(
      isScam: json['isScam'] ?? false,
      riskLevel: json['riskLevel'] ?? 'LOW',
      confidenceScore: json['confidenceScore'] ?? 0,
      summary: json['summary'] ?? 'No summary available.',
      scannedText: json['scannedText'] ?? '',
      flags: List<String>.from(json['flags'] ?? []),
    );
  }
}

class ScamAnalysisService {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  static const String _systemPrompt = '''
You are ScamShield AI, an expert cybersecurity scanner.
Analyze the provided text or image/screenshot for scam indicators, phishing attempts, smishing, fake urgency, or suspicious links.

STRICT THREAT SCORING RULES:
1. "isScam": Set to true ONLY if the content contains high or medium severity threats/scams. Set to false if safe, benign, or an official notification.
2. "confidenceScore": Integer from 0 to 100 representing THREAT/RISK PROBABILITY:
   - 0 to 39: Safe / Clean / Legitimate content (Low Threat Risk)
   - 40 to 79: Moderate risk or suspicious elements requiring caution (Medium Threat Risk)
   - 80 to 100: Malicious scam, phishing attempt, or high threat (High Threat Risk)
   CRITICAL: Do NOT return high confidence numbers (e.g. 90%) for safe content! Safe content MUST have a score below 40.
3. "riskLevel": Must strictly be "LOW" (for 0-39 score), "MEDIUM" (for 40-79 score), or "HIGH" (for 80-100 score).
4. "scannedText": For image/screenshot inputs, extract and transcribe the exact raw text visible inside the image. For text inputs, echo back the original text.

You MUST respond strictly in raw JSON with this exact structure:
{
  "isScam": false,
  "riskLevel": "LOW",
  "confidenceScore": 5,
  "scannedText": "Raw extracted text or transcribed message content from image...",
  "summary": "This message appears to be a legitimate automated notification with no scam indicators.",
  "flags": []
}
''';

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-3.6-flash',
    apiKey: _apiKey,
    systemInstruction: Content.system(_systemPrompt),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.2,
    ),
  );

  bool _isAnalyzing = false;
  DateTime? _cooldownUntil;

  void resetCooldown() {
    _cooldownUntil = null;
    _isAnalyzing = false;
  }

  int get remainingCooldownSeconds {
    if (_cooldownUntil == null) return 0;

    final millisDiff = _cooldownUntil!.difference(DateTime.now()).inMilliseconds;

    if (millisDiff <= 0) {
      _cooldownUntil = null;
      return 0;
    }

    return (millisDiff / 1000).ceil();
  }

  Future<ScamAnalysisResult> analyzeText(String inputText) async {
    _checkPreconditions();

    _isAnalyzing = true;
    int attempts = 4;

    while (attempts > 0) {
      try {
        final response = await _model.generateContent([
          Content.text('Analyze this text for scams:\n"$inputText"'),
        ]);
        final result = _parseResponse(response.text);

        _isAnalyzing = false;
        return result;
      } catch (e) {
        final msg = e.toString();

        if ((msg.contains('503') || msg.contains('UNAVAILABLE') || msg.contains('high demand')) && attempts > 1) {
          attempts--;
          await Future.delayed(Duration(seconds: (5 - attempts) * 2));
          continue;
        }

        _isAnalyzing = false;
        _handleApiError(e);
      }
    }

    _isAnalyzing = false;
    throw Exception('Google AI servers are currently experiencing high demand. Please try again in a few seconds.');
  }

  Future<ScamAnalysisResult> analyzeImage(Uint8List imageBytes, String mimeType) async {
    _checkPreconditions();

    _isAnalyzing = true;
    int attempts = 4;

    while (attempts > 0) {
      try {
        final imagePart = DataPart(mimeType, imageBytes);
        final response = await _model.generateContent([
          Content.multi([
            imagePart,
            TextPart('Transcribe all visible text from this image into "scannedText", and analyze it for potential scams or phishing.'),
          ]),
        ]);
        final result = _parseResponse(response.text);

        _isAnalyzing = false;
        return result;
      } catch (e) {
        final msg = e.toString();

        if ((msg.contains('503') || msg.contains('UNAVAILABLE') || msg.contains('high demand')) && attempts > 1) {
          attempts--;
          await Future.delayed(Duration(seconds: (5 - attempts) * 2));
          continue;
        }

        _isAnalyzing = false;
        _handleApiError(e);
      }
    }

    _isAnalyzing = false;
    throw Exception('Google AI servers are currently experiencing high demand. Please try again in a few seconds.');
  }

  void _checkPreconditions() {
    if (_isAnalyzing) {
      throw Exception('An analysis is already in progress. Please wait...');
    }

    final cooldown = remainingCooldownSeconds;
    if (cooldown > 0) {
      throw Exception('Rate limit active! Please wait $cooldown seconds before analyzing another item.');
    }
  }

  Never _handleApiError(Object error) {
    final msg = error.toString();

    if (msg.contains('429') || msg.contains('RESOURCE_EXHAUSTED') || msg.contains('quota')) {
      final match = RegExp(r'retry in (\d+(\.\d+)?)s').firstMatch(msg);
      int waitSecs = match != null ? (double.parse(match.group(1)!).ceil()) : 60;

      if (waitSecs > 60) waitSecs = 60;
      _cooldownUntil = DateTime.now().add(Duration(seconds: waitSecs));

      throw Exception('Rate limit reached! Please wait $waitSecs seconds before analyzing another item.');
    } else if (msg.contains('503') || msg.contains('UNAVAILABLE') || msg.contains('high demand')) {
      throw Exception('Google AI service is currently busy due to heavy demand. Please try again shortly.');
    }

    throw Exception('Analysis failed due to a network error. Please try again.');
  }

  ScamAnalysisResult _parseResponse(String? responseText) {
    if (responseText == null || responseText.isEmpty) {
      throw Exception('Failed to receive response from ScamShield AI.');
    }

    String cleanJson = responseText.trim();
    if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
    }

    final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;
    return ScamAnalysisResult.fromJson(decoded);
  }
}