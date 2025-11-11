import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/screens/appointment_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/home_screen.dart';
import 'package:repairando_mobile/src/features/messages/presentation/screens/my_messages_screen.dart';
import 'package:repairando_mobile/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class BottomNavScreen extends HookConsumerWidget {
  const BottomNavScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    List<Widget> screens = <Widget>[
      HomeScreen(),
      AppointmentScreen(),
      MyMessagesScreen(backButton: false),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: screens[selectedIndex.value],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.BACKGROUND_COLOR,
        currentIndex: selectedIndex.value,
        onTap: (index) {
          selectedIndex.value = index;
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.PRIMARY_COLOR,
        selectedLabelStyle: GoogleFonts.manrope(
          color: AppTheme.PRIMARY_COLOR,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        elevation: 0,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.all(5.0),
              child: Image.asset(AppImages.HOME, height: 25.h),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.all(5.0),
              child: Image.asset(AppImages.SELECTED_HOME, height: 25.h),
            ),
            label: 'home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.all(5.0),
              child: Image.asset(AppImages.APPOINTMENT, height: 25.h),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.all(5.0),
              child: Image.asset(AppImages.SELECTED_APPOINTMENT, height: 25.h),
            ),
            label: 'appointments'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.all(5.0),
              child: Image.asset(AppImages.MESSSGES, height: 25.h),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.all(5.0),
              child: Image.asset(AppImages.SELECTED_MESSAGE, height: 25.h),
            ),
            label: 'messages'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.all(5.0),
              child: Image.asset(AppImages.PROFILE, height: 25.h),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.all(5.0),
              child: Image.asset(AppImages.SELECTED_PROFILE, height: 25.h),
            ),
            label: 'profile'.tr(),
          ),
        ],
      ),
    );
  }
}
