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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Pengaturan berhasil disimpan!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Pengaturan Admin', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF713F12).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Area Admin',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pengaturan ini terkunci untuk pengguna biasa. Perubahan akan memengaruhi semua instalasi aplikasi.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Konfigurasi MikroTik',
            icon: Icons.router,
            color: const Color(0xFF7C3AED),
            children: [
              const SizedBox(height: 16),
              _buildTextField('Host', _hostCtrl, hint: '11.11.11.1', icon: Icons.dns),
              const SizedBox(height: 12),
              _buildTextField('Port', _portCtrl, hint: '8728', icon: Icons.settings_ethernet, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField('Username', _userCtrl, hint: 'superadmin', icon: Icons.person_outline),
              const SizedBox(height: 12),
              _buildPasswordField('Password', _passCtrl, _showPass, () => setState(() => _showPass = !_showPass)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => state.checkMikrotik(),
                  icon: Icon(state.mtkConnected ? Icons.check_circle : Icons.wifi_find, size: 20),
                  label: Text(state.mtkConnected ? 'MikroTik Terhubung ✓' : 'Uji Koneksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.mtkConnected ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Konfigurasi Supabase',
            icon: Icons.cloud_outlined,
            color: const Color(0xFF3B82F6),
            children: [
              const SizedBox(height: 16),
              _buildTextField('URL', _supaUrlCtrl, hint: 'https://xxx.supabase.co', icon: Icons.link),
              const SizedBox(height: 12),
                  _buildPasswordField('Service Role Key', _supaKeyCtrl, _showKey, () => setState(() => _showKey = !_showKey)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => state.checkSupabase(),
                  icon: Icon(state.supaConnected ? Icons.check_circle : Icons.cloud_sync, size: 20),
                  label: Text(state.supaConnected ? 'Supabase Terhubung ✓' : 'Uji Koneksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.supaConnected ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Pengaturan Default',
            icon: Icons.tune,
            color: const Color(0xFF6B7280),
            children: [
              const SizedBox(height: 16),
              _buildTextField('Profile Default', _profileCtrl, hint: 'APLIKASI', icon: Icons.badge_outlined),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, size: 20),
              label: const Text('Simpan Pengaturan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF8B5CF6)) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '••••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF8B5CF6)),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, size: 20, color: Colors.grey),
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tentang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAboutRow('Versi', '1.0.0'),
          const Divider(height: 20, color: Color(0xFF334155)),
          _buildAboutRow('Build', '2026.07.17'),
          const Divider(height: 20, color: Color(0xFF334155)),
          _buildAboutRow('Developer', 'WiFiSekre.net'),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}
