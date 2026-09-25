import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/scan_tracker_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  static const int _maxTotalLimit = 50;

  String _searchQuery = '';
  String _selectedRiskFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Cleans titles that start with "Image Scan:" or contain filenames like "Screenshot..."
  String _formatDisplayTitle(String title, String threatType) {
    String cleanTitle = title;

    // Remove "Image Scan: " prefix if present
    if (cleanTitle.toLowerCase().startsWith('image scan:')) {
      cleanTitle = cleanTitle.substring(11).trim();
    }

    // If the title is just a screenshot filename, fall back to displaying threat type
    final isFileName = cleanTitle.toLowerCase().contains('screenshot') ||
        cleanTitle.toLowerCase().endsWith('.png') ||
        cleanTitle.toLowerCase().endsWith('.jpg') ||
        cleanTitle.toLowerCase().endsWith('.jpeg');

    if (isFileName) {
      final cleanedThreat = threatType.replaceAll(RegExp(r'\s*•\s*\d+%'), '').trim();
      return cleanedThreat.isNotEmpty ? cleanedThreat : "Analyzed Image Document";
    }

    return cleanTitle;
  }

  int? _extractScore(String threatType) {
    final RegExp regExp = RegExp(r'(\d+)%');
    final match = regExp.firstMatch(threatType);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  String _getRiskCategory(bool isScam, String threatType) {
    final score = _extractScore(threatType);
    final upperType = threatType.toUpperCase();

    if (score != null) {
      if (score >= 80) return "High Risk";
      if (score >= 40) return "Medium Risk";
      return "Low / Safe";
    }

    if (!isScam) return "Low / Safe";
    if (upperType.contains('MEDIUM')) return "Medium Risk";
    return "High Risk";
  }

  Widget _buildRiskBadge(bool isScam, String threatType) {
    final category = _getRiskCategory(isScam, threatType);

    Color badgeColor;
    Color textColor;
    String badgeLabel;

    switch (category) {
      case "High Risk":
        badgeColor = Colors.redAccent.withValues(alpha: 0.2);
        textColor = Colors.redAccent;
        badgeLabel = "HIGH RISK";
        break;
      case "Medium Risk":
        badgeColor = Colors.orangeAccent.withValues(alpha: 0.2);
        textColor = Colors.orangeAccent;
        badgeLabel = "MEDIUM RISK";
        break;
      default:
        badgeColor = AppColors.safe.withValues(alpha: 0.2);
        textColor = AppColors.safe;
        badgeLabel = "SAFE";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        badgeLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Color _getIconColor(bool isScam, String threatType) {
    final category = _getRiskCategory(isScam, threatType);
    if (category == "High Risk") return Colors.redAccent;
    if (category == "Medium Risk") return Colors.orangeAccent;
    return AppColors.safe;
  }

  /// Displays detailed analysis in a bottom sheet when a history item is tapped
  void _showScanDetailModal(BuildContext context, ScanRecord scan) {
    final formattedDateTime =
        DateFormat('MMMM d, yyyy • HH:mm').format(scan.timestamp);
    final iconColor = _getIconColor(scan.isScam, scan.threatType);
    final displayTitle = _formatDisplayTitle(scan.title, scan.threatType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header & Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      scan.isScam
                          ? Icons.gpp_bad_rounded
                          : Icons.verified_user_rounded,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildRiskBadge(scan.isScam, scan.threatType),
                            const SizedBox(width: 8),
                            Text(
                              formattedDateTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SCANNED MESSAGE CONTAINER ---
                      const Text(
                        "SCANNED MESSAGE",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          scan.scannedText.isNotEmpty
                              ? scan.scannedText
                              : "No raw text available for this scan.",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE2E8F0),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Threat Type Field
                      if (scan.threatType.isNotEmpty) ...[
                        const Text(
                          "THREAT CATEGORY",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scan.threatType,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Stored Analysis Description
                      if (scan.description.isNotEmpty) ...[
                        const Text(
                          "ANALYSIS SUMMARY",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scan.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFCBD5E1),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Stored Threat Indicators
                      if (scan.indicators.isNotEmpty) ...[
                        const Text(
                          "DETECTED RISK INDICATORS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...scan.indicators.map(
                          (indicator) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    indicator,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFE2E8F0),
                                    ),
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
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "Clear History?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to delete all activity logs and reset your scan metrics? This cannot be undone.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                ScanTrackerService.instance.clearHistory();
                setState(() {
                  _currentPage = 1;
                  _searchQuery = '';
                  _selectedRiskFilter = 'All';
                  _searchController.clear();
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Scan history cleared successfully."),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                "Clear All",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ScanTrackerService.instance,
      builder: (context, _) {
        final List<ScanRecord> allScans = ScanTrackerService.instance.recentScans;

        if (allScans.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 48, color: AppColors.accent),
                SizedBox(height: 16),
                Text(
                  "Scan History Empty",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Detailed scan activity and threat logs will appear here.",
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          );
        }

        final limitedScans = allScans.take(_maxTotalLimit).toList();

        final filteredScans = limitedScans.where((scan) {
          final category = _getRiskCategory(scan.isScam, scan.threatType);

          if (_selectedRiskFilter != 'All' && category != _selectedRiskFilter) {
            return false;
          }

          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            final matchesTitle = scan.title.toLowerCase().contains(query);
            final matchesThreat = scan.threatType.toLowerCase().contains(query);
            final matchesDesc = scan.description.toLowerCase().contains(query);
            final matchesScannedText = scan.scannedText.toLowerCase().contains(query);

            if (!matchesTitle && !matchesThreat && !matchesDesc && !matchesScannedText) {
              return false;
            }
          }

          return true;
        }).toList();

        final totalLogs = filteredScans.length;
        final totalPages = max(1, (totalLogs / _itemsPerPage).ceil());

        if (_currentPage > totalPages) {
          _currentPage = totalPages;
        }

        final startIndex = max(0, (_currentPage - 1) * _itemsPerPage);
        final endIndex = min(startIndex + _itemsPerPage, totalLogs);
        final pageScans = (startIndex < totalLogs)
            ? filteredScans.sublist(startIndex, endIndex)
            : <ScanRecord>[];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$totalLogs Logs Saved${allScans.length > _maxTotalLimit ? ' (Max 50)' : ''}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showClearConfirmationDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text(
                      "Clear History",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Input Field
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                  });
                },
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search logs...",
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All',
                    'High Risk',
                    'Medium Risk',
                    'Low / Safe',
                  ].map((filter) {
                    final isSelected = _selectedRiskFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          filter == 'All' ? 'All Risk Levels' : filter,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accent,
                        backgroundColor: const Color(0xFF1E293B),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRiskFilter = filter;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Log Items List
              if (pageScans.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: const Text(
                    "No logs matching your search criteria.",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pageScans.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final scan = pageScans[index];
                    final formattedDateTime =
                        DateFormat('MMM d, yyyy • HH:mm').format(scan.timestamp);
                    final iconColor = _getIconColor(scan.isScam, scan.threatType);
                    final displayTitle = _formatDisplayTitle(scan.title, scan.threatType);

                    return InkWell(
                      onTap: () => _showScanDetailModal(context, scan),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                scan.isScam
                                    ? Icons.gpp_bad_rounded
                                    : Icons.verified_user_rounded,
                                color: iconColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildRiskBadge(scan.isScam, scan.threatType),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          scan.threatType,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedDateTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Pagination Controls
              if (totalPages > 1) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: Colors.white,
                      disabledColor: Colors.white24,
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Page $_currentPage of $totalPages",
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: Colors.white,
                      disabledColor: Colors.white24,
                      onPressed: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}