import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/screens/past_appointment_screen.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/screens/pending_appointment_screen.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/screens/upcoming_appointment_screen.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class AppointmentScreen extends HookConsumerWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 3);
    final currentTabIndex = useState(0);

    useEffect(() {
      void listener() {
        currentTabIndex.value = tabController.index;
      }

      tabController.addListener(listener);

      return () {
        tabController.removeListener(listener);
      };
    }, [tabController]);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'my_appointments'.tr(),
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.TEXT_COLOR,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push(AppRoutes.notification);
                    },
                    child: Image.asset(
                      AppImages.NOTIFICATION_ICON,
                      height: 30.h,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // TabBar
              TabBar(
                controller: tabController,
                indicatorColor: AppTheme.BLUE_COLOR,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.manrope(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.TEXT_COLOR,
                ),
                tabs: [
                  Tab(text: 'upcoming'.tr()),
                  Tab(text: 'past'.tr()),
                  Tab(text: 'pending'.tr()),
                ],
              ),

              SizedBox(height: 16.h),

              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: const [
                    UpcomingAppointmentScreen(),
                    PastAppointmentScreen(),
                    PendingAppointmentScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
