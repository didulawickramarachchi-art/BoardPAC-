import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/access_repository.dart';
import '../model/access_validation_model.dart';

final accessRepositoryProvider = Provider<AccessRepository>((ref) {
  return AccessRepository(ref.read(dioProvider));
});

final accessValidationProvider =
    FutureProvider.family<
      AccessValidationModel,
      ({int userId, String channel})
    >((ref, args) async {
      return ref
          .read(accessRepositoryProvider)
          .validate(userId: args.userId, channel: args.channel);
    });
