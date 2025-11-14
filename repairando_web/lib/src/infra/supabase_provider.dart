import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class SupabaseConfig {
  static String get url => 'https://irrcqqtubcxndjmjmokl.supabase.co';
  static String get anonKey =>
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlycmNxcXR1YmN4bmRqbWptb2tsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2OTAwNjYsImV4cCI6MjA2OTI2NjA2Nn0.YETb7x88_ouZmSFhyxNs8VGDQNlqcLgkf8LpW-LKbgg';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
  }
}
