import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:repairando_web/src/features/home/domain/service_option_model.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/manual_appointment_controller.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/widgets/custom_popup_menu.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/logout_controller.dart';

class AddManualAppointmentScreen extends HookConsumerWidget {
  const AddManualAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = useState(0);
    final formKey = GlobalKey<FormState>();

    // Selected values
    final selectedService = useState<ServiceOption?>(null);
    final selectedDate = useState<DateTime?>(null);
    final selectedTimeSlot = useState<TimeSlot?>(null);

    // Vehicle Information Controllers
    final serviceNameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final durationController = useTextEditingController();
    final priceController = useTextEditingController();
    final vinController = useTextEditingController();
    final vehicleMakeController = useTextEditingController();
    final vehicleModelController = useTextEditingController();
    final yearController = useTextEditingController();
    final mileageController = useTextEditingController();
    final engineTypeController = useTextEditingController();

    // Personal Information Controllers
    final customerNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final phoneController = useTextEditingController();
    final addressController = useTextEditingController();
    final cityController = useTextEditingController();
    final postalCodeController = useTextEditingController();
    final notesController = useTextEditingController();

    // Watch providers
    final servicesAsync = ref.watch(availableServicesProvider);
    final createAppointmentState = ref.watch(
      createAppointmentControllerProvider,
    );

