import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/model/login_response.dart';

void main() {
  group('LoginResponse account status', () {
    test('recognizes deactivated account status aliases', () {
      expect(
        LoginResponse.fromJson({'status': ' deactivated '}).isDeactivated,
        isTrue,
      );
      expect(
        LoginResponse.fromJson({'userStatus': 'INACTIVE'}).isDeactivated,
        isTrue,
      );
    });

    test('reads status from a nested user response', () {
      final response = LoginResponse.fromJson({
        'user': {'status': 'DEACTIVATED'},
      });

      expect(response.isDeactivated, isTrue);
    });

    test('does not reject active or unspecified account status', () {
      expect(LoginResponse.fromJson({'status': 'ACTIVE'}).isDeactivated, isFalse);
      expect(LoginResponse.fromJson({}).isDeactivated, isFalse);
    });
  });
}
