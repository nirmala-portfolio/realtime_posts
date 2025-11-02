// lib/profile_setup.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileSetupPage extends StatefulWidget {
  final String uid;
  const ProfileSetupPage({required this.uid, super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter display name');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final ref = FirebaseDatabase.instance.ref('users/${widget.uid}');
      await ref.set({
        'displayName': name,
        'createdAt': DateTime.now().toIso8601String(),
      });
      // go back to home (replace with your feed page in a moment)
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set display name')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Display name')),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Save')),
          ],
        ),
      ),
    );
  }
}
