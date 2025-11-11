import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/auth/data/auth_repository.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationController = useAnimationController(
      duration: AppTheme.SPLASH_ANIMATION_DURATION,
    );

    final fadeAnimation = useMemoized(
      () => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      ),
      [animationController],
    );

    final scaleAnimation = useMemoized(
      () => Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.elasticOut),
      ),
      [animationController],
    );

    useEffect(() {
      animationController.forward();

      Future.delayed(Duration(milliseconds: AppTheme.SPLASH_DURATION), () {
        final authRepository = ref.read(authRepositoryProvider);
        final hasSession = authRepository.isAuthenticated;

        if (context.mounted) {
          if (hasSession) {
            context.go(AppRoutes.bottomNav); // If session exists
          } else {
            context.go(AppRoutes.welcome); // If not logged in
          }
        }
      });

      return null;
    }, [animationController]);

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: Center(
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppImages.SPLASH_LOGO,
                      height: AppTheme.SPLASH_LOGO_WDITH,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
