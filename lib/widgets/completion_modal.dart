import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../helpers/nickname_helper.dart';

class CompletionModal extends StatefulWidget {
  final String taskId;
  final TimeSlot timeSlot;
  final DateTime date;

  const CompletionModal({
    super.key,
    required this.taskId,
    required this.timeSlot,
    required this.date,
  });

  @override
  State<CompletionModal> createState() => _CompletionModalState();
}

class _CompletionModalState extends State<CompletionModal> {
  final TaskService _taskService = TaskService();
  List<String> _nicknames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletionNicknames();
  }

  void _loadCompletionNicknames() async {
    final nicknames = await _taskService.getCompletionNicknames(
      widget.taskId,
      widget.date,
      widget.timeSlot,
    );

    if (mounted) {
      setState(() {
        _nicknames = nicknames;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Erledigt von',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_nicknames.length} Personen',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_nicknames.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Noch niemand hat diese Aufgabe erledigt',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _nicknames.length,
                  itemBuilder: (context, index) {
                    final nickname = _nicknames[index];
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
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getAvatarColor(nickname),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getAvatarInitial(nickname),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FutureBuilder<String>(
                              future: NicknameHelper.formatNickname(nickname),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? nickname,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (index == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Erster!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Schließen', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String nickname) {
    // Generate a color based on the nickname
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final hash = nickname.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _getAvatarInitial(String nickname) {
    if (nickname.isEmpty) return '?';
    return nickname[0].toUpperCase();
  }
}
