class VoucherResult {
  final int index;
  final String username;
  final bool mikrotikOk;
  final bool supabaseOk;
  final String message;

  VoucherResult({
    required this.index,
    required this.username,
    required this.mikrotikOk,
    required this.supabaseOk,
    required this.message,
  });
}

class LogEntry {
  final DateTime time;
  final String message;

  LogEntry({DateTime? time, required this.message}) : time = time ?? DateTime.now();
}
