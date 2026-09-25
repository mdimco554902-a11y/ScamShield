import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ScanRecord {
  final String id;
  final String title;
  final DateTime timestamp;
  final bool isScam;
  final String threatType;
  final String description;
  final List<String> indicators;
  final String scannedText;

  ScanRecord({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.isScam,
    required this.threatType,
    this.description = '',
    this.indicators = const [],
    this.scannedText = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timestamp': Timestamp.fromDate(timestamp),
      'isScam': isScam,
      'threatType': threatType,
      'description': description,
      'indicators': indicators,
      'scannedText': scannedText,
    };
  }

  factory ScanRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedTimestamp;
    final rawTimestamp = data['timestamp'];

    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else {
      parsedTimestamp = DateTime.now();
    }

    String rawTitle = data['title']?.toString() ?? '';
    String threat = data['threatType']?.toString() ?? '';

    // Auto-clean titles starting with 'Image Scan:'
    String cleanTitle = rawTitle;
    if (cleanTitle.toLowerCase().startsWith('image scan:')) {
      cleanTitle = cleanTitle.substring(11).trim();
    }

    final isFileName = cleanTitle.toLowerCase().contains('screenshot') ||
        cleanTitle.toLowerCase().endsWith('.png') ||
        cleanTitle.toLowerCase().endsWith('.jpg') ||
        cleanTitle.toLowerCase().endsWith('.jpeg');

    // If still an image filename, attempt to derive a clear threat title from threatType
    if (isFileName) {
      final cleanedThreat = threat.replaceAll(RegExp(r'\s*•\s*\d+%'), '').trim();
      cleanTitle = (cleanedThreat.isNotEmpty && !cleanedThreat.toLowerCase().contains('high risk'))
          ? cleanedThreat
          : "Analyzed Image Document";
    }

    // Safely parse indicators list
    final rawIndicators = data['indicators'];
    List<String> parsedIndicators = [];
    if (rawIndicators is List) {
      parsedIndicators = rawIndicators.map((e) => e.toString()).toList();
    }

    return ScanRecord(
      id: doc.id,
      title: cleanTitle,
      timestamp: parsedTimestamp,
      isScam: data['isScam'] == true,
      threatType: threat,
      description: data['description']?.toString() ?? '',
      indicators: parsedIndicators,
      scannedText: data['scannedText']?.toString() ?? '',
    );
  }
}

class ScanTrackerService extends ChangeNotifier {
  ScanTrackerService._() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToUserScans(user.uid);
      } else {
        _clearLocalState();
      }
    });
  }

  static final ScanTrackerService instance = ScanTrackerService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _scansSubscription;

  List<ScanRecord> _recentScans = [];
  int _totalScans = 0;
  int _scamsBlocked = 0;
  int _safeLinks = 0;

  int get totalScans => _totalScans;
  int get scamsBlocked => _scamsBlocked;
  int get safeLinks => _safeLinks;
  List<ScanRecord> get recentScans => List.unmodifiable(_recentScans);

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Listens to live Firestore scans for the active user
  void _listenToUserScans(String userId) {
    _scansSubscription?.cancel();

    _scansSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _recentScans = snapshot.docs
            .map((doc) => ScanRecord.fromFirestore(doc))
            .toList();

        _totalScans = _recentScans.length;
        _scamsBlocked = _recentScans.where((scan) => scan.isScam).length;
        _safeLinks = _recentScans.where((scan) => !scan.isScam).length;

        notifyListeners();
      },
      onError: (error, stackTrace) {
        debugPrint("Firestore Scan Listener Error: $error");
        debugPrint("Stacktrace: $stackTrace");
      },
    );
  }

  /// Extracts the main headline/subject line from raw OCR text when a raw filename is passed
  String _extractScamSubject({required String rawTitle, String ocrText = ''}) {
    String cleanTitle = rawTitle.trim();

    if (cleanTitle.toLowerCase().startsWith('image scan:')) {
      cleanTitle = cleanTitle.substring(11).trim();
    }

    final isFileName = cleanTitle.toLowerCase().contains('screenshot') ||
        cleanTitle.toLowerCase().endsWith('.png') ||
        cleanTitle.toLowerCase().endsWith('.jpg') ||
        cleanTitle.toLowerCase().endsWith('.jpeg');

    if (isFileName && ocrText.isNotEmpty) {
      final lines = ocrText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.length > 4)
          .toList();

      if (lines.isNotEmpty) {
        cleanTitle = lines.first;
        if (cleanTitle.length > 50) {
          cleanTitle = '${cleanTitle.substring(0, 47)}...';
        }
        return cleanTitle;
      }
    }

    return cleanTitle;
  }

  /// Writes a new scan document to `users/{uid}/scans`
  Future<void> recordNewScan({
    required String title,
    required bool isScam,
    required String threatType,
    String description = '',
    List<String> indicators = const [],
    String scannedText = '',
    String ocrText = '',
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint("Cannot record scan: User is not logged in.");
      return;
    }

    final formattedTitle = _extractScamSubject(rawTitle: title, ocrText: ocrText);
    final finalScannedText = scannedText.isNotEmpty ? scannedText : ocrText;

    final newScan = ScanRecord(
      id: '',
      title: formattedTitle,
      timestamp: DateTime.now(),
      isScam: isScam,
      threatType: threatType,
      description: description,
      indicators: indicators,
      scannedText: finalScannedText,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .add(newScan.toMap());
  }

  /// Deletes history docs only for the currently logged-in user
  Future<void> clearHistory() async {
    final uid = _currentUserId;
    if (uid == null) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  void _clearLocalState() {
    _scansSubscription?.cancel();
    _recentScans = [];
    _totalScans = 0;
    _scamsBlocked = 0;
    _safeLinks = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _scansSubscription?.cancel();
    super.dispose();
  }
}