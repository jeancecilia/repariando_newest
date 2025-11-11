import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/service_controller.dart';
import 'package:repairando_web/src/features/home/domain/service_model.dart';
import 'package:repairando_web/src/features/home/presentation/screens/base_layout.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

class ServiceManagementScreen extends HookConsumerWidget {
  const ServiceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesState = ref.watch(fetchServicesControllerProvider);
    final updateState = ref.watch(updateServiceControllerProvider);

    // Controllers for each service row
    final serviceControllers = useState<Map<String, ServiceRowControllers>>({});
    // Add reactive state for checkbox values
    final checkboxStates = useState<Map<String, bool>>({});

    // Initialize controllers and fetch services on first build
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(fetchServicesControllerProvider.notifier).fetchServices();
      });
      return null;
    }, []);

    // Update controllers when services change
    useEffect(() {
      servicesState.whenData((services) {
        final newControllers = <String, ServiceRowControllers>{};
        final newCheckboxStates = <String, bool>{};

        for (final serviceWithAvailability in services) {
          final service = serviceWithAvailability.service;
          final adminService = serviceWithAvailability.adminService;

          newControllers[service.id] = ServiceRowControllers(
            priceController: TextEditingController(
              text: adminService?.price.toString() ?? '',
            ),
            durationController: TextEditingController(
              text: adminService?.durationMinutes ?? '',
            ),
          );

          // Store checkbox state separately
          newCheckboxStates[service.id] = adminService?.isAvailable ?? false;
        }

        serviceControllers.value = newControllers;
        checkboxStates.value = newCheckboxStates;
      });
      return null;
    }, [servicesState]);

    return BaseLayout(
      title: 'Serviceverwaltung',

      child: Column(
        children: [
          // Main content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildTitleSection(
                    context,
                    ref,
                    serviceControllers.value,
                    checkboxStates.value,
                    updateState.isLoading,
                  ),
                  Divider(color: AppTheme.BORDER_COLOR),
                  Expanded(
                    child: servicesState.when(
                      data:
                          (services) => _buildServicesTable(
                            services,
                            serviceControllers.value,
                            checkboxStates,
                            updateState.isLoading,
                          ),
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error:
                          (error, stack) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error: $error'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          fetchServicesControllerProvider
                                              .notifier,
                                        )
                                        .fetchServices();
                                  },
                                  child: Text('retry'.tr()),
                                ),
                              ],
                            ),
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

  Widget _buildTitleSection(
    BuildContext context,
    WidgetRef ref,
    Map<String, ServiceRowControllers> controllers,
    Map<String, bool> checkboxStates,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'Serviceverwaltung',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 40,
            width: 100,
            child: ElevatedButton(
              onPressed:
                  isLoading
                      ? null
                      : () => _saveAllServices(
                        context,
                        ref,
                        controllers,
                        checkboxStates,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.PRIMARY_COLOR,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size(80, 32),
              ),
              child:
                  isLoading
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
                        style: GoogleFonts.manrope(fontSize: 12),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTable(
    List<ServiceWithAvailability> services,
    Map<String, ServiceRowControllers> controllers,
    ValueNotifier<Map<String, bool>> checkboxStates,
    bool isLoading,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              border: Border.all(color: AppTheme.BORDER_COLOR),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'service_name'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'availability'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Benötigte Arbeitseinheiten (1 WU = 6 min)',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "${'price_input_field'.tr()} in €",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Services list
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final serviceWithAvailability = services[index];
                    final controller =
                        controllers[serviceWithAvailability.service.id];

                    return _buildServiceRow(
                      serviceWithAvailability,
                      controller,
                      checkboxStates,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(
    ServiceWithAvailability serviceWithAvailability,
    ServiceRowControllers? controller,
    ValueNotifier<Map<String, bool>> checkboxStates,
  ) {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final service = serviceWithAvailability.service;
    final isAvailable = checkboxStates.value[service.id] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          // Service Name and Category
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.service,
                  style: GoogleFonts.manrope(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.category,
                  style: GoogleFonts.manrope(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Availability Checkbox
          Expanded(
            flex: 1,
            child: Checkbox(
              value: isAvailable,
              onChanged: (bool? newValue) {
                final updatedStates = Map<String, bool>.from(
                  checkboxStates.value,
                );
                updatedStates[service.id] = newValue ?? false;
                checkboxStates.value = updatedStates;
              },
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: controller.durationController,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  hintText:
                      service.workUnit.isNotEmpty ? service.workUnit : 'WU',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: GoogleFonts.manrope(fontSize: 14),
              ),
            ),
          ),

          // Price Input
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                controller: controller.priceController,

                decoration: AppTheme.textFieldDecoration.copyWith(
                  hintText: 'price'.tr(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: GoogleFonts.manrope(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllServices(
    BuildContext context,
    WidgetRef ref,
    Map<String, ServiceRowControllers> controllers,
    Map<String, bool> checkboxStates,
  ) async {
    try {
      final requests = <UpdateServiceRequest>[];

      for (final entry in controllers.entries) {
        final serviceId = entry.key;
        final controller = entry.value;
        final isAvailable = checkboxStates[serviceId] ?? false;

        final price = double.tryParse(controller.priceController.text) ?? 0.0;
        final duration = controller.durationController.text;

        requests.add(
          UpdateServiceRequest(
            serviceId: serviceId,
            isAvailable: isAvailable,
            price: price,
            durationMinutes: duration,
          ),
        );
      }

      await ref
          .read(updateServiceControllerProvider.notifier)
          .updateMultipleServices(requests);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('service_updated_successfully'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_update_service'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Helper class to manage controllers for each service row
class ServiceRowControllers {
  final TextEditingController priceController;
  final TextEditingController durationController;

  ServiceRowControllers({
    required this.priceController,
    required this.durationController,
  });

  void dispose() {
    priceController.dispose();
    durationController.dispose();
  }
}
