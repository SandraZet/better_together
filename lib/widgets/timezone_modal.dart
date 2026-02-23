import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:better_together/helpers/nickname_helper.dart';

class TimezoneModal extends StatefulWidget {
  final int counter;
  final List<String> nicknames;
  final String currentSlot;

  const TimezoneModal({
    super.key,
    required this.counter,
    required this.nicknames,
    required this.currentSlot,
  });

  @override
  State<TimezoneModal> createState() => _TimezoneModalState();
}

class _TimezoneModalState extends State<TimezoneModal> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Update jede Minute
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  // Alle Zeitzonen mit Offset
  static const List<Map<String, dynamic>> _allTimezones = [
    {'name': '🇰🇮 Line Islands', 'offset': 14.0},
    {'name': '🇳🇿 New Zealand', 'offset': 13.0},
    {'name': '🇫🇯 Fiji', 'offset': 12.0},
    {'name': '🇦🇺 Sydney', 'offset': 11.0},
    {'name': '🇦🇺 Brisbane / 🇷🇺 Vladivostok', 'offset': 10.0},
    {'name': '🇦🇺 Adelaide', 'offset': 9.5},
    {'name': '🇯🇵 Tokyo', 'offset': 9.0},
    {'name': '🇨🇳 Beijing', 'offset': 8.0},
    {'name': '🇷🇺 Novosibirsk / 🇹🇭 Bangkok / 🇮🇩 Jakarta', 'offset': 7.0},
    {'name': '🇲🇲 Yangon', 'offset': 6.5},
    {'name': '🇧🇩 Dhaka', 'offset': 6.0},
    {'name': '🇮🇳 Mumbai', 'offset': 5.5},
    {'name': '🇵🇰 Karachi', 'offset': 5.0},
    {'name': '🇦🇫 Kabul', 'offset': 4.5},
    {'name': '🇦🇪 Dubai', 'offset': 4.0},
    {'name': '🇮🇷 Tehran', 'offset': 3.5},
    {'name': '🇷🇺 Moscow', 'offset': 3.0},
    {'name': '🇬🇷 Athens', 'offset': 2.0},
    {'name': '🇩🇪 Berlin / 🇫🇷 Paris', 'offset': 1.0},
    {'name': '🇬🇧 London / 🇮🇸 Reykjavik', 'offset': 0.0},
    {'name': '🇨🇻 Cape Verde', 'offset': -1.0},
    {'name': '🇬🇸 South Georgia', 'offset': -2.0},
    {'name': '🇧🇷 São Paulo', 'offset': -3.0},
    {'name': '🇨🇦 Newfoundland', 'offset': -3.5},
    {'name': '🇧🇷 Manaus / 🇨🇱 Santiago', 'offset': -4.0},
    {'name': '🇨🇦 Toronto / 🇺🇸 New York', 'offset': -5.0},
    {'name': '🇺🇸 Chicago / 🇲🇽 Mexico City', 'offset': -6.0},
    {'name': '🇺🇸 Denver', 'offset': -7.0},
    {'name': '🇺🇸 Los Angeles / 🇨🇦 Vancouver', 'offset': -8.0},
    {'name': '🇺🇸 Alaska', 'offset': -9.0},
    {'name': '🇺🇸 Hawaii', 'offset': -10.0},
    {'name': '🇦🇸 Samoa', 'offset': -11.0},
    {'name': '🇺🇲 Baker Island', 'offset': -12.0},
  ];

  // Slot-Fenster definieren (lokale Zeit in jeder Zone: 5am-12pm etc.)
  Map<String, int> _getSlotWindow() {
    switch (widget.currentSlot) {
      case 'morning':
        return {'start': 5, 'end': 12}; // 5am-12pm local
      case 'noon':
        return {'start': 12, 'end': 17}; // 12pm-5pm local
      case 'afternoon':
        return {'start': 17, 'end': 22}; // 5pm-10pm local
      case 'night':
        return {'start': 22, 'end': 29}; // 10pm-5am local (next day)
      default:
        return {'start': 5, 'end': 12};
    }
  }

  // Berechne die lokale Zeit in einer Zeitzone
  double _getLocalHour(double offset) {
    final utcNow = DateTime.now().toUtc();
    final utcHour = utcNow.hour + (utcNow.minute / 60.0);

    // Lokale Stunde = UTC + Offset
    double localHour = utcHour + offset;

    // Normalisiere auf 0-24 Range
    if (localHour >= 24) localHour -= 24;
    if (localHour < 0) localHour += 24;

    return localHour;
  }

  // Get user's current UTC offset from device
  double _getCurrentUserOffset() {
    final offset = DateTime.now().timeZoneOffset;
    return offset.inMinutes / 60.0;
  }

  // Check if timezone matches user's current timezone
  bool _isUserTimezone(double offset) {
    final userOffset = _getCurrentUserOffset();
    return (offset - userOffset).abs() <
        0.1; // Allow small difference for rounding
  }

  // Hilfsfunktion: Bestimme User's UTC Offset basierend auf lokaler Zeit
  double _getUserOffset() {
    final now = DateTime.now();
    final offsetMinutes = now.timeZoneOffset.inMinutes;
    return offsetMinutes / 60.0;
  }

  // Prüfe ob Zeitzone im Slot-Fenster ist (basierend auf IHRER lokalen Zeit)
  bool _isInSlotWindow(double offset) {
    final window = _getSlotWindow();
    final start = window['start']!.toDouble();
    final end = window['end']!.toDouble();

    if (end > 24) {
      // Overnight slot (night: 22-29 = 22-5)
      // Vordefinierte Logik basierend auf User's lokaler Stunde
      final userOffset = _getUserOffset();
      final userLocalHour = _getLocalHour(userOffset);

      // Für jede Stunde des Night-Slots: Welche Offsets sind ACTIVE?
      // 22:00-22:59: user+0 bis user+6
      // 23:00-23:59: user-1 bis user+5
      // 00:00-00:59: user-2 bis user+4
      // 01:00-01:59: user-3 bis user+3
      // 02:00-02:59: user-4 bis user+2
      // 03:00-03:59: user-5 bis user+1
      // 04:00-04:59: user-6 bis user+0

      if (userLocalHour >= 22 && userLocalHour < 23) {
        return offset >= userOffset && offset <= userOffset + 6;
      } else if (userLocalHour >= 23 || userLocalHour < 1) {
        final hour = userLocalHour >= 23 ? 23 : 0;
        final shift = hour == 23 ? -1 : -2;
        return offset >= userOffset + shift && offset <= userOffset + shift + 6;
      } else if (userLocalHour >= 1 && userLocalHour < 2) {
        return offset >= userOffset - 3 && offset <= userOffset + 3;
      } else if (userLocalHour >= 2 && userLocalHour < 3) {
        return offset >= userOffset - 4 && offset <= userOffset + 2;
      } else if (userLocalHour >= 3 && userLocalHour < 4) {
        return offset >= userOffset - 5 && offset <= userOffset + 1;
      } else if (userLocalHour >= 4 && userLocalHour < 5) {
        return offset >= userOffset - 6 && offset <= userOffset;
      }

      // Außerhalb Night-Slot
      return false;
    } else if (start == 5 && end == 12) {
      // Morning slot (5:00-12:00)
      // Vordefinierte Logik basierend auf User's lokaler Stunde
      final userOffset = _getUserOffset();
      final userLocalHour = _getLocalHour(userOffset);

      // Für jede Stunde des Morning-Slots: Welche Offsets sind ACTIVE?
      // 05:00-05:59: user+0 bis user+6
      // 06:00-06:59: user-1 bis user+5
      // 07:00-07:59: user-2 bis user+4
      // 08:00-08:59: user-3 bis user+3
      // 09:00-09:59: user-4 bis user+2
      // 10:00-10:59: user-5 bis user+1
      // 11:00-11:59: user-6 bis user+0

      if (userLocalHour >= 5 && userLocalHour < 6) {
        return offset >= userOffset && offset <= userOffset + 6;
      } else if (userLocalHour >= 6 && userLocalHour < 7) {
        return offset >= userOffset - 1 && offset <= userOffset + 5;
      } else if (userLocalHour >= 7 && userLocalHour < 8) {
        return offset >= userOffset - 2 && offset <= userOffset + 4;
      } else if (userLocalHour >= 8 && userLocalHour < 9) {
        return offset >= userOffset - 3 && offset <= userOffset + 3;
      } else if (userLocalHour >= 9 && userLocalHour < 10) {
        return offset >= userOffset - 4 && offset <= userOffset + 2;
      } else if (userLocalHour >= 10 && userLocalHour < 11) {
        return offset >= userOffset - 5 && offset <= userOffset + 1;
      } else if (userLocalHour >= 11 && userLocalHour < 12) {
        return offset >= userOffset - 6 && offset <= userOffset;
      }

      // Außerhalb Morning-Slot
      return false;
    } else if (start == 12 && end == 17) {
      // Noon slot (12:00-17:00)
      // Vordefinierte Logik basierend auf User's lokaler Stunde
      final userOffset = _getUserOffset();
      final userLocalHour = _getLocalHour(userOffset);

      // Für jede Stunde des Noon-Slots: Welche Offsets sind ACTIVE?
      // 12:00-12:59: user+0 bis user+6
      // 13:00-13:59: user-1 bis user+5
      // 14:00-14:59: user-2 bis user+4
      // 15:00-15:59: user-3 bis user+3
      // 16:00-16:59: user-4 bis user+2

      if (userLocalHour >= 12 && userLocalHour < 13) {
        return offset >= userOffset && offset <= userOffset + 6;
      } else if (userLocalHour >= 13 && userLocalHour < 14) {
        return offset >= userOffset - 1 && offset <= userOffset + 5;
      } else if (userLocalHour >= 14 && userLocalHour < 15) {
        return offset >= userOffset - 2 && offset <= userOffset + 4;
      } else if (userLocalHour >= 15 && userLocalHour < 16) {
        return offset >= userOffset - 3 && offset <= userOffset + 3;
      } else if (userLocalHour >= 16 && userLocalHour < 17) {
        return offset >= userOffset - 4 && offset <= userOffset + 2;
      }

      // Außerhalb Noon-Slot
      return false;
    } else if (start == 17 && end == 22) {
      // Afternoon slot (17:00-22:00)
      // Vordefinierte Logik basierend auf User's lokaler Stunde
      final userOffset = _getUserOffset();
      final userLocalHour = _getLocalHour(userOffset);

      // Für jede Stunde des Afternoon-Slots: Welche Offsets sind ACTIVE?
      // 17:00-17:59: user+0 bis user+6
      // 18:00-18:59: user-1 bis user+5
      // 19:00-19:59: user-2 bis user+4
      // 20:00-20:59: user-3 bis user+3
      // 21:00-21:59: user-4 bis user+2

      if (userLocalHour >= 17 && userLocalHour < 18) {
        return offset >= userOffset && offset <= userOffset + 6;
      } else if (userLocalHour >= 18 && userLocalHour < 19) {
        return offset >= userOffset - 1 && offset <= userOffset + 5;
      } else if (userLocalHour >= 19 && userLocalHour < 20) {
        return offset >= userOffset - 2 && offset <= userOffset + 4;
      } else if (userLocalHour >= 20 && userLocalHour < 21) {
        return offset >= userOffset - 3 && offset <= userOffset + 3;
      } else if (userLocalHour >= 21 && userLocalHour < 22) {
        return offset >= userOffset - 4 && offset <= userOffset + 2;
      }

      // Außerhalb Afternoon-Slot
      return false;
    } else {
      // Andere Slots: Standard-Logik
      final localHour = _getLocalHour(offset);
      return localHour >= start && localHour < end;
    }
  }

  // Prüfe ob Zeitzone das Fenster schon passiert hat
  bool _hasPassed(double offset) {
    final window = _getSlotWindow();
    final start = window['start']!.toDouble();
    final end = window['end']!.toDouble();

    if (end > 24) {
      // Overnight slot (night: 22-29 = 22-5)
      final userOffset = _getUserOffset();
      final userLocalHour = _getLocalHour(userOffset);

      // PASSED = Alle Offsets die VOR dem ACTIVE-Fenster liegen (höhere Offsets)
      // 22:00-22:59: passed = user+7 bis +14
      // 23:00-23:59: passed = user+6 bis +14
      // 00:00-00:59: passed = user+5 bis +14
      // 01:00-01:59: passed = user+4 bis +14
      // 02:00-02:59: passed = user+3 bis +14
      // 03:00-03:59: passed = user+2 bis +14
      // 04:00-04:59: passed = user+1 bis +14

      if (userLocalHour >= 22 && userLocalHour < 23) {
        return offset > userOffset + 6;
      } else if (userLocalHour >= 23 || userLocalHour < 1) {
        final hour = userLocalHour >= 23 ? 23 : 0;
        final shift = hour == 23 ? -1 : -2;
        return offset > userOffset + shift + 6;
      } else if (userLocalHour >= 1 && userLocalHour < 2) {
        return offset > userOffset + 3;
      } else if (userLocalHour >= 2 && userLocalHour < 3) {
        return offset > userOffset + 2;
      } else if (userLocalHour >= 3 && userLocalHour < 4) {
        return offset > userOffset + 1;
      } else if (userLocalHour >= 4 && userLocalHour < 5) {
        return offset > userOffset;
      }

      // Außerhalb Night-Slot: Lokale Prüfung
      final localHour = _getLocalHour(offset);
      return localHour >= 5 && localHour < 12;
    } else if (start == 5 && end == 12) {
      // Morning slot (5:00-12:00)
      final userOffset = _getUserOffset();
      final userLocalHour = _getLocalHour(userOffset);

      // PASSED = Alle Offsets die VOR dem ACTIVE-Fenster liegen (höhere Offsets)
      // 05:00-05:59: passed = user+7 bis +14
      // 06:00-06:59: passed = user+6 bis +14
      // 07:00-07:59: passed = user+5 bis +14
      // 08:00-08:59: passed = user+4 bis +14
      // 09:00-09:59: passed = user+3 bis +14
      // 10:00-10:59: passed = user+2 bis +14
      // 11:00-11:59: passed = user+1 bis +14

      if (userLocalHour >= 5 && userLocalHour < 6) {
        return offset > userOffset + 6;
      } else if (userLocalHour >= 6 && userLocalHour < 7) {
        return offset > userOffset + 5;
      } else if (userLocalHour >= 7 && userLocalHour < 8) {
        return offset > userOffset + 4;
      } else if (userLocalHour >= 8 && userLocalHour < 9) {
        return offset > userOffset + 3;
      } else if (userLocalHour >= 9 && userLocalHour < 10) {
        return offset > userOffset + 2;
      } else if (userLocalHour >= 10 && userLocalHour < 11) {
        return offset > userOffset + 1;
      } else if (userLocalHour >= 11 && userLocalHour < 12) {
        return offset > userOffset;
      }

      // Außerhalb Morning-Slot: Lokale Prüfung
      final localHour = _getLocalHour(offset);
      return localHour >= 12;
    } else if (start == 12 && end == 17) {
      // Noon slot (12:00-17:00)
      final userOffset = _getUserOffset();
      final userLocalHour = _getLocalHour(userOffset);

      // PASSED = Alle Offsets die VOR dem ACTIVE-Fenster liegen (höhere Offsets)
      // 12:00-12:59: passed = user+7 bis +14
      // 13:00-13:59: passed = user+6 bis +14
      // 14:00-14:59: passed = user+5 bis +14
      // 15:00-15:59: passed = user+4 bis +14
      // 16:00-16:59: passed = user+3 bis +14

      if (userLocalHour >= 12 && userLocalHour < 13) {
        return offset > userOffset + 6;
      } else if (userLocalHour >= 13 && userLocalHour < 14) {
        return offset > userOffset + 5;
      } else if (userLocalHour >= 14 && userLocalHour < 15) {
        return offset > userOffset + 4;
      } else if (userLocalHour >= 15 && userLocalHour < 16) {
        return offset > userOffset + 3;
      } else if (userLocalHour >= 16 && userLocalHour < 17) {
        return offset > userOffset + 2;
      }

      // Außerhalb Noon-Slot: Lokale Prüfung
      final localHour = _getLocalHour(offset);
      return localHour >= 17;
    } else if (start == 17 && end == 22) {
      // Afternoon slot (17:00-22:00)
      final userOffset = _getUserOffset();
      final userLocalHour = _getLocalHour(userOffset);

      // PASSED = Alle Offsets die VOR dem ACTIVE-Fenster liegen (höhere Offsets)
      // 17:00-17:59: passed = user+7 bis +14
      // 18:00-18:59: passed = user+6 bis +14
      // 19:00-19:59: passed = user+5 bis +14
      // 20:00-20:59: passed = user+4 bis +14
      // 21:00-21:59: passed = user+3 bis +14

      if (userLocalHour >= 17 && userLocalHour < 18) {
        return offset > userOffset + 6;
      } else if (userLocalHour >= 18 && userLocalHour < 19) {
        return offset > userOffset + 5;
      } else if (userLocalHour >= 19 && userLocalHour < 20) {
        return offset > userOffset + 4;
      } else if (userLocalHour >= 20 && userLocalHour < 21) {
        return offset > userOffset + 3;
      } else if (userLocalHour >= 21 && userLocalHour < 22) {
        return offset > userOffset + 2;
      }

      // Außerhalb Afternoon-Slot: Lokale Prüfung
      final localHour = _getLocalHour(offset);
      return localHour >= 22 || localHour < 5;
    } else {
      // Andere Slots: Standard-Logik
      final localHour = _getLocalHour(offset);
      return localHour >= end;
    }
  } // Prüfe ob Zeitzone noch upcoming ist

  bool _isUpcoming(double offset) {
    // Einfach: Weder passed noch active
    return !_hasPassed(offset) && !_isInSlotWindow(offset);
  }

  List<String> _getPassedTimeZones() {
    return _allTimezones
        .where((tz) => _hasPassed(tz['offset'] as double))
        .map(
          (tz) =>
              '${tz['name']} (UTC${tz['offset'] >= 0 ? '+' : ''}${tz['offset']})',
        )
        .toList();
  }

  List<String> _getActiveTimeZones() {
    return _allTimezones
        .where((tz) => _isInSlotWindow(tz['offset'] as double))
        .map(
          (tz) =>
              '${tz['name']} (UTC${tz['offset'] >= 0 ? '+' : ''}${tz['offset']})',
        )
        .toList();
  }

  List<String> _getUpcomingTimeZones() {
    return _allTimezones
        .where((tz) => _isUpcoming(tz['offset'] as double))
        .map(
          (tz) =>
              '${tz['name']} (UTC${tz['offset'] >= 0 ? '+' : ''}${tz['offset']})',
        )
        .toList();
  }

  // Count completions by UTC offset
  Map<String, int> _getCompletionsByTimezone() {
    final Map<String, int> counts = {};

    for (final nickname in widget.nicknames) {
      // Extract UTC from nickname|location|UTC format (or nickname|UTC for old format)
      if (nickname.contains('|')) {
        final parts = nickname.split('|');

        // Try to get UTC from third part (new format: nickname|location|UTC)
        String? timezone;
        if (parts.length >= 3) {
          timezone = parts[2];
        } else if (parts.length >= 2) {
          // Fallback to second part if it looks like UTC
          timezone = parts[1];
        }

        // Remove timestamp if present (UTC#timestamp)
        if (timezone != null && timezone.contains('#')) {
          timezone = timezone.split('#')[0];
        }

        // Normalize UTC format: Convert UTC+5:30 to UTC+5.5
        if (timezone != null && timezone.startsWith('UTC')) {
          // Check if timezone has minute component (e.g., UTC+5:30)
          if (timezone.contains(':')) {
            final match = RegExp(r'UTC([+-]?\d+):(\d+)').firstMatch(timezone);
            if (match != null) {
              final hours = int.parse(match.group(1)!);
              final minutes = int.parse(match.group(2)!);
              final decimalOffset = hours + (minutes / 60.0);
              // Format to match display format (remove .0 for whole numbers)
              final sign = decimalOffset >= 0 ? '+' : '';
              timezone =
                  'UTC$sign${decimalOffset.toString().replaceAll('.0', '')}';
            }
          }
          counts[timezone] = (counts[timezone] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  // Get formatted timezone string
  String _formatTimezone(String tzName, double offset) {
    final utcStr =
        'UTC${offset >= 0 ? '+' : ''}${offset.toString().replaceAll('.0', '')}';
    return '$tzName ($utcStr)';
  }

  // Build badge widget for completion count
  Widget _buildCountBadge(int count, {bool isActive = false}) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [
                  // OPTION 1: Türkis → Blau → Orange (lebendig)
                  //Color(0xFF14B8A6), // türkis
                  // Color(0xFF3B82F6), // blau
                  Color(0xFFF97316), // orange
                  // OPTION 2: Orange → Lila (aktuell)
                  Color(0xFFF97316), // orange
                  Color(0xFF9333EA), // purple
                  // OPTION 3: Blau → Türkis (frisch)
                  // Color(0xFF3B82F6), // blau
                  // Color(0xFF14B8A6), // türkis

                  // OPTION 4: Pink → Orange (warm)
                  // Color(0xFFEC4899), // pink
                  // Color(0xFFF97316), // orange
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.white : Colors.black.withOpacity(0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 24, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People around the world make the same tiny micro-action.',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Info Text
                    Text(
                      'It starts in UTC+14 in Line Islands.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We end in UTC-12 in Baker Island.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Time zones that already passed
                    if (_getPassedTimeZones().isNotEmpty) ...[
                      Text(
                        'Time zones that already passed the window:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...() {
                        final counts = _getCompletionsByTimezone();
                        return _allTimezones
                            .where((tz) => _hasPassed(tz['offset'] as double))
                            .map((tz) {
                              final utcStr =
                                  'UTC${tz['offset'] >= 0 ? '+' : ''}${tz['offset'].toString().replaceAll('.0', '')}';
                              final count = counts[utcStr] ?? 0;
                              final isUserTz = _isUserTimezone(
                                tz['offset'] as double,
                              );

                              // Split city names by slash
                              final cities = (tz['name'] as String).split(
                                ' / ',
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: isUserTz
                                    ? BoxDecoration(
                                        color: Colors.black.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                    : null,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // First city with UTC offset
                                          Text(
                                            '${cities[0]} ($utcStr)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black.withOpacity(
                                                0.4,
                                              ),
                                              fontWeight: isUserTz
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                          // Additional cities without UTC
                                          ...cities
                                              .skip(1)
                                              .map(
                                                (city) => Text(
                                                  city,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                    fontWeight: isUserTz
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                        ],
                                      ),
                                    ),
                                    if (isUserTz) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '← You',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black.withOpacity(0.3),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    _buildCountBadge(count, isActive: false),
                                  ],
                                ),
                              );
                            })
                            .toList();
                      }(),
                      const SizedBox(height: 24),
                    ],

                    // Time zones currently active
                    Text(
                      'Time zones currently active:',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...() {
                      final counts = _getCompletionsByTimezone();
                      return _allTimezones
                          .where(
                            (tz) => _isInSlotWindow(tz['offset'] as double),
                          )
                          .map((tz) {
                            final utcStr =
                                'UTC${tz['offset'] >= 0 ? '+' : ''}${tz['offset'].toString().replaceAll('.0', '')}';
                            final count = counts[utcStr] ?? 0;
                            final isUserTz = _isUserTimezone(
                              tz['offset'] as double,
                            );

                            // Split city names by slash
                            final cities = (tz['name'] as String).split(' / ');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: isUserTz
                                  ? BoxDecoration(
                                      color: Colors.black.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // First city with UTC offset
                                        Text(
                                          '${cities[0]} ($utcStr)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        // Additional cities without UTC
                                        ...cities
                                            .skip(1)
                                            .map(
                                              (city) => Text(
                                                city,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                  if (isUserTz) ...[
                                    const SizedBox(width: 6),
                                    const Text(
                                      '← You',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    _buildCountBadge(count, isActive: false),
                                  ] else ...[
                                    _buildCountBadge(count, isActive: false),
                                  ],
                                ],
                              ),
                            );
                          })
                          .toList();
                    }(),
                    const SizedBox(height: 24),

                    // Time zones up next
                    Text(
                      'Time zones up next:',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...() {
                      final counts = _getCompletionsByTimezone();
                      return _allTimezones
                          .where((tz) => _isUpcoming(tz['offset'] as double))
                          .map((tz) {
                            final utcStr =
                                'UTC${tz['offset'] >= 0 ? '+' : ''}${tz['offset'].toString().replaceAll('.0', '')}';
                            final count = counts[utcStr] ?? 0;

                            // Split city names by slash
                            final cities = (tz['name'] as String).split(' / ');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // First city with UTC offset
                                        Text(
                                          '${cities[0]} ($utcStr)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        // Additional cities without UTC
                                        ...cities
                                            .skip(1)
                                            .map(
                                              (city) => Text(
                                                city,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                  _buildCountBadge(count, isActive: false),
                                ],
                              ),
                            );
                          })
                          .toList();
                    }(),
                    const SizedBox(height: 32),

                    // Divider
                    Container(height: 1, color: Colors.black.withOpacity(0.1)),
                    const SizedBox(height: 24),

                    // User list header
                    Row(
                      children: [
                        Text(
                          'Completed by',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.counter}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Scrollable user list
                    if (widget.nicknames.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No one yet. Be the first!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.4),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      )
                    else
                      ...widget.nicknames.asMap().entries.map((entry) {
                        final index = entry.key;
                        final nickname = entry.value;

                        // Extract timestamp from nickname#timestamp format
                        String? timeAgo;
                        if (nickname.contains('#')) {
                          final parts = nickname.split('#');
                          if (parts.length == 2) {
                            final timestamp = int.tryParse(parts[1]);
                            if (timestamp != null) {
                              final completedTime =
                                  DateTime.fromMillisecondsSinceEpoch(
                                    timestamp,
                                  );
                              final diff = DateTime.now().difference(
                                completedTime,
                              );

                              if (diff.inMinutes < 1) {
                                timeAgo = 'just now';
                              } else if (diff.inMinutes < 60) {
                                timeAgo = '${diff.inMinutes} min ago';
                              } else if (diff.inHours < 24) {
                                timeAgo = '${diff.inHours} hr ago';
                              } else {
                                timeAgo = '${diff.inDays} d ago';
                              }
                            }
                          }
                        }

                        return FutureBuilder<String>(
                          future: NicknameHelper.formatNickname(nickname),
                          builder: (context, snapshot) {
                            final displayName = snapshot.data ?? nickname;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (timeAgo != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            timeAgo,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
