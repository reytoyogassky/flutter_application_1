import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/voucher_result.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _pkgCtrl;
  late TextEditingController _profileCtrl;
  int _qty = 10;
  String _packageName = '5 Jam 1000';
  String _profile = 'APLIKASI';
  int _logoTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '10');
    _pkgCtrl = TextEditingController(text: _packageName);
    _profileCtrl = TextEditingController(text: _profile);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      _profileCtrl.text = state.profile;
      _profile = state.profile;
    });
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _pkgCtrl.dispose();
    _profileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: GestureDetector(
          onTap: _onLogoTap,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.confirmation_number, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WiFiSekre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Generator Voucher', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        actions: const [SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildStatusSection(state),
            const SizedBox(height: 20),
            _buildGeneratorCard(state),
            const SizedBox(height: 20),
            if (state.results.isNotEmpty) _buildResultsSection(state),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: state.logs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showLogsBottomSheet(context, state),
              icon: const Icon(Icons.article_outlined),
              label: const Text('Lihat Log'),
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _onLogoTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 3)) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    _lastTapTime = now;
    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _showAdminPasswordDialog();
    }
  }

  void _showAdminPasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Admin Access', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter admin password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (passwordController.text == 'admin123') {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password salah!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(AppState state) {
    final bool anyDisconnected = !state.mtkConnected || !state.supaConnected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatusCard('MikroTik', state.mtkConnected, Icons.router)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusCard('Supabase', state.supaConnected, Icons.cloud_outlined)),
            ],
          ),
          if (anyDisconnected) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Masalah koneksi terdeteksi. Hubungi admin jika masalah berlanjut.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, bool connected, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: connected
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFEF4444).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: connected ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 32),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  connected ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorCard(AppState state) {
    final bool canGenerate = state.mtkConnected && state.supaConnected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Generate Voucher', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Buat banyak voucher secara instan', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!canGenerate) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Koneksi Diperlukan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('MikroTik dan Supabase harus terhubung untuk generate voucher', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Text('Jumlah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)), SizedBox(width: 4), Text('*', style: TextStyle(color: Color(0xFFEF4444)))]),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.format_list_numbered, size: 20, color: Color(0xFF8B5CF6)),
                          hintText: '1 - 500',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (v) {
                          int? val = int.tryParse(v);
                          if (val != null) {
                            if (val > 500) { _qtyCtrl.text = '500'; _qty = 500; }
                            else if (val < 1 && v.isNotEmpty) { _qtyCtrl.text = '1'; _qty = 1; }
                            else { _qty = val; }
                          } else if (v.isEmpty) { _qty = 1; }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Text('Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)), SizedBox(width: 4), Text('*', style: TextStyle(color: Color(0xFFEF4444)))]),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: state.availableProfiles.contains(_profile) ? _profile : state.availableProfiles.first,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined, size: 20, color: Color(0xFF8B5CF6)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: state.availableProfiles.map((prof) => DropdownMenuItem(value: prof, child: Text(prof))).toList(),
                        onChanged: (val) { setState(() { _profile = val ?? 'APLIKASI'; _profileCtrl.text = _profile; }); },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Text('Nama Paket', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)), SizedBox(width: 4), Text('*', style: TextStyle(color: Color(0xFFEF4444)))]),
                const SizedBox(height: 10),
                TextField(
                  controller: _pkgCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'cth: 5 Jam 1000',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.label_outline, size: 20, color: Color(0xFF8B5CF6)),
                  ),
                  onChanged: (v) => _packageName = v,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 56,
              child: FilledButton(
                onPressed: (state.generating || !canGenerate)                     ? null : () => state.generate(qty: _qty, packageName: _packageName, profile: _profile),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  disabledBackgroundColor: const Color(0xFF334155),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: state.generating
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)), SizedBox(width: 14), Text('Generating...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))])
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.rocket_launch, size: 22), const SizedBox(width: 10), Text(canGenerate ? 'GENERATE & SYNC' : 'CONNECTION REQUIRED', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(AppState state) {
    final successCount = state.results.where((r) => r.mikrotikOk && r.supabaseOk).length;
    final totalCount = state.results.length;
    final successRate = totalCount > 0 ? (successCount / totalCount * 100).toStringAsFixed(0) : '0';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: successCount == totalCount
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hasil Generate', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('voucher berhasil dibuat', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text('$successRate%', style: TextStyle(color: successCount == totalCount ? const Color(0xFF059669) : const Color(0xFFD97706), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text('$successCount/$totalCount', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildResultCard(state.results[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(VoucherResult result) {
    final isSuccess = result.mikrotikOk && result.supabaseOk;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFEF4444).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSuccess ? [const Color(0xFF10B981), const Color(0xFF059669)] : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('#${result.index}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(result.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace', letterSpacing: 0.5, color: Colors.white))),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: IconButton(
                            icon: const Icon(Icons.copy, size: 18, color: Color(0xFF8B5CF6)),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: result.username));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width: 12), Text('Username disalin!')]),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(isSuccess ? Icons.check_circle : Icons.error, size: 14, color: isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(result.message, style: TextStyle(fontSize: 12, color: Colors.grey.shade400))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatusBadge('MikroTik', result.mikrotikOk)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusBadge('Supabase', result.supabaseOk)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ok ? [const Color(0xFF10B981), const Color(0xFF059669)] : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  void _showLogsBottomSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.article, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 12),
                    const Text('Log Generate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Spacer(),
                    Text('${state.logs.length} entri', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const Divider(height: 24, color: Color(0xFF334155)),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.logs.length,
                  itemBuilder: (_, i) {
                    final log = state.logs[i];
                    final timeStr = DateFormat('HH:mm:ss').format(log.time);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('[$timeStr]', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(log.message, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
