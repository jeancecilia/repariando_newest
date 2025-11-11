import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_web/src/constants/app_constants.dart';
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/logout_controller.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/workshop_opening_controller.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/workshop_setting_controller.dart';
import 'package:repairando_web/src/features/home/domain/working_setting_model.dart';
import 'package:repairando_web/src/features/home/domain/workshop_opening_hour_model.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:repairando_web/src/widgets/custom_popup_menu.dart';

class WorkshopSettingsScreen extends HookConsumerWidget {
  const WorkshopSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(fetchWorkshopProfileControllerProvider);
    final updateState = ref.watch(updateWorkshopProfileControllerProvider);
    final openingHoursState = ref.watch(workshopOpeningControllerProvider);

    // Opening hours state
    final openingHours = useState<List<WorkshopOpeningHour>>([]);
    final currentUserId = useState<String?>(null);

    useEffect(() {
      Future.microtask(() {
        ref
            .read(fetchWorkshopProfileControllerProvider.notifier)
            .fetchProfile();
      });
      return null;
    }, []);

    // Initialize opening hours when profile is loaded
    useEffect(() {
      profileState.whenData((profile) async {
        if (profile.userId != null && currentUserId.value != profile.userId) {
          currentUserId.value = profile.userId;
          await ref
              .read(workshopOpeningControllerProvider.notifier)
              .loadHours(profile.userId!);
        }
      });
      return null;
    }, [profileState]);

    // Update local opening hours state when data is loaded
    useEffect(() {
      openingHoursState.whenData((hours) {
        if (hours.isNotEmpty) {
          openingHours.value = List.from(hours);
        } else {
          // Initialize with default closed state for all days
          openingHours.value =
              AppConstants.DAYS_OF_WEEKS
                  .map(
                    (day) => WorkshopOpeningHour(
                      dayOfWeek: day.toLowerCase(),
                      isOpen: false,
                      openTime: null,
                      closeTime: null,
                      breakStart: null,
                      breakEnd: null,
                    ),
                  )
                  .toList();
        }
      });
      return null;
    }, [openingHoursState]);

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final workshopName = useTextEditingController();
    final description = useTextEditingController();
    final phone = useTextEditingController();
    final email = useTextEditingController();
    final street = useTextEditingController();
    final number = useTextEditingController();
    final postalCode = useTextEditingController();
    final city = useTextEditingController();
    final companyName = useTextEditingController();
    final registerNumber = useTextEditingController();
    final registerCourt = useTextEditingController();
    final vatId = useTextEditingController();
    final profileImageUrl = useState<String?>(null);
    final legalDocumentUrl = useState<String?>(null);
    final newProfileImage = useState<Uint8List?>(null);
    final newLegalDocument = useState<Uint8List?>(null);
    final selectedMonths = useState<String?>(null);

    useEffect(() {
      if (profileState.value != null) {
        if (workshopName.text != (profileState.value!.workshopName ?? '')) {
          workshopName.text = profileState.value!.workshopName ?? '';
        }
        if (description.text != (profileState.value!.shortDescription ?? '')) {
          description.text = profileState.value!.shortDescription ?? '';
        }
        if (phone.text != (profileState.value!.phoneNumber ?? '')) {
          phone.text = profileState.value!.phoneNumber ?? '';
        }
        if (email.text != (profileState.value!.email ?? '')) {
          email.text = profileState.value!.email ?? '';
        }
        if (street.text != (profileState.value!.street ?? '')) {
          street.text = profileState.value!.street ?? '';
        }
        if (number.text != (profileState.value!.number ?? '')) {
          number.text = profileState.value!.number ?? '';
        }
        if (postalCode.text != (profileState.value!.postalCode ?? '')) {
          postalCode.text = profileState.value!.postalCode ?? '';
        }
        if (city.text != (profileState.value!.city ?? '')) {
          city.text = profileState.value!.city ?? '';
        }
        if (companyName.text != (profileState.value!.companyName ?? '')) {
          companyName.text = profileState.value!.companyName ?? '';
        }
        if (registerNumber.text !=
            (profileState.value!.commercialRegisterNumber ?? '')) {
          registerNumber.text =
              profileState.value!.commercialRegisterNumber ?? '';
        }
        if (registerCourt.text != (profileState.value!.registerCourt ?? '')) {
          registerCourt.text = profileState.value!.registerCourt ?? '';
        }
        if (vatId.text != (profileState.value!.vatId ?? '')) {
          vatId.text = profileState.value!.vatId ?? '';
        }

        if ((profileState.value!.bookingsOpen?.isNotEmpty ?? false) &&
            selectedMonths.value != profileState.value!.bookingsOpen) {
          selectedMonths.value = profileState.value!.bookingsOpen!;
        }

        profileImageUrl.value = profileState.value!.profileImageUrl;
        legalDocumentUrl.value = profileState.value!.legalDocumentUrl;
      }

      return null; // cleanup not needed here
    }, [profileState.value]);

