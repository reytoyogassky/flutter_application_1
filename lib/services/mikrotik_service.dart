import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class MikrotikError implements Exception {
  final String message;
  MikrotikError(this.message);
  @override
  String toString() => message;
}

class _SocketReader {
  final StreamIterator<Uint8List> _iterator;
  Uint8List? _current;
  int _offset = 0;

  _SocketReader(Socket socket) : _iterator = StreamIterator(socket);

  Future<int> readByte() async {
    if (_current == null || _offset >= _current!.length) {
      if (!await _iterator.moveNext()) throw MikrotikError('Connection closed');
      _current = _iterator.current;
      _offset = 0;
    }
    return _current![_offset++];
  }

  Future<Uint8List> readBytes(int count) async {
    final result = <int>[];
    while (result.length < count) {
      if (_current == null || _offset >= _current!.length) {
        if (!await _iterator.moveNext()) throw MikrotikError('Connection closed');
        _current = _iterator.current;
        _offset = 0;
      }
      final available = _current!.length - _offset;
      final needed = count - result.length;
      final take = available < needed ? available : needed;
      result.addAll(_current!.sublist(_offset, _offset + take));
      _offset += take;
    }
    return Uint8List.fromList(result);
  }
}

class MikrotikClient {
  final String host;
  final int port;
  final String user;
  final String password;
  final Duration timeout;
  final void Function(String)? onLog;

  Socket? _socket;

  MikrotikClient({
    required this.host,
    this.port = 8728,
    required this.user,
    required this.password,
    this.timeout = const Duration(seconds: 5),
    this.onLog,
  });

  void _log(String msg) {
    onLog?.call('[MikroTik] $msg');
  }

