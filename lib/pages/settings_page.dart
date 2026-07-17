import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _supaUrlCtrl;
  late TextEditingController _supaKeyCtrl;
  late TextEditingController _profileCtrl;
  bool _showPass = false;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController();
    _portCtrl = TextEditingController(text: '8728');
    _userCtrl = TextEditingController();
    _passCtrl = TextEditingController();
    _supaUrlCtrl = TextEditingController();
    _supaKeyCtrl = TextEditingController();
    _profileCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      _hostCtrl.text = state.mikrotikHost;
      _portCtrl.text = state.mikrotikPort.toString();
      _userCtrl.text = state.mikrotikUser;
      _passCtrl.text = state.mikrotikPass;
      _supaUrlCtrl.text = state.supabaseUrl;
      _supaKeyCtrl.text = state.supabaseKey;
      _profileCtrl.text = state.defaultProfile;
    });
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _supaUrlCtrl.dispose();
    _supaKeyCtrl.dispose();
    _profileCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final state = context.read<AppState>();
    state.saveSettings(
      host: _hostCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text.trim()) ?? 8728,
      user: _userCtrl.text.trim(),
      pass: _passCtrl.text,
      supabaseUrl: _supaUrlCtrl.text.trim(),
      supabaseKey: _supaKeyCtrl.text.trim(),
      profile: _profileCtrl.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('MIKROTIK'),
          const SizedBox(height: 8),
          _field('Host', _hostCtrl, hint: '11.11.11.1'),
          _field('Port', _portCtrl, hint: '8728', keyboardType: TextInputType.number),
          _field('Username', _userCtrl, hint: 'superadmin'),
          _passwordField('Password', _passCtrl, _showPass, () => setState(() => _showPass = !_showPass)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => state.checkMikrotik(),
            icon: Icon(state.mtkConnected ? Icons.check_circle : Icons.wifi, color: Colors.white),
            label: Text(state.mtkConnected ? 'MikroTik Connected' : 'Test Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.mtkConnected ? Colors.green : Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          _section('SUPABASE'),
          const SizedBox(height: 8),
          _field('URL', _supaUrlCtrl, hint: 'https://xxx.supabase.co'),
          _passwordField('Service Role Key', _supaKeyCtrl, _showKey, () => setState(() => _showKey = !_showKey)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => state.checkSupabase(),
            icon: Icon(state.supaConnected ? Icons.check_circle : Icons.cloud, color: Colors.white),
            label: Text(state.supaConnected ? 'Supabase Connected' : 'Test Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.supaConnected ? Colors.green : Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          _section('DEFAULT'),
          const SizedBox(height: 8),
          _field('Profile', _profileCtrl, hint: 'APLIKASI'),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(title, style: TextStyle(
      fontSize: 13, fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
      letterSpacing: 1,
    ));
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController ctrl,
      bool obscure, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        obscureText: !obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