    // Listen for update state changes
    ref.listen<AsyncValue<WorkshopSettingModel?>>(
      updateWorkshopProfileControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'error_prefix'.tr()}$error'),
                backgroundColor: Colors.red,
              ),
            );
          },
          data: (data) {
            if (data != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('profile_updated_successfully'.tr()),
                  backgroundColor: Colors.green,
                ),
              );

              // Update the UI state with new URLs from backend response
              profileImageUrl.value = data.profileImageUrl;
              legalDocumentUrl.value = data.legalDocumentUrl;

              // Reset the new file states
              newProfileImage.value = null;
              newLegalDocument.value = null;

              // Reset the controller state
              ref
                  .read(updateWorkshopProfileControllerProvider.notifier)
                  .resetState();
            }
          },
        );
      },
    );

    // Helper function to update opening hours
    void updateOpeningHour(int index, WorkshopOpeningHour updatedHour) {
      final updatedList = List<WorkshopOpeningHour>.from(openingHours.value);
      updatedList[index] = updatedHour;
      openingHours.value = updatedList;
    }

    Future<void> handleSave() async {
      if (formKey.currentState?.validate() ?? false) {
        // Save profile first
        final updateModel = WorkshopUpdateModel(
          workshopName: workshopName.text.trim(),
          shortDescription: description.text.trim(),
          phoneNumber: phone.text.trim(),
          email: email.text.trim(),
          street: street.text.trim(),
          number: number.text.trim(),
          postalCode: postalCode.text.trim(),
          city: city.text.trim(),
          companyName: companyName.text.trim(),
          commercialRegisterNumber: registerNumber.text.trim(),
          registerCourt: registerCourt.text.trim(),
          vatId: vatId.text.trim(),
          profileImage: newProfileImage.value,
          legalDocument: newLegalDocument.value,
          bookingsOpen: selectedMonths.value,
        );

        await ref
            .read(updateWorkshopProfileControllerProvider.notifier)
            .updateProfile(updateModel);

        // Save opening hours if user ID is available
        if (currentUserId.value != null) {
          await ref
              .read(workshopOpeningControllerProvider.notifier)
              .saveHours(currentUserId.value!, openingHours.value);
        }
      }
    }

    Future<TimeOfDay?> showTimePicker(
      BuildContext context,
      TimeOfDay? initialTime,
    ) async {
      return await showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (BuildContext context) {
          DateTime selectedTime = DateTime(
            2023,
            1,
            1,
            initialTime?.hour ?? 9,
            initialTime?.minute ?? 0,
          );

          return Container(
            height: 300,
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: Text('cancel'.tr()),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      CupertinoButton(
                        child: Text('done'.tr()),
                        onPressed:
                            () => Navigator.of(context).pop(
                              TimeOfDay(
                                hour: selectedTime.hour,
                                minute: selectedTime.minute,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    use24hFormat: true,
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: selectedTime,
                    onDateTimeChanged: (DateTime dateTime) {
                      selectedTime = dateTime;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: Column(
        children: [
          // Fixed Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AppTheme.LITE_PRIMARY_COLOR,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.home);
                  },
                  child: Image.asset(AppImages.APP_LOGO, height: 40),
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildNavTab('upcoming_appointments'.tr(), false, () {
                      context.push(AppRoutes.upcomingAppointment);
                    }),

                    const SizedBox(width: 24),
                    _buildNavTab('Serviceverwaltung', false, () {
                      context.push(AppRoutes.serviceManagement);
                    }),
                    const SizedBox(width: 24),
                    _buildNavTab('messages'.tr(), false, () {
                      context.push(AppRoutes.messages);
                    }),
                  ],
                ),
                const Spacer(),
                CustomPopupMenuWidget(
                  onSettingsTap: () {
                    context.go(AppRoutes.workshopSetting);
                  },
                  onLogoutTap: () async {
                    final controller = ref.read(
                      logoutControllerProvider.notifier,
                    );

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    await controller.logout();
                    Navigator.of(context).pop();

                    final logoutState = ref.read(logoutControllerProvider);
                    logoutState.whenOrNull(
                      error: (err, _) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err.toString())));
                      },
                      data: (_) {
                        context.go(AppRoutes.login);
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Settings Header with Save Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'settings'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      (updateState.isLoading || openingHoursState.isLoading)
                          ? null
                          : handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.PRIMARY_COLOR,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child:
                      (updateState.isLoading || openingHoursState.isLoading)
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'save'.tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.BORDER_COLOR),

          // Scrollable Content
          Expanded(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: profileState.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, _) =>
                          Center(child: Text('${'error_prefix'.tr()}$error')),
                  data: (profile) {
                    return Column(
                      children: [
                        // Main Form Container
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.BORDER_COLOR),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Use responsive layout
                              if (constraints.maxWidth > 900) {
                                // Desktop layout - side by side
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildWorkshopInfoSection(
                                          profileImageUrl.value ?? '',
                                          workshopName,
                                          description,
                                          phone,
                                          email,
                                          newProfileImage,
                                          selectedMonths,
                                          AppConstants.MONTHS_OPTIONS,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        color: AppTheme.BORDER_COLOR,
                                      ),
                                      Expanded(
                                        child: _buildLegalInfoSection(
                                          legalDocumentUrl.value ?? '',
                                          street,
                                          number,
                                          postalCode,
                                          city,
                                          companyName,
                                          registerNumber,
                                          registerCourt,
                                          vatId,
                                          newLegalDocument,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                // Mobile/Tablet layout - stacked
                                return Column(
                                  children: [
                                    _buildWorkshopInfoSection(
                                      profileImageUrl.value ?? '',
                                      workshopName,
                                      description,
                                      phone,
                                      email,
                                      newProfileImage,
                                      selectedMonths,
                                      AppConstants.MONTHS_OPTIONS,
                                    ),
                                    const Divider(),
                                    _buildLegalInfoSection(
                                      legalDocumentUrl.value ?? '',
                                      street,
                                      number,
                                      postalCode,
                                      city,
                                      companyName,
                                      registerNumber,
                                      registerCourt,
                                      vatId,
                                      newLegalDocument,
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Workshop Opening Times Container
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.BORDER_COLOR),
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'workshop_opening_times'.tr(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (openingHours.value.isNotEmpty)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: openingHours.value.length,
                                  itemBuilder: (context, index) {
                                    final hour = openingHours.value[index];
                                    return Column(
                                      children: [
                                        _buildDayRow(
                                          context,
                                          hour,
                                          index,
                                          updateOpeningHour,
                                          showTimePicker,
                                        ),
                                        if (index <
                                            openingHours.value.length - 1)
                                          Divider(color: AppTheme.BORDER_COLOR),
                                      ],
                                    );
                                  },
                                )
                              else
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20), // Bottom padding
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    WorkshopOpeningHour hour,
    int index,
    Function(int, WorkshopOpeningHour) updateOpeningHour,
    Future<TimeOfDay?> Function(BuildContext, TimeOfDay?) showTimePicker,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Desktop layout
            return Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    hour.dayOfWeek.tr(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: CupertinoSwitch(
                    value: hour.isOpen,
                    onChanged: (value) {
                      updateOpeningHour(
                        index,
                        WorkshopOpeningHour(
                          dayOfWeek: hour.dayOfWeek,
                          isOpen: value,
                          openTime: value ? '09:00' : null,
                          closeTime: value ? '17:00' : null,
                          breakStart: value ? '13:00' : null,
                          breakEnd: value ? '14:00' : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                if (hour.isOpen) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        TimeOfDay? initialTime;
                        if (hour.openTime != null &&
                            hour.openTime!.isNotEmpty) {
                          try {
                            final parts = hour.openTime!.split(':');
                            if (parts.length == 2) {
                              initialTime = TimeOfDay(
                                hour: int.parse(parts[0]),
                                minute: int.parse(parts[1]),
                              );
                            }
                          } catch (e) {
                            initialTime = const TimeOfDay(hour: 9, minute: 0);
                          }
                        } else {
                          initialTime = const TimeOfDay(hour: 9, minute: 0);
                        }

                        final selectedTime = await showTimePicker(
                          context,
                          initialTime,
                        );
                        if (selectedTime != null) {
                          final timeString =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                          updateOpeningHour(
                            index,
                            WorkshopOpeningHour(
                              dayOfWeek: hour.dayOfWeek,
                              isOpen: hour.isOpen,
                              openTime: timeString,
                              closeTime: hour.closeTime,
                              breakStart: hour.breakStart,
                              breakEnd: hour.breakEnd,
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.BORDER_COLOR),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Image.asset(AppImages.CLOCK, height: 20),
                            const SizedBox(width: 4),
                            Text(
                              'opens_at'.tr(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ' ${hour.openTime ?? '09:00'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        TimeOfDay? initialTime;
                        if (hour.closeTime != null &&
                            hour.closeTime!.isNotEmpty) {
                          try {
                            final parts = hour.closeTime!.split(':');
                            if (parts.length == 2) {
                              initialTime = TimeOfDay(
                                hour: int.parse(parts[0]),
                                minute: int.parse(parts[1]),
                              );
                            }
                          } catch (e) {
                            initialTime = const TimeOfDay(hour: 17, minute: 0);
                          }
                        } else {
                          initialTime = const TimeOfDay(hour: 17, minute: 0);
                        }

                        final selectedTime = await showTimePicker(
                          context,
                          initialTime,
                        );
                        if (selectedTime != null) {
                          final timeString =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                          updateOpeningHour(
                            index,
                            WorkshopOpeningHour(
                              dayOfWeek: hour.dayOfWeek,
                              isOpen: hour.isOpen,
                              openTime: hour.openTime,
                              closeTime: timeString,
                              breakStart: hour.breakStart,
                              breakEnd: hour.breakEnd,
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.BORDER_COLOR),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Image.asset(AppImages.CLOCK, height: 20),
                            const SizedBox(width: 4),
                            Text(
                              'closes_at'.tr(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ' ${hour.closeTime ?? '17:00'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        // Show dialog for break time selection
                        String? breakStartTime = hour.breakStart ?? '13:00';
                        String? breakEndTime = hour.breakEnd ?? '14:00';

                        await showDialog<void>(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext dialogContext) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Text(
                                    'Select Break Time',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  content: Container(
                                    width: 400,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Break Start Time
                                        GestureDetector(
                                          onTap: () async {
                                            TimeOfDay? initialTime;
                                            if (breakStartTime != null &&
                                                breakStartTime!.isNotEmpty) {
                                              try {
                                                final parts = breakStartTime!
                                                    .split(':');
                                                if (parts.length == 2) {
                                                  initialTime = TimeOfDay(
                                                    hour: int.parse(parts[0]),
                                                    minute: int.parse(parts[1]),
                                                  );
                                                }
                                              } catch (e) {
                                                initialTime = const TimeOfDay(
                                                  hour: 13,
                                                  minute: 0,
                                                );
                                              }
                                            } else {
                                              initialTime = const TimeOfDay(
                                                hour: 13,
                                                minute: 0,
                                              );
                                            }

                                            final selectedTime =
                                                await showTimePicker(
                                                  dialogContext,
                                                  initialTime,
                                                );
                                            if (selectedTime != null) {
                                              setState(() {
                                                breakStartTime =
                                                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                                              });
                                            }
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppTheme.BORDER_COLOR,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            padding: const EdgeInsets.all(12.0),
                                            child: Row(
                                              children: [
                                                Image.asset(
                                                  AppImages.CLOCK,
                                                  height: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Break starts at',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  breakStartTime ?? '13:00',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Break End Time
                                        GestureDetector(
                                          onTap: () async {
                                            TimeOfDay? initialTime;
                                            if (breakEndTime != null &&
                                                breakEndTime!.isNotEmpty) {
                                              try {
                                                final parts = breakEndTime!
                                                    .split(':');
                                                if (parts.length == 2) {
                                                  initialTime = TimeOfDay(
                                                    hour: int.parse(parts[0]),
                                                    minute: int.parse(parts[1]),
                                                  );
                                                }
                                              } catch (e) {
                                                initialTime = const TimeOfDay(
                                                  hour: 14,
                                                  minute: 0,
                                                );
                                              }
                                            } else {
                                              initialTime = const TimeOfDay(
                                                hour: 14,
                                                minute: 0,
                                              );
                                            }

                                            final selectedTime =
                                                await showTimePicker(
                                                  dialogContext,
                                                  initialTime,
                                                );
                                            if (selectedTime != null) {
                                              setState(() {
                                                breakEndTime =
                                                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                                              });
                                            }
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppTheme.BORDER_COLOR,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            padding: const EdgeInsets.all(12.0),
                                            child: Row(
                                              children: [
                                                Image.asset(
                                                  AppImages.CLOCK,
                                                  height: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Break ends at',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  breakEndTime ?? '14:00',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text(
                                        'cancel'.tr(),
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.PRIMARY_COLOR,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'save'.tr(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () {
                                        // Validate that break end time is after break start time
                                        if (breakStartTime != null &&
                                            breakEndTime != null) {
                                          final startParts = breakStartTime!
                                              .split(':');
                                          final endParts = breakEndTime!.split(
                                            ':',
                                          );

                                          final startMinutes =
                                              int.parse(startParts[0]) * 60 +
                                              int.parse(startParts[1]);
                                          final endMinutes =
                                              int.parse(endParts[0]) * 60 +
                                              int.parse(endParts[1]);

                                          if (endMinutes <= startMinutes) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Break end time must be after break start time',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                        }

                                        updateOpeningHour(
                                          index,
                                          WorkshopOpeningHour(
                                            dayOfWeek: hour.dayOfWeek,
                                            isOpen: hour.isOpen,
                                            openTime: hour.openTime,
                                            closeTime: hour.closeTime,
                                            breakStart: breakStartTime,
                                            breakEnd: breakEndTime,
                                          ),
                                        );
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.BORDER_COLOR),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Image.asset(AppImages.CLOCK, height: 20),
                            const SizedBox(width: 4),
                            Text(
                              'mittagspause'.tr(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ' ${hour.breakStart ?? '13:00'} - ${hour.breakEnd ?? '14:00'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.BORDER_COLOR),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[100],
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'closed'.tr(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }
          return SizedBox();
        },
      ),
    );
  }
}

Widget _buildNavTab(String title, bool isActive, VoidCallback onTap) {
  return HookBuilder(
    builder: (context) {
      final isHovered = useState(false);

      return InkWell(
        onTap: onTap,
        onHover: (hovering) => isHovered.value = hovering,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight:
                isActive || isHovered.value
                    ? FontWeight.w600
                    : FontWeight.normal,
            color:
                isActive
                    ? Colors.black87
                    : isHovered.value
                    ? Colors.black54
                    : Colors.grey[600],
          ),
        ),
      );
    },
  );
}

Widget _buildWorkshopInfoSection(
  String profileImage,
  TextEditingController name,
  TextEditingController desc,
  TextEditingController phone,
  TextEditingController email,
  ValueNotifier<Uint8List?> newImage,
  ValueNotifier<String?> selectedMonths,
  List<String> options,
) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'workshop_info'.tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        const SizedBox(height: 16),
        _buildLabel('profile_picture_upload'.tr()),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              key: ValueKey(
                '${profileImage}_${DateTime.now().millisecondsSinceEpoch}',
              ), // Add unique key
              radius: 36,
              backgroundColor: Colors.black12,
              backgroundImage:
                  newImage.value != null
                      ? MemoryImage(newImage.value!)
                      : (profileImage.isNotEmpty
                          ? NetworkImage(
                            '$profileImage?v=${DateTime.now().millisecondsSinceEpoch}',
                          ) // Add cache buster
                          : null),
              child:
                  newImage.value == null && (profileImage.isEmpty)
                      ? const Icon(Icons.person, size: 36)
                      : null,
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'png', 'pdf'],
                  withData: kIsWeb,
                );

                if (result != null) {
                  if (kIsWeb) {
                    if (result.files.single.bytes != null) {
                      newImage.value = result.files.single.bytes!;
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F3D52),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                'select'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('workshop_name'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: name,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'workshop_name_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('short_description'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: desc,
          validator: _requiredValidator,
          maxLines: 3,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'short_description_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('phone_number'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: phone,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'phone_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('email_address'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: email,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'email_sample'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Buchbar im Voraus'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,

          child: DropdownButtonFormField<String>(
            value:
                selectedMonths.value != null &&
                        options.contains(selectedMonths.value)
                    ? selectedMonths.value
                    : null,
            decoration: InputDecoration(
              hintText:
                  'Monate auswählen', // Placeholder text when no value is selected
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
            ),

            items:
                options.map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(
                      month,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              selectedMonths.value = newValue;
            },

            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ),
      ],
    ),
  );
}

Widget _buildLegalInfoSection(
  String docImage,
  TextEditingController street,
  TextEditingController number,
  TextEditingController postalCode,
  TextEditingController city,
  TextEditingController company,
  TextEditingController regNum,
  TextEditingController regCourt,
  TextEditingController vat,
  ValueNotifier<Uint8List?> newDocument,
) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'legal_info'.tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        const SizedBox(height: 16),
        _buildLabel('gewerbeanmeldung'.tr()),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              key: ValueKey(
                '${docImage}_${DateTime.now().millisecondsSinceEpoch}',
              ),
              height: 80,
              width: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  newDocument.value != null
                      ? Image.memory(newDocument.value!, fit: BoxFit.cover)
                      : (docImage.isNotEmpty)
                      ? Image.network(
                        '$docImage?v=${DateTime.now().millisecondsSinceEpoch}',
                        fit: BoxFit.cover,
                      )
                      : Image.asset(
                        AppImages.UPLOAD_DOCUMENT,
                        fit: BoxFit.cover,
                      ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'png', 'pdf'],
                  withData: kIsWeb, // Only load bytes on web
                );

                if (result != null) {
                  if (kIsWeb) {
                    // Web platform - use bytes
                    if (result.files.single.bytes != null) {
                      newDocument.value = result.files.single.bytes!;
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F3D52),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                'select'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('business_address'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: street,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'street_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: number,
                validator: _requiredValidator,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  hintText: 'number_hint'.tr(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: postalCode,
                validator: _requiredValidator,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  hintText: 'postal_code_hint'.tr(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: city,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'city_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('company_name'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: company,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'full_legal_name_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('commercial_register_number'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: regNum,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'commercial_register_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('register_court'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: regCourt,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: 'register_court_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('vat_id_ust'.tr()),
        const SizedBox(height: 8),
        TextFormField(
          controller: vat,
          validator: _requiredValidator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: "DE123456789",
          ),
        ),
      ],
    ),
  );
}

Widget _buildLabel(String label) {
  return Text(
    label,
    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
  );
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'field_required'.tr();
  return null;
}
