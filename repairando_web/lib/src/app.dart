import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:repairando_web/src/constants/app_constants.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RepariandoWeb extends HookConsumerWidget {
  const RepariandoWeb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: AppConstants.APP_NAME,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
