import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final workshopRepositoryProvider = Provider<WorkshopRepository>((ref) {
  final supabase = Supabase.instance.client;
  return WorkshopRepository(supabase);
});

class WorkshopRepository {
  final SupabaseClient _client;

  WorkshopRepository(this._client);

  Future<List<WorkshopModel>> fetchWorkshops() async {
    try {
      final response = await _client.from('admin').select();

      return response.map((json) => WorkshopModel.fromJson(json)).toList();
        } catch (e) {
      throw Exception('fetch_workshops_failed'.tr());
    }
  }
}
