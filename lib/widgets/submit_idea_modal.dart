import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../providers/app_state_provider.dart';

class SubmitIdeaModal extends StatefulWidget {
  final TimeSlot timeSlot;

  const SubmitIdeaModal({super.key, required this.timeSlot});

  @override
  State<SubmitIdeaModal> createState() => _SubmitIdeaModalState();
}

class _SubmitIdeaModalState extends State<SubmitIdeaModal> {
  final TaskService _taskService = TaskService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskTheme _selectedTheme = TaskTheme.creativity;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitIdea() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib einen Titel für deine Idee ein'),
        ),
      );
      return;
    }

    final provider = Provider.of<AppStateProvider>(context, listen: false);

    setState(() {
      _isSubmitting = true;
    });

    final task = Task(
      id: '', // Will be set by Firestore
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      authorNickname: provider.userNickname.isEmpty
          ? 'Anonym'
          : provider.userNickname,
      theme: _selectedTheme,
      timeSlot: widget.timeSlot,
      createdAt: DateTime.now(),
      activeDate: DateTime.now(), // For future scheduling, could be different
      isActive: false, // Will be activated later by admin/system
    );

    final taskId = await _taskService.createTask(task);

    setState(() {
      _isSubmitting = false;
    });

    if (taskId != null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deine Idee wurde eingereicht! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fehler beim Einreichen der Idee. Versuche es später nochmal.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Neue Aufgaben-Idee',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Für ${_getTimeSlotName(widget.timeSlot)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Title Field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel der Aufgabe *',
                hintText: 'z.B. "Mache 10 Kniebeugen"',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // Description Field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                hintText: 'Zusätzliche Details oder Erklärungen...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 250,
            ),

            const SizedBox(height: 16),

            // Theme Selection
            Text(
              'Kategorie',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: TaskTheme.values.length,
                itemBuilder: (context, index) {
                  final theme = TaskTheme.values[index];
                  final isSelected = theme == _selectedTheme;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTheme = theme;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getThemeName(theme),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitIdea,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Einreichen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeSlotName(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.night:
        return 'Nacht (0-3 Uhr)';
      case TimeSlot.morning:
        return 'Morgen (6-12 Uhr)';
      case TimeSlot.afternoon:
        return 'Mittag (12-18 Uhr)';
      case TimeSlot.evening:
        return 'Abend (18-22 Uhr)';
    }
  }

  String _getThemeName(TaskTheme theme) {
    switch (theme) {
      case TaskTheme.creativity:
        return 'Kreativität';
      case TaskTheme.fitness:
        return 'Fitness';
      case TaskTheme.mindfulness:
        return 'Achtsamkeit';
      case TaskTheme.social:
        return 'Soziales';
      case TaskTheme.productivity:
        return 'Produktivität';
      case TaskTheme.learning:
        return 'Lernen';
      case TaskTheme.nature:
        return 'Natur';
      case TaskTheme.cooking:
        return 'Kochen';
      case TaskTheme.entertainment:
        return 'Unterhaltung';
      case TaskTheme.wellness:
        return 'Wellness';
    }
  }
}
