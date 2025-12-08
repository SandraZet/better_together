import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';

class TaskThemeConfig {
  final List<Color> gradientColors;
  final TextStyle titleStyle;
  final TextStyle authorStyle;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color appBarIconColor;
  final Color countTextColor;

  TaskThemeConfig({
    required this.gradientColors,
    required this.titleStyle,
    required this.authorStyle,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.appBarIconColor,
    required this.countTextColor,
  });
}

class TaskThemeManager {
  static TaskThemeConfig getThemeForTask(TaskTheme theme) {
    switch (theme) {
      case TaskTheme.creativity:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFFFF6B6B), // Coral
            const Color(0xFFFFE66D), // Yellow
          ],
          titleStyle: GoogleFonts.comfortaa(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.comfortaa(
            fontSize: 16,
            color: Colors.white70,
          ),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFFFF6B6B),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.fitness:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFF56CCF2), // Light Blue
            const Color(0xFF2F80ED), // Blue
          ],
          titleStyle: GoogleFonts.oswald(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.oswald(fontSize: 16, color: Colors.white70),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFF2F80ED),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.mindfulness:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFFBB6BD9), // Purple
            const Color(0xFF9B59B6), // Darker Purple
          ],
          titleStyle: GoogleFonts.libreBaskerville(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.libreBaskerville(
            fontSize: 16,
            color: Colors.white70,
          ),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFF9B59B6),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.social:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFFFF9A9E), // Light Pink
            const Color(0xFFFECFEF), // Lighter Pink
          ],
          titleStyle: GoogleFonts.dancingScript(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.dancingScript(
            fontSize: 18,
            color: Colors.white70,
          ),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFFFF9A9E),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.productivity:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFF667eea), // Blue Purple
            const Color(0xFF764ba2), // Purple
          ],
          titleStyle: GoogleFonts.roboto(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.roboto(fontSize: 16, color: Colors.white70),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFF667eea),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.learning:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFFF093FB), // Light Purple
            const Color(0xFFF5576C), // Pink Red
          ],
          titleStyle: GoogleFonts.merriweather(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.merriweather(
            fontSize: 16,
            color: Colors.white70,
          ),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFFF5576C),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.nature:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFF96E6A1), // Light Green
            const Color(0xFF4ECDC4), // Turquoise
          ],
          titleStyle: GoogleFonts.pacifico(
            fontSize: 28,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.pacifico(
            fontSize: 16,
            color: Colors.white70,
          ),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFF4ECDC4),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.cooking:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFFFFAB91), // Orange
            const Color(0xFFFF8A65), // Darker Orange
          ],
          titleStyle: GoogleFonts.lobster(
            fontSize: 32,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.lobster(fontSize: 16, color: Colors.white70),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFFFF8A65),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.entertainment:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFFFFE259), // Yellow
            const Color(0xFFFFA751), // Orange
          ],
          titleStyle: GoogleFonts.frederickaTheGreat(
            fontSize: 30,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.frederickaTheGreat(
            fontSize: 16,
            color: Colors.white70,
          ),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFFFFA751),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );

      case TaskTheme.wellness:
        return TaskThemeConfig(
          gradientColors: [
            const Color(0xFF81C784), // Light Green
            const Color(0xFF4FC3F7), // Light Blue
          ],
          titleStyle: GoogleFonts.quicksand(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
          authorStyle: GoogleFonts.quicksand(
            fontSize: 16,
            color: Colors.white70,
          ),
          buttonColor: Colors.white,
          buttonTextColor: const Color(0xFF81C784),
          appBarIconColor: Colors.white,
          countTextColor: Colors.white,
        );
    }
  }

  // Rest mode theme (Feuer/Fire theme for 22-6 Uhr)
  static TaskThemeConfig getRestModeTheme() {
    return TaskThemeConfig(
      gradientColors: [
        const Color(0xFF2C1810), // Dark Brown
        const Color(0xFF8B4513), // Saddle Brown
        const Color(0xFFFF4500), // Orange Red
      ],
      titleStyle: GoogleFonts.lobster(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFD700), // Gold
        shadows: [
          const Shadow(
            blurRadius: 10,
            color: Color(0xFFFF4500),
            offset: Offset(0, 0),
          ),
        ],
      ),
      authorStyle: GoogleFonts.cinzel(
        fontSize: 18,
        color: const Color(0xFFFFB347), // Light Orange
      ),
      buttonColor: const Color(0xFFFF4500),
      buttonTextColor: Colors.white,
      appBarIconColor: const Color(0xFFFFD700),
      countTextColor: const Color(0xFFFFD700),
    );
  }
}