    // UPDATED: Enhanced listener with single snackbar logic
    ref.listen(createAppointmentControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (success) {
          if (success != null && success.isNotEmpty) {
            // Show success message and navigate
            ScaffoldMessenger.of(
              context,
            ).clearSnackBars(); // Clear any existing snackbars
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate back to calendar
            context.pop();

            // Reset the controller state
            ref.read(createAppointmentControllerProvider.notifier).resetState();
          }
        },
        error: (error, stackTrace) {
          print('error');

          print(error);
          // Clear any existing snackbars and show error
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );

          // Reset state after showing error
          ref.read(createAppointmentControllerProvider.notifier).resetState();
        },
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: Column(
        children: [
          // Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AppTheme.LITE_PRIMARY_COLOR,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push(AppRoutes.home),
                  child: Image.asset(AppImages.APP_LOGO, height: 40),
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildNavTab('upcoming_appointments'.tr(), false, () {
                      context.push(AppRoutes.upcomingAppointment);
                    }),

                    const SizedBox(width: 24),
                    _buildNavTab('service_management'.tr(), false, () {
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
                  onSettingsTap: () => context.go(AppRoutes.workshopSetting),
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
                      data: (_) => context.go(AppRoutes.login),
                    );
                  },
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Manuelle Buchung hinzufügen',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Füllen Sie das untenstehende Formular aus, um einen neuen Termin zu buchen.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  // Step Headers
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStepHeader(
                            'Service-Auswahl',
                            currentStep.value == 0,
                            0,
                            () => currentStep.value = 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStepHeader(
                            'Datum & Zeit-Auswahl',
                            currentStep.value == 1,
                            1,
                            () => currentStep.value = 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStepHeader(
                            'Fahrzeuginformationen',
                            currentStep.value == 2,
                            2,
                            () => currentStep.value = 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStepHeader(
                            'Persönliche Informationen',
                            currentStep.value == 3,
                            3,
                            () => currentStep.value = 3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Form(
                            key: formKey,
                            child: _buildCurrentStepContent(
                              currentStep.value,
                              context,
                              ref,
                              servicesAsync,
                              selectedService,
                              selectedDate,
                              selectedTimeSlot,
                              serviceNameController,
                              descriptionController,
                              durationController,
                              priceController,
                              vinController,
                              vehicleMakeController,
                              vehicleModelController,
                              yearController,
                              mileageController,
                              engineTypeController,
                              customerNameController,
                              emailController,
                              phoneController,
                              addressController,
                              cityController,
                              postalCodeController,
                              notesController,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (currentStep.value > 0)
                                  OutlinedButton(
                                    onPressed:
                                        () =>
                                            currentStep.value =
                                                currentStep.value - 1,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.PRIMARY_COLOR,
                                      side: const BorderSide(
                                        color: AppTheme.PRIMARY_COLOR,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'previous'.tr(),
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                createAppointmentState.isLoading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                      onPressed: () {
                                        _handleNextStep(
                                          currentStep,
                                          formKey,
                                          context,
                                          ref,
                                          selectedService,
                                          selectedDate,
                                          selectedTimeSlot,
                                          serviceNameController,
                                          descriptionController,
                                          durationController,
                                          priceController,
                                          vinController,
                                          vehicleMakeController,
                                          vehicleModelController,
                                          yearController,
                                          mileageController,
                                          engineTypeController,
                                          customerNameController,
                                          emailController,
                                          phoneController,
                                          addressController,
                                          cityController,
                                          postalCodeController,
                                          notesController,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.PRIMARY_COLOR,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _getNextButtonText(currentStep.value),
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(
    int currentStep,
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ServiceOption>> servicesAsync,
    ValueNotifier<ServiceOption?> selectedService,
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
    TextEditingController serviceNameController,
    TextEditingController descriptionController,
    TextEditingController durationController,
    TextEditingController priceController,
    TextEditingController vinController,
    TextEditingController vehicleMakeController,
    TextEditingController vehicleModelController,
    TextEditingController yearController,
    TextEditingController mileageController,
    TextEditingController engineTypeController,
    TextEditingController customerNameController,
    TextEditingController emailController,
    TextEditingController phoneController,
    TextEditingController addressController,
    TextEditingController cityController,
    TextEditingController postalCodeController,
    TextEditingController notesController,
  ) {
    switch (currentStep) {
      case 0:
        return _buildServiceSelectionForm(
          context,
          ref,
          servicesAsync,
          selectedService,
          serviceNameController,
          descriptionController,
          priceController,
          durationController,
        );
      case 1:
        return _buildDateTimeSelectionForm(
          context,
          ref,
          selectedService,
          selectedDate,
          selectedTimeSlot,
          durationController,
        );
      case 2:
        return _buildVehicleInformationForm(
          vinController,
          vehicleMakeController,
          vehicleModelController,
          yearController,
          mileageController,
          engineTypeController,
        );
      case 3:
        return _buildPersonalInformationForm(
          customerNameController,
          emailController,
          phoneController,
          addressController,
          cityController,
          postalCodeController,
          notesController,
        );
      default:
        return Container();
    }
  }

  Widget _buildServiceSelectionForm(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ServiceOption>> servicesAsync,
    ValueNotifier<ServiceOption?> selectedService,
    TextEditingController serviceNameController,
    TextEditingController descriptionController,
    TextEditingController priceController,
    TextEditingController durationController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service Selection
        _buildServiceDropdown(
          context,
          servicesAsync,
          selectedService,
          serviceNameController,
          descriptionController,
          priceController,
          durationController,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDateTimeSelectionForm(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<ServiceOption?> selectedService,
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
    TextEditingController durationController,
  ) {
    return SizedBox(
      height: 550,
      child: Row(
        children: [
          // Time Slots Section (Left Side)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verfügbare Zeitfenster',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedDate.value == null ||
                      durationController.text.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'Bitte Datum auswählen',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    _buildTimeSlotChips(
                      context,
                      ref,
                      selectedDate.value!,
                      durationController,
                      selectedTimeSlot,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Calendar Section (Right Side)
          Expanded(
            flex: 2,
            child: Container(
           padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Termin-Datum auswählen',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  Expanded(
                    child: _buildCalendarWidget(
                      context,
                      selectedDate,
                      selectedTimeSlot,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Updated calendar widget with proper navigation
  Widget _buildCalendarWidget(
    BuildContext context,
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
  ) {
    final now = DateTime.now();
    final currentMonth = useState(DateTime(now.year, now.month));

    return Column(
      children: [
        // Calendar Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final prevMonth = DateTime(
                    currentMonth.value.year,
                    currentMonth.value.month - 1,
                  );
                  // Allow navigation to previous month only if it's not before current month
                  if (prevMonth.year > now.year ||
                      (prevMonth.year == now.year &&
                          prevMonth.month >= now.month)) {
                    currentMonth.value = prevMonth;
                  }
                },
                icon: Icon(
                  Icons.chevron_left,
                  color:
                      (currentMonth.value.year > now.year ||
                              (currentMonth.value.year == now.year &&
                                  currentMonth.value.month > now.month))
                          ? Colors.black87
                          : Colors.grey[400],
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              Text(
                DateFormat.yMMMM().format(currentMonth.value),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () {
                  currentMonth.value = DateTime(
                    currentMonth.value.year,
                    currentMonth.value.month + 1,
                  );
                },
                icon: const Icon(Icons.chevron_right),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),

        // Days of Week Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            children:
                ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),

        // Calendar Grid
        Expanded(
          child: _buildCalendarGrid(
            currentMonth.value,
            selectedDate,
            selectedTimeSlot,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(
    DateTime currentMonth,
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
  ) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstDayWeekday; i++) {
      dayWidgets.add(Container());
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      final isToday =
          date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;
      final isSelected =
          selectedDate.value != null &&
          date.day == selectedDate.value!.day &&
          date.month == selectedDate.value!.month &&
          date.year == selectedDate.value!.year;
      // UPDATED: Disable today's date and past dates - only allow future dates
      final isDisabled = date.isBefore(today.add(const Duration(days: 1)));

      dayWidgets.add(
        GestureDetector(
          onTap:
              isDisabled
                  ? null
                  : () {
                    selectedDate.value = date;
                    selectedTimeSlot.value =
                        null; // Reset time slot when date changes
                  },
          child: Container(
            margin: const EdgeInsets.all(2),
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.PRIMARY_COLOR : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isDisabled
                          ? Colors.grey[400]
                          : isSelected
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.2,
        children: dayWidgets,
      ),
    );
  }

  Widget _buildTimeSlotChips(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    TextEditingController durationController,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
  ) {
    // Calculate duration in minutes from work units
    final workUnits = int.tryParse(durationController.text) ?? 0;
    final durationMinutes = workUnits * 6;

    if (durationMinutes <= 0) {
      return Expanded(
        child: Center(
          child: Text(
            'please_enter_valid_duration'.tr(),
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final timeSlotsAsync = ref.watch(
      timeSlotsProvider((
        date: selectedDate,
        workUnits: int.parse(durationController.text),
      )),
    );

    return timeSlotsAsync.when(
      data: (timeSlots) {
        if (timeSlots.isEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                'no_available_time_slots'.tr(),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  timeSlots.map((slot) {
                    final isSelected =
                        selectedTimeSlot.value?.startTime == slot.startTime;

                    return GestureDetector(
                      onTap: () {
                        selectedTimeSlot.value = slot;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppTheme.PRIMARY_COLOR
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppTheme.PRIMARY_COLOR
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          slot.displayText,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        );
      },
      loading:
          () =>
              const Expanded(child: Center(child: CircularProgressIndicator())),
      error: (error, stack) {
        return Expanded(
          child: Center(
            child: Text(
              'error_loading_time_slots'.tr(),
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleInformationForm(
    TextEditingController vinController,
    TextEditingController vehicleMakeController,
    TextEditingController vehicleModelController,
    TextEditingController yearController,
    TextEditingController mileageController,
    TextEditingController engineTypeController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                'enter_vin'.tr(),
                vinController,
                required: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFormField(
                'enter_vehicle_make'.tr(),
                vehicleMakeController,
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildFormField(
                'enter_vehicle_model'.tr(),
                vehicleModelController,
                required: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFormField(
                'enter_year_manufacture'.tr(),
                yearController,
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildFormField(
                'enter_mileage'.tr(),
                mileageController,
                required: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFormField(
                'enter_engine_type'.tr(),
                engineTypeController,
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildServiceDropdown(
    BuildContext context,
    AsyncValue<List<ServiceOption>> servicesAsync,
    ValueNotifier<ServiceOption?> selectedService,
    TextEditingController serviceNameController,
    TextEditingController descriptionController,
    TextEditingController priceController,
    TextEditingController durationController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicename *',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        servicesAsync.when(
          data:
              (services) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: DropdownButtonFormField<ServiceOption>(
                  value: selectedService.value,
                  decoration: InputDecoration(
                    hintText: 'Service auswählen',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                  items:
                      services.map((service) {
                        return DropdownMenuItem<ServiceOption>(
                          value: service,
                          child: Text(
                            service.serviceName,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (ServiceOption? value) {
                    selectedService.value = value;
                    if (value != null) {
                      // Validate that service has price and work units
                      if (value.price <= 0 || value.workUnit <= 0) {
                        // Show warning that service configuration is incomplete
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'warning_service_incomplete'.tr(),
                              style: GoogleFonts.manrope(color: Colors.white),
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 4),
                          ),
                        );
                        }
                      }

                      serviceNameController.text = value.serviceName;
                      descriptionController.text = value.description;
                      priceController.text =
                          value.price > 0
                              ? '${value.price.toStringAsFixed(2)} €'
                              : '0.00 €';
                      // Clear duration field so user can enter their own WU value
                      durationController.clear();
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Service auswählen';
                    }
                    return null;
                  },
                ),
              ),
          loading:
              () => Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
          error:
              (error, stack) => Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Center(
                  child: Text(
                    'error_loading_services'.tr(),
                    style: GoogleFonts.manrope(fontSize: 14, color: Colors.red),
                  ),
                ),
              ),
        ),
        const SizedBox(height: 20),
        if (selectedService.value != null) ...[
          _buildFormField(
            'description'.tr(),
            descriptionController,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildFormField('price'.tr(), priceController)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildFormField(
                      'Dauer (AE)',
                      durationController,
                      required: true,
                      hintText: 'Arbeitseinheiten eingeben',
                      helperText: '1 WU = 6 minutes',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
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

  Widget _buildStepHeader(
    String title,
    bool isActive,
    int stepIndex,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.PRIMARY_COLOR : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInformationForm(
    TextEditingController customerNameController,
    TextEditingController emailController,
    TextEditingController phoneController,
    TextEditingController addressController,
    TextEditingController cityController,
    TextEditingController postalCodeController,
    TextEditingController notesController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          'customer_name'.tr(),
          customerNameController,
          required: true,
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildFormField(
                'email_address'.tr(),
                emailController,
                required: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFormField(
                'phone_number'.tr(),
                phoneController,
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _buildFormField('address'.tr(), addressController, required: true),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildFormField(
                'city'.tr(),
                cityController,
                required: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFormField(
                'postal_code'.tr(),
                postalCodeController,
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _buildFormField(
          'additional_notes'.tr(),
          notesController,
          maxLines: 4,
          required: true,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    bool readOnly = false,
    String? hintText,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType:
              label.contains('WU') ||
                      label.contains('duration') ||
                      label.contains('year') ||
                      label.contains('mileage')
                  ? TextInputType.number
                  : label.contains('price')
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : label.contains('email')
                  ? TextInputType.emailAddress
                  : label.contains('phone')
                  ? TextInputType.phone
                  : TextInputType.text,
          inputFormatters: label.contains('price')
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
          validator:
              required
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'this_field_is_required'.tr();
                    }

                    // Specific validations
                    if (label.contains('WU') || label.contains('duration')) {
                      final workUnits = int.tryParse(value.trim());
                      if (workUnits == null || workUnits <= 0) {
                        return 'please_enter_valid_work_units'.tr();
                      }
                    }

                    if (label.toLowerCase().contains('email')) {
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'please_enter_valid_email'.tr();
                      }
                    }

                    if (label.toLowerCase().contains('phone')) {
                      if (value.trim().length < 10) {
                        return 'please_enter_valid_phone'.tr();
                      }
                    }

                    if (label.contains('year')) {
                      final year = int.tryParse(value.trim());
                      final currentYear = DateTime.now().year;
                      if (year == null ||
                          year < 1900 ||
                          year > currentYear + 1) {
                        return 'please_enter_valid_year'.tr();
                      }
                    }

                    return null;
                  }
                  : null,
          decoration: InputDecoration(
            hintText: hintText ?? label,
            helperText: helperText,
            helperStyle: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            hintStyle: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.PRIMARY_COLOR),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
          ),
          style: GoogleFonts.manrope(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  String _getNextButtonText(int currentStep) {
    switch (currentStep) {
      case 0:
        return 'Weiter: Datum & Zeit';
      case 1:
        return 'Weiter: Fahrzeug-Info';
      case 2:
        return 'Weiter: Persönliche Info';
      case 3:
        return 'Termin erstellen';
      default:
        return 'next'.tr();
    }
  }

  // ENHANCED: Complete validation method for all steps with proper form validation
  void _handleNextStep(
    ValueNotifier<int> currentStep,
    GlobalKey<FormState> formKey,
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<ServiceOption?> selectedService,
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
    TextEditingController serviceNameController,
    TextEditingController descriptionController,
    TextEditingController durationController,
    TextEditingController priceController,
    TextEditingController vinController,
    TextEditingController vehicleMakeController,
    TextEditingController vehicleModelController,
    TextEditingController yearController,
    TextEditingController mileageController,
    TextEditingController engineTypeController,
    TextEditingController customerNameController,
    TextEditingController emailController,
    TextEditingController phoneController,
    TextEditingController addressController,
    TextEditingController cityController,
    TextEditingController postalCodeController,
    TextEditingController notesController,
  ) {
    // Clear any existing snackbars before validation
    ScaffoldMessenger.of(context).clearSnackBars();

    switch (currentStep.value) {
      case 0:
        final serviceValidation = _validateServiceStep(
          selectedService.value,
          durationController.text,
        );
        if (serviceValidation == null) {
          currentStep.value = 1;
        } else {}
        break;

      case 1:
        final dateTimeValidation = _validateDateTimeStep(
          selectedDate.value,
          selectedTimeSlot.value,
        );
        if (dateTimeValidation == null) {
          currentStep.value = 2;
        } else {}
        break;

      case 2:
        // Validate vehicle form fields
        if (_validateCurrentStepForm(formKey)) {
          currentStep.value = 3;
        } else {}
        break;

      case 3:
        // Validate personal information form fields
        if (_validateCurrentStepForm(formKey)) {
          _createAppointment(
            context,
            ref,
            selectedService.value!,
            selectedDate.value!,
            selectedTimeSlot.value!,
            serviceNameController,
            descriptionController,
            durationController,
            priceController,
            vinController,
            vehicleMakeController,
            vehicleModelController,
            yearController,
            mileageController,
            engineTypeController,
            customerNameController,
            emailController,
            phoneController,
            addressController,
            cityController,
            postalCodeController,
            notesController,
          );
        } else {}
        break;
    }
  }

  // Helper method to validate current step form
  bool _validateCurrentStepForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  // ENHANCED: Service step validation
  String? _validateServiceStep(
    ServiceOption? selectedService,
    String duration,
  ) {
    if (selectedService == null) {
      return 'Service auswählen';
    }

    if (duration.trim().isEmpty) {
      return 'please_enter_duration'.tr();
    }

    final workUnits = int.tryParse(duration.trim());
    if (workUnits == null || workUnits <= 0) {
      return 'please_enter_valid_work_units'.tr();
    }

    return null; // No errors
  }

  // ENHANCED: Date and time step validation
  String? _validateDateTimeStep(
    DateTime? selectedDate,
    TimeSlot? selectedTimeSlot,
  ) {
    if (selectedDate == null) {
      return 'Termin-Datum auswählen';
    }

    // Check if selected date is not in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (selectedDay.isBefore(today)) {
      return 'Bitte wählen Sie ein Datum in der Zukunft';
    }

    if (selectedTimeSlot == null) {
      return 'Bitte wählen Sie ein Zeitfenster';
    }

    return null; // No errors
  }

  // UPDATED: Enhanced appointment creation method
  void _createAppointment(
    BuildContext context,
    WidgetRef ref,
    ServiceOption selectedService,
    DateTime selectedDate,
    TimeSlot selectedTimeSlot,
    TextEditingController serviceNameController,
    TextEditingController descriptionController,
    TextEditingController durationController,
    TextEditingController priceController,
    TextEditingController vinController,
    TextEditingController vehicleMakeController,
    TextEditingController vehicleModelController,
    TextEditingController yearController,
    TextEditingController mileageController,
    TextEditingController engineTypeController,
    TextEditingController customerNameController,
    TextEditingController emailController,
    TextEditingController phoneController,
    TextEditingController addressController,
    TextEditingController cityController,
    TextEditingController postalCodeController,
    TextEditingController notesController,
  ) {
    final controller = ref.read(createAppointmentControllerProvider.notifier);

    // Parse the price from the priceController, removing any currency symbols and formatting
    final priceText = priceController.text.trim().replaceAll('€', '').replaceAll(',', '.').trim();
    final price = double.tryParse(priceText) ?? selectedService.price;

    // Final validation before creating appointment
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preis muss größer als 0 sein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final workUnitsInt = int.tryParse(durationController.text.trim());
    if (workUnitsInt == null || workUnitsInt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Work Units müssen größer als 0 sein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    controller.createAppointment(
      serviceName: selectedService.serviceName,
      description: descriptionController.text,
      appointmentDate: selectedDate,
      selectedTimeSlot: selectedTimeSlot,
      durationMinutes: durationController.text,
      price: price,
      vin: vinController.text.trim(),
      vehicleMake: vehicleMakeController.text.trim(),
      vehicleModel: vehicleModelController.text.trim(),
      year: yearController.text.trim(),
      mileage: mileageController.text.trim(),
      engineType: engineTypeController.text.trim(),
      customerName: customerNameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      postalCode: postalCodeController.text.trim(),
      notes: notesController.text.trim(),
      serviceId: selectedService.serviceId,
      workUnits: durationController.text,
    );
  }
}
