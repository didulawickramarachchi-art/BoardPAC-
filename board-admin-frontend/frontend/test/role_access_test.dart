import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/role_access.dart';

void main() {
  test('secretary manages privileges instead of admin', () {
    expect(const RoleAccess('SECRETARY').canManagePrivileges, isTrue);
    expect(const RoleAccess('ADMIN').canManagePrivileges, isFalse);
    expect(const RoleAccess('MEMBER').canManagePrivileges, isFalse);
  });
}
