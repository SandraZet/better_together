import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/task_themes.dart';
import 'package:better_together/providers/app_state_provider.dart';
import '../utils/time_slot_manager.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TaskThemeConfig themeConfig;
  final VoidCallback onCompletionTap;
  final Animation<double>? rocketGlow; // Raketen-Animation

  const CustomAppBar({
    super.key,
    required this.themeConfig,
    required this.onCompletionTap,
    this.rocketGlow,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final timeUntilNext = TimeSlotManager.getTimeUntilNextSlot();

        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.person,
                  color: themeConfig.appBarIconColor,
                  size: 24,
                ),
                onPressed: () {
                  _showUserSettings(context, provider);
                },
              ),
            ),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              TimeSlotManager.formatDuration(timeUntilNext),
              style: TextStyle(
                color: themeConfig.countTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: onCompletionTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Raketen-Icon mit Animation
                        if (rocketGlow != null)
                          AnimatedBuilder(
                            animation: rocketGlow!,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: rocketGlow!.value,
                                child: Icon(
                                  Icons.rocket_launch_rounded,
                                  color: themeConfig.appBarIconColor,
                                  size: 20,
                                ),
                              );
                            },
                          )
                        else
                          Icon(
                            Icons.rocket_launch_rounded,
                            color: themeConfig.appBarIconColor,
                            size: 20,
                          ),
                        const SizedBox(width: 4),
                        StreamBuilder<int>(
                          stream: _getCompletionCountStream(provider),
                          builder: (context, snapshot) {
                            final count =
                                snapshot.data ?? provider.completionCount;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                count.toString(),
                                key: ValueKey(count),
                                style: TextStyle(
                                  color: themeConfig.countTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<int>? _getCompletionCountStream(AppStateProvider provider) {
    final currentTask = provider.currentTask;
    final currentSlot = provider.currentTimeSlot;

    if (currentTask != null && currentSlot != null) {
      // Import TaskService here if needed
      // return TaskService().getCompletionCountStream(
      //   currentTask.id,
      //   DateTime.now(),
      //   currentSlot,
      // );
    }
    return null;
  }

  void _showUserSettings(BuildContext context, AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Benutzer-Einstellungen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'Dein Nickname',
              ),
              controller: TextEditingController(text: provider.userNickname),
              onChanged: (value) {
                provider.setUserNickname(value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Aktueller Zeitslot: ${TimeSlotManager.getCurrentSlotDisplayName()}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
