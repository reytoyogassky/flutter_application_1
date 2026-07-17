import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voucher_result.dart';
import '../services/mikrotik_service.dart';
import '../services/supabase_service.dart';
import '../services/generator_service.dart';

class AppState extends ChangeNotifier {
  // Settings
  String _mikrotikHost = '11.11.11.1';
  int _mikrotikPort = 8728;
  String _mikrotikUser = 'superadmin';
  String _mikrotikPass = '';
  String _supabaseUrl = '';
  String _supabaseKey = '';
  String _defaultProfile = 'APLIKASI';

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

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _mikrotikHost = prefs.getString('mikrotik_host') ?? '11.11.11.1';
    _mikrotikPort = prefs.getInt('mikrotik_port') ?? 8728;
    _mikrotikUser = prefs.getString('mikrotik_user') ?? 'superadmin';
    _mikrotikPass = prefs.getString('mikrotik_pass') ?? '';
    _supabaseUrl = prefs.getString('supabase_url') ?? '';
    _supabaseKey = prefs.getString('supabase_key') ?? '';
    _defaultProfile = prefs.getString('default_profile') ?? 'APLIKASI';
    _profile = _defaultProfile;
    notifyListeners();
  }

  Future<void> saveSettings({
    required String host,
    required int port,
    required String user,
    required String pass,
    required String supabaseUrl,
    required String supabaseKey,
    required String profile,
  }) async {
    _mikrotikHost = host;
    _mikrotikPort = port;
    _mikrotikUser = user;
    _mikrotikPass = pass;
    _supabaseUrl = supabaseUrl;
    _supabaseKey = supabaseKey;
    _defaultProfile = profile;
    _profile = profile;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mikrotik_host', host);
    await prefs.setInt('mikrotik_port', port);
    await prefs.setString('mikrotik_user', user);
    await prefs.setString('mikrotik_pass', pass);
    await prefs.setString('supabase_url', supabaseUrl);
    await prefs.setString('supabase_key', supabaseKey);
    await prefs.setString('default_profile', profile);
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
