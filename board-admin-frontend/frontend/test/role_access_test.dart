import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/role_access.dart';

void main() {
  test('admin manages privileges instead of secretary', () {
    expect(const RoleAccess('SECRETARY').canManagePrivileges, isFalse);
    expect(const RoleAccess('ADMIN').canManagePrivileges, isTrue);
    expect(const RoleAccess('MEMBER').canManagePrivileges, isFalse);
  });

  test('admin manages categories and subcategories instead of secretary', () {
    const admin = RoleAccess('ADMIN');
    const secretary = RoleAccess('SECRETARY');

    expect(admin.canManageCategories, isTrue);
    expect(admin.canManageSubcategories, isTrue);
    expect(secretary.canManageCategories, isFalse);
    expect(secretary.canManageSubcategories, isFalse);
  });
}
