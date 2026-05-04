import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../data/subcategory_repository.dart';
import '../model/subcategory_model.dart';

final subcategoryRepositoryProvider = Provider<SubcategoryRepository>((ref) {
  return SubcategoryRepository(ref.read(dioProvider));
});

final subcategoryListProvider =
    FutureProvider<List<SubcategoryModel>>((ref) async {
  return ref.read(subcategoryRepositoryProvider).getSubcategories();
});