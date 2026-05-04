import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/pack_delivery_repository.dart';
import '../model/pack_delivery_model.dart';

final packDeliveryRepositoryProvider = Provider<PackDeliveryRepository>((ref) {
  return PackDeliveryRepository(ref.read(dioProvider));
});

final packDeliveryByPaperProvider = FutureProvider.family<List<PackDeliveryModel>, int>((ref, paperId) async {
  return ref.read(packDeliveryRepositoryProvider).getByPaper(paperId);
});

final packDeliveryByUserProvider = FutureProvider.family<List<PackDeliveryModel>, int>((ref, userId) async {
  return ref.read(packDeliveryRepositoryProvider).getByUser(userId);
});