  List<int> _encodeLength(int length) {
    if (length < 0x80) {
      return [length];
    } else if (length < 0x4000) {
      length |= 0x8000;
      return [(length >> 8) & 0xFF, length & 0xFF];
    } else if (length < 0x200000) {
      length |= 0xC00000;
      return [(length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF];
    } else if (length < 0x10000000) {
      length |= 0xE0000000;
      return [
        (length >> 24) & 0xFF,
        (length >> 16) & 0xFF,
        (length >> 8) & 0xFF,
        length & 0xFF,
      ];
    } else {
      return [0xF0, (length >> 24) & 0xFF, (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF];
    }
  }

  Future<int> _readLength(_SocketReader reader) async {
    final b = await reader.readByte();
    if (b & 0x80 == 0) return b;

    if ((b & 0xC0) == 0x80) {
      final b2 = await reader.readByte();
      return ((b & 0x3F) << 8) | b2;
    } else if ((b & 0xE0) == 0xC0) {
      final b2 = await reader.readByte();
      final b3 = await reader.readByte();
      return ((b & 0x1F) << 16) | (b2 << 8) | b3;
    } else if ((b & 0xF0) == 0xE0) {
      final b2 = await reader.readByte();
      final b3 = await reader.readByte();
      final b4 = await reader.readByte();
      return ((b & 0x0F) << 24) | (b2 << 16) | (b3 << 8) | b4;
    } else {
      final raw = await reader.readBytes(4);
      return (raw[0] << 24) | (raw[1] << 16) | (raw[2] << 8) | raw[3];
    }
  }

  Future<void> _writeWord(String word) async {
    final data = utf8.encode(word);
    final header = _encodeLength(data.length);
    _socket!.add(header);
    _socket!.add(data);
    _log('SEND: [${data.length}] $word');
  }

  Future<void> _writeSentence(List<String> words) async {
    for (final word in words) {
      await _writeWord(word);
    }
    _socket!.add([0x00]);
    _log('SEND: [0] <EOS>');
    await _socket!.flush();
  }

  Future<List<String>> _readSentence(_SocketReader reader) async {
    final words = <String>[];
    while (true) {
      final length = await _readLength(reader);
      if (length == 0) break;
      final raw = await reader.readBytes(length);
      final word = utf8.decode(raw);
      _log('RECV: [${raw.length}] $word');
      words.add(word);
    }
    return words;
  }

  String _getMessage(List<String> sentence) {
    for (final w in sentence) {
      if (w.startsWith('=message=')) return w.substring(9);
      if (w.startsWith('=msg=')) return w.substring(5);
    }
    return 'Unknown error';
  }

  Future<void> _login(_SocketReader reader) async {
    _log('Attempting old-style login...');
    await _writeSentence(['/login', '=name=$user', '=password=$password']);
    final resp = await _readSentence(reader);

    if (resp.isEmpty) throw MikrotikError('Empty response from server');

    if (resp[0] == '!done' && resp.length == 1) {
      _log('Old-style login successful');
      return;
    }

    // Challenge-response
    String? challenge;
    for (final w in resp) {
      if (w.startsWith('=ret=')) {
        var raw = w.substring(5);
        if (raw.startsWith('00:')) raw = raw.substring(3);
        challenge = raw;
        break;
      }
    }

    if (challenge == null) {
      throw MikrotikError('Login failed: unexpected response $resp');
    }

    _log('Challenge received: ${challenge.substring(0, 32)}...');
    final binaryChallenge = _hexToBytes(challenge);
    final md5Input = Uint8List.fromList([0x00, ...utf8.encode(password), ...binaryChallenge]);
    final hash = md5.convert(md5Input).toString();

    _log('Sending challenge response...');
    await _writeSentence(['/login', '=name=$user', '=response=00$hash']);
    final loginResp = await _readSentence(reader);

    if (loginResp.isEmpty) throw MikrotikError('Empty response to challenge login');
    if (loginResp[0] == '!done') {
      _log('Challenge login successful');
      return;
    }

    throw MikrotikError('Challenge login failed: ${_getMessage(loginResp)}');
  }

  List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  Future<Map<String, dynamic>> command(String cmd, {Map<String, String>? params}) async {
    _log('Connecting to $host:$port...');
    _socket = await Socket.connect(host, port, timeout: timeout);
    _log('TCP connected');

    try {
      final reader = _SocketReader(_socket!);
      await _login(reader);

      final words = <String>[cmd];
      if (params != null) {
        params.forEach((k, v) => words.add('=$k=$v'));
      }
      _log('Executing: $cmd');
      await _writeSentence(words);

      final results = <Map<String, String>>[];
      while (true) {
        final resp = await _readSentence(reader);
        if (resp.isEmpty) break;
        final tag = resp[0];
        if (tag.startsWith('!done')) {
          _log('Command completed');
          break;
        } else if (tag.startsWith('!trap')) {
          final msg = _getMessage(resp);
          if (msg.toLowerCase().contains('already have') || msg.toLowerCase().contains('duplicate')) {
            _log('Duplicate entry: $msg');
            return {'ok': false, 'error': 'duplicate', 'data': results, 'message': msg};
          }
          throw MikrotikError(msg);
        } else if (tag.startsWith('!fatal')) {
          throw MikrotikError('Fatal: ${_getMessage(resp)}');
        } else if (tag.startsWith('!re')) {
          final entry = <String, String>{};
          for (final w in resp.skip(1)) {
            if (w.startsWith('=')) {
              final eq = w.indexOf('=', 1);
              if (eq > 0) {
                entry[w.substring(1, eq)] = w.substring(eq + 1);
              }
            }
          }
          results.add(entry);
        }
      }
      return {'ok': true, 'data': results};
    } finally {
      _socket?.close();
      _socket = null;
      _log('Connection closed');
    }
  }

  Future<bool> checkConnection() async {
    try {
      final result = await command('/system/identity/print');
      return result['ok'] == true;
    } catch (e) {
      _log('Connection check failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> addHotspotUser({
    required String username,
    required String password,
    String profile = 'default',
    String server = 'all',
    String? limitUptime,
    String? comment,
  }) async {
    final params = <String, String>{
      'name': username,
      'password': password,
      'profile': profile,
      'server': server,
      'disabled': 'no',
    };
    if (limitUptime != null) params['limit-uptime'] = limitUptime;
    if (comment != null) params['comment'] = comment;
    return command('/ip/hotspot/user/add', params: params);
  }

  Future<List<String>> getProfiles() async {
    final result = await command('/ip/hotspot/user/profile/print');
    if (result['ok'] == true) {
      final data = result['data'] as List<Map<String, String>>;
      return data.map((e) => e['name'] ?? '').where((n) => n.isNotEmpty).toList();
    }
    return [];
  }
}
