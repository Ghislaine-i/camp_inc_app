import 'package:campus_incident_app/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('rejects empty', () => expect(Validators.email(''), isNotNull));
    test('rejects malformed', () => expect(Validators.email('abc@'), isNotNull));
    test('accepts valid', () => expect(Validators.email('a.b@uni.edu'), isNull));
  });

  group('password', () {
    test('rejects short', () => expect(Validators.password('123'), isNotNull));
    test('accepts 6+ chars', () => expect(Validators.password('abcdef'), isNull));
  });

  test('confirmPassword must match', () {
    expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    expect(Validators.confirmPassword('abc124', 'abc123'), isNotNull);
  });

  group('title', () {
    test('too short', () => expect(Validators.title('abc'), isNotNull));
    test('too long', () => expect(Validators.title('a' * 81), isNotNull));
    test('ok', () => expect(Validators.title('Broken tap'), isNull));
  });

  group('description', () {
    test('too short', () => expect(Validators.description('short'), isNotNull));
    test('ok', () => expect(Validators.description('The tap in block B is leaking'), isNull));
  });

  test('location required', () {
    expect(Validators.location('  '), isNotNull);
    expect(Validators.location('Block A'), isNull);
  });
}
