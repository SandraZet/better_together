import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:better_together/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _statistics = [];
  bool _isLoading = true;
  Set<String> _userCompletedSlots = {};

  // Static cache for statistics
  static List<Map<String, dynamic>>? _cachedStatistics;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    // Pre-populate from cache synchronously so first build has data immediately
    final now = DateTime.now();
    if (_cachedStatistics != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < _cacheDuration) {
      _statistics = _cachedStatistics!;
      _isLoading = false;
    }
    _loadStatistics(forceRefresh: false);
  }

  Future<void> _loadStatistics({bool forceRefresh = false}) async {
    // Load user's completed slots from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final completedSlots = <String>{};
    for (final key in prefs.getKeys()) {
      if (key.endsWith('_done') && prefs.getBool(key) == true) {
        completedSlots.add(key.replaceAll('_done', ''));
      }
    }

    // Check if we have valid cached data
    final now = DateTime.now();
    final hasValidCache =
        _cachedStatistics != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < _cacheDuration;

    if (hasValidCache && !forceRefresh) {
      // Cache already applied in initState; just update prefs-based data
      if (mounted) {
        setState(() {
          _userCompletedSlots = completedSlots;
          _isLoading = false;
        });
      }
      // Refresh in background
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _refreshInBackground();
      });
    } else {
      // No cache or forced refresh - load from Firestore
      setState(() => _isLoading = true);

      final stats = await _firebaseService.getStatistics();

      // Update cache
      _cachedStatistics = stats;
      _cacheTime = now;

      setState(() {
        _statistics = stats;
        _userCompletedSlots = completedSlots;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshInBackground() async {
    final stats = await _firebaseService.getStatistics();
    final now = DateTime.now();

    // Update cache
    _cachedStatistics = stats;
    _cacheTime = now;

    // Update UI if data changed
    if (mounted && stats.length != _statistics.length) {
      setState(() {
        _statistics = stats;
      });
    }
  }

  bool _didUserComplete(String date, String slot) {
    return _userCompletedSlots.contains('${date}_$slot');
  }

  String _formatSlotTime(String slot) {
    switch (slot) {
      case 'morning':
        return '5am - 12pm';
      case 'noon':
        return '12pm - 5pm';
      case 'afternoon':
        return '5pm - 10pm';
      case 'night':
        return '10pm - 5am';
      default:
        return slot;
    }
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    }
    return date;
  }

  LinearGradient _getSlotGradient(String slot) {
    switch (slot) {
      case 'morning':
        return LinearGradient(
          colors: [Colors.orange[200]!, Colors.orange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'noon':
        return LinearGradient(
          colors: [Colors.pink[200]!, Colors.pink[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'afternoon':
        return LinearGradient(
          colors: [Colors.purple[200]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'night':
        return LinearGradient(
          colors: [Colors.deepPurple[400]!, Colors.deepPurple[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Colors.grey, Colors.grey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double scale = (w / 390.0).clamp(1.0, 1.4);
    final double hPad = w > 640 ? (w - 600) / 2.0 : 16.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'The Movement',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statistics.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 80,
                    color: Colors.black.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No statistics yet',
                    style: GoogleFonts.poppins(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadStatistics(forceRefresh: true),
              child: ListView(
                padding: EdgeInsets.only(
                  left: hPad,
                  right: hPad,
                  top: 16,
                  bottom: 100, // Extra bottom padding for last item
                ),
                children: [
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Since Launch',
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.pink[400]!, Colors.purple[400]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'Feb 20, 2026',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem(
                              'Tasks',
                              _statistics.length.toString(),
                            ),
                            _buildSummaryItem(
                              'Completions',
                              _statistics
                                  .fold<int>(
                                    0,
                                    (sum, stat) =>
                                        sum + (stat['completions'] as int),
                                  )
                                  .toString(),
                            ),
                            _buildSummaryItem(
                              'Timezones',
                              _statistics
                                  .map((s) => s['timezones'] as int)
                                  .fold<Set<int>>(
                                    {},
                                    (set, val) => set..add(val),
                                  )
                                  .fold<int>(0, (sum, val) => sum + val)
                                  .toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Task List
                  Text(
                    'Micro-Task History',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._statistics.map((stat) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with date and slot
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(stat['date']),
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: _getSlotGradient(stat['slot']),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatSlotTime(stat['slot']),
                                    style: GoogleFonts.poppins(
                                      color: stat['slot'] == 'night'
                                          ? Colors.black
                                          : Colors.black,
                                      fontSize: 11 * scale,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white),

                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        stat['headline'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.black87,
                                          fontSize: 16 * scale,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    if (_didUserComplete(
                                      stat['date'],
                                      stat['slot'],
                                    )) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'You',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (stat['submittedBy']
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Idea: ${stat['submittedBy']}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black45,
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildStatBadge(
                                      Icons.people,
                                      '${stat['completions']} people',
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatBadge(
                                      Icons.public,
                                      '${stat['timezones']} timezones',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 28 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    final double scale = (MediaQuery.of(context).size.width / 390.0).clamp(
      1.0,
      1.4,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * scale, color: Colors.black),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
