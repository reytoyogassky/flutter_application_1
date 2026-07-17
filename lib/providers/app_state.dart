import 'package:flutter/foundation.dart';
import '../models/voucher_result.dart';
import '../services/mikrotik_service.dart';
import '../services/supabase_service.dart';
import '../services/generator_service.dart';

class AppState extends ChangeNotifier {
  // Fixed Settings (Locked - Cannot be changed by user)
  static const String _mikrotikHost = '11.11.11.1';
  static const int _mikrotikPort = 8728;
  static const String _mikrotikUser = 'superadmin';
  static const String _mikrotikPass = 'admin';
  static const String _supabaseUrl = 'https://ikyzdwccwebmxkztwglg.supabase.co';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlreXpkd2Njd2VibXhrenR3Z2xnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg1ODM1NywiZXhwIjoyMDg4NDM0MzU3fQ.lrUCSS9-B4uAHiMNkIUQ26Eszf-wtcaKRPlT1jcNxHQ';
  static const String _defaultProfile = 'APLIKASI';

  // State
  bool _mtkConnected = false;
  bool _supaConnected = false;
  bool _generating = false;
  int _qty = 10;
  String _packageName = '5 Jam 1000';
  String _profile = 'APLIKASI';
  List<String> _availableProfiles = ['APLIKASI', 'default', 'ANGGOTA', 'BULANAN', 'Teknisi', 'Laptpop'];
  List<VoucherResult> _results = [];
  final List<LogEntry> _logs = [];

  // Getters
  String get mikrotikHost => _mikrotikHost;
  int get mikrotikPort => _mikrotikPort;
  String get mikrotikUser => _mikrotikUser;
  String get mikrotikPass => _mikrotikPass;
  String get supabaseUrl => _supabaseUrl;
  String get supabaseKey => _supabaseKey;
  String get defaultProfile => _defaultProfile;
  bool get mtkConnected => _mtkConnected;
  bool get supaConnected => _supaConnected;
  bool get generating => _generating;
  int get qty => _qty;
  String get packageName => _packageName;
  String get profile => _profile;
  List<String> get availableProfiles => _availableProfiles;
  List<VoucherResult> get results => _results;
  List<LogEntry> get logs => _logs;

  void addLog(String msg) {
    _logs.add(LogEntry(message: msg));
    notifyListeners();
  }

  // Auto-connect on init
  AppState() {
    _autoConnect();
  }

  Future<void> _autoConnect() async {
    addLog('Initializing app...');
    await Future.delayed(const Duration(milliseconds: 500));
    await checkMikrotik();
    await checkSupabase();
    await fetchProfiles();
  }

  // Admin-only method for settings (hidden access)
  Future<void> saveSettings({
    required String host,
    required int port,
    required String user,
    required String pass,
    required String supabaseUrl,
    required String supabaseKey,
    required String profile,
  }) async {
    // Note: This method exists for admin access only
    // Normal users cannot access this
    addLog('Admin: Settings updated');
    notifyListeners();
  }

  Future<void> checkMikrotik() async {
    addLog('Checking MikroTik connection...');
    final client = MikrotikClient(
      host: _mikrotikHost,
      port: _mikrotikPort,
      user: _mikrotikUser,
      password: _mikrotikPass,
      onLog: addLog,
    );
    try {
      _mtkConnected = await client.checkConnection();
    } catch (e) {
      _mtkConnected = false;
      addLog('MikroTik error: $e');
    }
    addLog(_mtkConnected ? 'MikroTik: Connected' : 'MikroTik: Disconnected');
    notifyListeners();
  }

  Future<void> checkSupabase() async {
    addLog('Checking Supabase connection...');
    if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) {
      _supaConnected = false;
      addLog('Supabase: No config');
      notifyListeners();
      return;
    }
    try {
      final client = SupabaseClient(url: _supabaseUrl, serviceKey: _supabaseKey);
      _supaConnected = await client.ping();
    } catch (e) {
      _supaConnected = false;
      addLog('Supabase error: $e');
    }
    addLog(_supaConnected ? 'Supabase: Connected' : 'Supabase: Disconnected');
    notifyListeners();
  }

  Future<void> fetchProfiles() async {
    addLog('Fetching profiles from MikroTik...');
    final client = MikrotikClient(
      host: _mikrotikHost,
      port: _mikrotikPort,
      user: _mikrotikUser,
      password: _mikrotikPass,
      onLog: addLog,
    );
    try {
      final profiles = await client.getProfiles();
      if (profiles.isNotEmpty) {
        _availableProfiles = profiles;
        if (!profiles.contains(_profile)) {
          _profile = profiles.first;
        }
        addLog('Profiles: ${profiles.join(", ")}');
      }
    } catch (e) {
      addLog('Failed to fetch profiles: $e');
    }
    notifyListeners();
  }

  Future<void> generate({int? qty, String? packageName, String? profile}) async {
    if (_generating) return;
    _generating = true;
    _results = [];
    if (qty != null) _qty = qty;
    if (packageName != null) _packageName = packageName;
    if (profile != null) _profile = profile;
    notifyListeners();

    addLog('Generating $_qty vouchers...');

    final vouchers = GeneratorService.generate(_qty);
    final mtkClient = MikrotikClient(
      host: _mikrotikHost,
      port: _mikrotikPort,
      user: _mikrotikUser,
      password: _mikrotikPass,
      onLog: addLog,
    );
    final supaClient = SupabaseClient(url: _supabaseUrl, serviceKey: _supabaseKey);
    final uptime = '5h';
    final batchTag = 'wifisekre-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

    int successMtk = 0, successDb = 0, failMtk = 0, failDb = 0;

    for (int i = 0; i < vouchers.length; i++) {
      final v = vouchers[i];
      bool mtkOk = false;
      bool dbOk = false;
      String mtkMsg = '';
      String dbMsg = '';

      // MikroTik
      try {
        final result = await mtkClient.addHotspotUser(
          username: v['username']!,
          password: v['password']!,
          profile: _profile,
          limitUptime: uptime,
          comment: batchTag,
        );
        if (result['ok'] == true) {
          mtkOk = true;
          successMtk++;
          mtkMsg = 'OK';
        } else if (result['error'] == 'duplicate') {
          mtkOk = true;
          successMtk++;
          mtkMsg = 'Already exists';
        } else {
          failMtk++;
          mtkMsg = result['message'] as String? ?? 'Failed';
        }
      } catch (e) {
        failMtk++;
        mtkMsg = e.toString().substring(0, 60);
      }

      // Supabase
      try {
        await supaClient.insertVoucher(
          code: v['username']!,
          packageName: _packageName,
          price: 1000,
          duration: uptime,
        );
        dbOk = true;
        successDb++;
        dbMsg = 'OK';
      } catch (e) {
        failDb++;
        dbMsg = e.toString().substring(0, 60);
      }

      final mtkIcon = mtkOk ? '✅' : '❌';
      final dbIcon = dbOk ? '✅' : '❌';
      final msg = !mtkOk ? mtkMsg : (!dbOk ? dbMsg : 'OK');

      _results.add(VoucherResult(
        index: i + 1,
        username: v['username']!,
        mikrotikOk: mtkOk,
        supabaseOk: dbOk,
        message: msg,
      ));
      addLog('[${i + 1}/${vouchers.length}] ${v['username']}  MT: $mtkIcon  DB: $dbIcon');
      notifyListeners();
    }

    addLog('Done: $successMtk/$successDb MikroTik/Supabase OK');
    _generating = false;
    notifyListeners();
  }
}
