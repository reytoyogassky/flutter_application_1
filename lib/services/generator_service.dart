import 'dart:math';

class GeneratorService {
  static const String _nums = '23456789';
  static final Random _random = Random();

  static List<Map<String, String>> generate(int qty, {int length = 6}) {
    final seen = <String>{};
    final result = <Map<String, String>>[];
    int attempts = 0;

    while (result.length < qty && attempts < qty * 30) {
      attempts++;
      final code = List.generate(length, (_) => _nums[_random.nextInt(_nums.length)]).join();
      if (seen.contains(code)) continue;
      seen.add(code);
      result.add({'username': code, 'password': code});
    }

    return result;
  }
}
