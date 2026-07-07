import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/calendar_provider.dart';
import '../../services/secure_storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await SecureStorageService().getOpenAiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = key != null && key.isNotEmpty;
        _apiKeyCtrl.text = key ?? '';
      });
    }
  }

  Future<void> _saveKey() async {
    await SecureStorageService().setOpenAiKey(_apiKeyCtrl.text.trim());
    if (mounted) {
      setState(() => _hasApiKey = _apiKeyCtrl.text.trim().isNotEmpty);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved')),
      );
    }
  }

  Future<void> _deleteKey() async {
    await SecureStorageService().deleteOpenAiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = false;
        _apiKeyCtrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gcal = ref.watch(googleCalendarServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Google Calendar', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            title: Text(gcal.isSignedIn ? 'Connected' : 'Not connected'),
            subtitle: const Text('Sync tasks with Google Calendar'),
            trailing: gcal.isSignedIn
                ? TextButton(onPressed: gcal.signOut, child: const Text('Disconnect'))
                : FilledButton(onPressed: gcal.signIn, child: const Text('Connect')),
          ),
          const Divider(),
          const ListTile(title: Text('AI Description', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'OpenAI API Key',
                hintText: 'sk-...',
                suffixIcon: _hasApiKey
                    ? IconButton(icon: const Icon(Icons.delete), onPressed: _deleteKey)
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton(onPressed: _saveKey, child: const Text('Save API Key')),
          ),
          const Divider(),
          const ListTile(
            title: Text('Cloud Sync', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Firebase sync — configure in Task 14'),
          ),
        ],
      ),
    );
  }
}
