import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/app.dart';
import 'package:repairando_web/src/infra/supabase_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await dotenv.load(fileName: ".env");
  await SupabaseConfig.initialize();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en', 'US')],
      path: 'assets/translation',
      fallbackLocale: Locale('en', 'US'),
      child: const ProviderScope(child: RepariandoWeb()),
    ),
  );
}
