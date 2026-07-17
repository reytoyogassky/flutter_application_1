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
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '10');
    _pkgCtrl = TextEditingController(text: _packageName);
    _profileCtrl = TextEditingController(text: _profile);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadSettings().then((_) {
        _profileCtrl.text = state.profile;
        _profile = state.profile;
        state.checkMikrotik();
        state.checkSupabase();
      });
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.confirmation_number, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WiFiSekre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Voucher Generator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusSection(state),
            const SizedBox(height: 16),
            _buildGeneratorCard(state),
            const SizedBox(height: 16),
            if (state.results.isNotEmpty) _buildResultsSection(state),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: state.logs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showLogsBottomSheet(context, state),
              icon: const Icon(Icons.article_outlined),
              label: const Text('View Logs'),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7C3AED),
            )
          : null,
    );
  }

  Widget _buildStatusSection(AppState state) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatusCard('MikroTik', state.mtkConnected, Icons.router)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatusCard('Supabase', state.supaConnected, Icons.cloud_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, bool connected, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: connected ? const Color(0xFF10B981) : Colors.grey, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: connected ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? const Color(0xFF10B981) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  connected ? 'Connected' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: connected ? const Color(0xFF10B981) : Colors.grey,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle_outline, color: Color(0xFF7C3AED), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Generate Vouchers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _qty,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.format_list_numbered, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: [5, 10, 25, 50, 100, 200].map((qty) {
                            return DropdownMenuItem(value: qty, child: Text('$qty vouchers'));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _qty = val ?? 10;
                              _qtyCtrl.text = _qty.toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: state.availableProfiles.contains(_profile) ? _profile : state.availableProfiles.first,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: state.availableProfiles.map((prof) {
                            return DropdownMenuItem(value: prof, child: Text(prof));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _profile = val ?? 'APLIKASI';
                              _profileCtrl.text = _profile;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Package Name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pkgCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g., 5 Jam 1000',
                  prefixIcon: Icon(Icons.label_outline, size: 20),
                ),
                onChanged: (v) => _packageName = v,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: state.generating
                      ? null
                      : () => state.generate(
                            qty: _qty,
                            packageName: _packageName,
                            profile: _profile,
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: state.generating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Text('Generating...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch, size: 20),
                            SizedBox(width: 8),
                            Text('GENERATE & SYNC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection(AppState state) {
    final successCount = state.results.where((r) => r.mikrotikOk && r.supabaseOk).length;
    final totalCount = state.results.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: successCount == totalCount ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$successCount/$totalCount Success',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = state.results[i];
              return _buildResultCard(r);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(VoucherResult result) {
    final isSuccess = result.mikrotikOk && result.supabaseOk;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSuccess ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${result.index}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            result.username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: result.username));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Username copied!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.message,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildStatusBadge('MT', result.mikrotikOk),
                    const SizedBox(width: 6),
                    _buildStatusBadge('DB', result.supabaseOk),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.article, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 12),
                    const Text(
                      'Generation Logs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${state.logs.length} entries',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
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
                          Text(
                            '[$timeStr]',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.message,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status badges
          _statusRow(state),
          // Form
          _formSection(state),
          // Generate button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: state.generating ? null : () => state.generate(
                  qty: _qty, packageName: _packageName, profile: _profile,
                ),
                icon: state.generating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(state.generating ? 'Generating...' : 'GENERATE & SYNC'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Results + Log tabs
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xFF7C3AED),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Results', icon: Icon(Icons.list, size: 18)),
                      Tab(text: 'Log', icon: Icon(Icons.terminal, size: 18)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _resultsTab(state),
                        _logTab(state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statusChip('MikroTik', state.mtkConnected, const Color(0xFF22C55E), Colors.grey),
          const SizedBox(width: 8),
          _statusChip('Supabase', state.supaConnected, const Color(0xFF3B82F6), Colors.grey),
          const Spacer(),
          TextButton.icon(
            onPressed: () => state.fetchProfiles(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Profiles', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool connected, Color onColor, Color offColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: connected ? onColor.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: connected ? onColor : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? onColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: connected ? onColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formSection(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onChanged: (v) => _qty = (int.tryParse(v) ?? 10).clamp(1, 500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pkgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Package Name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onChanged: (v) => _packageName = v,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (text) {
                        final q = text.text.toLowerCase();
                        return state.availableProfiles.where((p) => p.toLowerCase().contains(q));
                      },
                      initialValue: TextEditingValue(text: state.profile),
                      onSelected: (v) => _profile = v,
                      fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                        _profileCtrl = ctrl;
                        return TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Profile',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          onChanged: (v) => _profile = v,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => state.fetchProfiles(),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Fetch profiles',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultsTab(AppState state) {
    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No results yet', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.results.length,
      itemBuilder: (_, i) {
        final r = state.results[i];
        return Card(
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: r.mikrotikOk && r.supabaseOk
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              child: Text('${r.index}', style: TextStyle(
                fontWeight: FontWeight.bold,
                color: r.mikrotikOk && r.supabaseOk ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 13,
              )),
            ),
            title: Text(r.username, style: const TextStyle(
              fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(r.message, style: TextStyle(
              fontSize: 12, color: Colors.grey.shade600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _resultIcon(r.mikrotikOk, 'MT'),
                const SizedBox(width: 8),
                _resultIcon(r.supabaseOk, 'DB'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.article, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 12),
                    const Text(
                      'Generation Logs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${state.logs.length} entries',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
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
                          Text(
                            '[$timeStr]',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.message,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
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
