import 'package:flutter_test/flutter_test.dart';

bool isVersionLower(String current, String target) {
  List<int> currentParts = current.split('.').map(int.parse).toList();
  List<int> targetParts = target.split('.').map(int.parse).toList();

  for (int i = 0; i < targetParts.length; i++) {
    int currentPart = i < currentParts.length ? currentParts[i] : 0;
    if (currentPart < targetParts[i]) return true;
    if (currentPart > targetParts[i]) return false;
  }
  return false;
}

void main() {
  group('Version Comparison Logic', () {
    test('Should return true if current is lower (major)', () {
      expect(isVersionLower('1.0.0', '2.0.0'), isTrue);
    });

    test('Should return true if current is lower (minor)', () {
      expect(isVersionLower('1.1.0', '1.2.0'), isTrue);
    });

    test('Should return true if current is lower (patch)', () {
      expect(isVersionLower('1.1.1', '1.1.2'), isTrue);
    });

    test('Should return false if current is same', () {
      expect(isVersionLower('1.1.0', '1.1.0'), isFalse);
    });

    test('Should return false if current is higher', () {
      expect(isVersionLower('1.2.0', '1.1.5'), isFalse);
      expect(isVersionLower('2.0.0', '1.9.9'), isFalse);
    });

    test('Should handle mismatched lengths', () {
      expect(isVersionLower('1.1', '1.1.1'), isTrue);
      expect(isVersionLower('1.2.1', '1.2'), isFalse);
    });
  });
}
