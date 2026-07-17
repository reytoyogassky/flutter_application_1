import 'package:flutter/material.dart';
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
  final _logScrollCtrl = ScrollController();

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
    _logScrollCtrl.dispose();
    super.dispose();
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

  Widget _resultIcon(bool ok, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ok ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel,
               size: 14, color: ok ? Colors.green : Colors.red),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold,
            color: ok ? Colors.green.shade700 : Colors.red.shade700,
          )),
        ],
      ),
    );
  }

  Widget _logTab(AppState state) {
    if (state.logs.isEmpty) {
      return Center(
        child: Text('No logs', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView.builder(
      controller: _logScrollCtrl,
      padding: const EdgeInsets.all(8),
      itemCount: state.logs.length,
      itemBuilder: (_, i) {
        final log = state.logs[i];
        final timeStr = DateFormat('HH:mm:ss').format(log.time);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[$timeStr] ', style: TextStyle(
                fontSize: 11, fontFamily: 'monospace',
                color: Colors.grey.shade500,
              )),
              Expanded(
                child: Text(
                  log.message,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
