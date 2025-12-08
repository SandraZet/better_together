import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugPrefsScreen extends StatefulWidget {
  const DebugPrefsScreen({super.key});

  @override
  State<DebugPrefsScreen> createState() => _DebugPrefsScreenState();
}

class _DebugPrefsScreenState extends State<DebugPrefsScreen> {
  Map<String, dynamic> _prefs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> data = {};

    for (final key in keys) {
      data[key] = prefs.get(key);
    }

    setState(() {
      _prefs = data;
      _isLoading = false;
    });
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _loadPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SharedPreferences Debug'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPrefs),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Alles löschen?'),
                  content: const Text(
                    'Alle SharedPreferences werden gelöscht.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Löschen'),
                    ),
                  ],
                ),
              );
              if (confirm == true) _clearPrefs();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prefs.isEmpty
          ? const Center(child: Text('Keine Daten gespeichert'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _prefs.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      entry.value.toString(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
