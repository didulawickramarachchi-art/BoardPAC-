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
      expect(
        LoginResponse.fromJson({'status': 'ACTIVE'}).isDeactivated,
        isFalse,
      );
      expect(LoginResponse.fromJson({}).isDeactivated, isFalse);
    });
  });

  group('LoginResponse device approval status', () {
    test('recognizes pending device aliases', () {
      expect(
        LoginResponse.fromJson({
          'deviceStatus': 'PENDING',
          'requiresTwoFactor': false,
        }).requiresDeviceApproval,
        isTrue,
      );
      expect(
        LoginResponse.fromJson({
          'device': {'status': 'AWAITING_APPROVAL'},
          'requiresTwoFactor': false,
        }).requiresDeviceApproval,
        isTrue,
      );
    });

    test('does not reject an approved device', () {
      expect(
        LoginResponse.fromJson({
          'deviceApprovalStatus': 'APPROVED',
          'requiresTwoFactor': false,
        }).requiresDeviceApproval,
        isFalse,
      );
    });
  });
}
