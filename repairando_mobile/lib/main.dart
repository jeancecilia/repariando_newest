import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/app.dart';
import 'package:repairando_mobile/src/infra/supabase_provider.dart'
    show SupabaseConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseConfig.initialize();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('de', 'DE')],
      path: 'assets/translation',
      fallbackLocale: Locale('de', 'DE'),
      child: const ProviderScope(child: RepariandoApp()),
    ),
  );
}
