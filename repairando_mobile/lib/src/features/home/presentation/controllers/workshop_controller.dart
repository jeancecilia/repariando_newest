import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/home/data/workshop_repository.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 📦 Get all workshops from Supabase
final workshopsProvider =
    StateNotifierProvider<WorkshopController, AsyncValue<List<WorkshopModel>>>(
      (ref) => WorkshopController(ref),
    );

class WorkshopController
    extends StateNotifier<AsyncValue<List<WorkshopModel>>> {
  final Ref ref;
  final supabase = Supabase.instance.client;

  WorkshopController(this.ref) : super(const AsyncLoading()) {
    fetchWorkshops();
  }

  Future<void> fetchWorkshops() async {
    try {
      final repository = ref.read(workshopRepositoryProvider);
      final workshops = await repository.fetchWorkshops();
      state = AsyncValue.data(workshops);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 🔍 Search-related state providers
final searchInputProvider = StateProvider<String>((ref) => '');
final showSuggestionsBoxProvider = StateProvider<bool>((ref) => true);

final showSuggestionsProvider = Provider<bool>((ref) {
  final input = ref.watch(searchInputProvider);
  return input.trim().isNotEmpty;
});

// 🔎 Filtered list based on input
final filteredWorkshopsProvider = Provider<List<WorkshopModel>>((ref) {
  final input = ref.watch(searchInputProvider).toLowerCase().trim();
  final allWorkshopsAsync = ref.watch(workshopsProvider);

  return allWorkshopsAsync.when(
    data: (workshops) {
      if (input.isEmpty) return [];
      return workshops.where((w) {
        final name = (w.workshopName ?? '').toLowerCase();
        final desc = (w.shortDescription ?? '').toLowerCase();
        return name.contains(input) || desc.contains(input);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// 💡 Suggestions based on name or short description
final searchSuggestionsProvider = Provider<List<String>>((ref) {
  final input = ref.watch(searchInputProvider).toLowerCase().trim();
  final showBox = ref.watch(showSuggestionsBoxProvider);
  final allWorkshopsAsync = ref.watch(workshopsProvider);

  if (input.isEmpty || !showBox) return [];

  final Set<String> suggestions = {};

  allWorkshopsAsync.whenData((workshops) {
    for (final w in workshops) {
      final name = w.workshopName ?? '';
      final desc = w.shortDescription ?? '';

      if (name.toLowerCase().contains(input)) {
        suggestions.add(name);
      }

      for (final word in desc.split(',')) {
        if (word.toLowerCase().contains(input)) {
          suggestions.add(word.trim());
        }
      }
    }
  });

  final sorted = suggestions.toList()..sort();
  return sorted.take(6).toList();
});
