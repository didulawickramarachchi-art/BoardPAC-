import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/users/model/user_model.dart';

UserModel userWithStatus(String? status) => UserModel(
  id: 1,
  username: 'alex',
  firstName: 'Alex',
  lastName: 'Doe',
  email: 'alex@example.com',
  status: status,
);

void main() {
  test('reads the persisted two-factor setting from the user response', () {
    final user = UserModel.fromJson({
      'id': 1,
      'username': 'member',
      'firstName': 'Board',
      'lastName': 'Member',
      'email': 'member@example.com',
      'twoStepEnabled': true,
    });

    expect(user.twoStepEnabled, isTrue);
  });

  group('UserModel lifecycle status', () {
    test('recognizes active status without depending on casing', () {
      expect(userWithStatus(' active ').isActive, isTrue);
      expect(userWithStatus('DEACTIVATED').isActive, isFalse);
    });

    test('recognizes deactivated and inactive backend values', () {
      expect(userWithStatus('deactivated').isDeactivated, isTrue);
      expect(userWithStatus(' INACTIVE ').isDeactivated, isTrue);
      expect(userWithStatus('ACTIVE').isDeactivated, isFalse);
      expect(userWithStatus(null).isDeactivated, isFalse);
    });
  });
}
