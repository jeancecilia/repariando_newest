// FIXED: workshop_profile_screen.dart - Key fixes applied
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_constants.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/home/domain/service_model.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';
import 'package:repairando_mobile/src/features/home/presentation/controllers/service_controller.dart';
import 'package:repairando_mobile/src/features/messages/domain/chat_model.dart';
import 'package:repairando_mobile/src/features/messages/presentation/controllers/chat_controller.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class WorkshopProfileScreen extends HookConsumerWidget {
  final WorkshopModel workshop;

  const WorkshopProfileScreen({super.key, required this.workshop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set the selected workshop ID when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedWorkshopProvider.notifier).state = workshop.userId;
    });

    final servicesAsync = ref.watch(workshopServicesProvider(workshop.userId!));
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(serviceCategoriesProvider);
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: AppTheme.BACKGROUND_COLOR,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleBackButton(),
        ),
        title: Text(
          'workshop_profile_title'.tr(),
          style: AppTheme.appBarTitleStyle,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                context.push(AppRoutes.notification);
              },
              child: Image.asset(AppImages.NOTIFICATION_ICON, height: 25.h),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workshop Info Container
            Container(
              decoration: AppTheme.workshopProfileContainerDecoration,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (workshop.profileImageUrl != null) ...[
                      Container(
                        height: 150.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.network(workshop.profileImageUrl!),
                      ),
                    ] else ...[
                      Image.asset(AppImages.AUTOREPAIR_IMAGE),
                    ],
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          workshop.workshopName ?? '',
                          style: AppTheme.workshopNameStyle,
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workshop.shortDescription ?? '',
                          style: AppTheme.workshopServicesStyle,
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          "${workshop.street} ${workshop.postalCode} ${workshop.city}",
                          style: AppTheme.workshopAddressStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Contact Section
            Row(
              children: [
                Expanded(
                  child: Text(
                    'workshop_contact_text'.tr(),
                    style: AppTheme.contactUsTextStyle,
                  ),
                ),
                SizedBox(
                  width: 130.w,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5C00),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        chatState.isCreatingChat
                            ? null
                            : () => _handleChatButtonPressed(context, ref),
                    child:
                        chatState.isCreatingChat
                            ? SizedBox(
                              height: 15.h,
                              width: 15.w,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image.asset(
                                  AppImages.WHITE_MESSAGE_IMAGE,
                                  height: 15.h,
                                ),
                                Text(
                                  'workshop_chat_button'.tr(),
                                  style: AppTheme.chatButtonTextStyle,
                                ),
                              ],
                            ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Services Section Header
            Text(
              'workshop_services_list'.tr(),
              style: AppTheme.sectionHeaderStyle,
            ),
            SizedBox(height: 10.h),

            // Category Filter (if you want to add filtering)
            if (categories.isNotEmpty) ...[
              SizedBox(
                height: 40.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(selectedCategoryProvider.notifier).state =
                              category;
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: AppTheme.PRIMARY_COLOR,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 15.h),
            ],

            // Services List
            servicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'no_services_available'.tr(),
                        style: AppTheme.serviceDescriptionStyle,
                      ),
                    ),
                  );
                }

                // Filter services by selected category
                final filteredServices =
                    selectedCategory == 'All'
                        ? services
                        : services
                            .where(
                              (service) => service.category == selectedCategory,
                            )
                            .toList();

                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    return _buildServiceCard(context, service, ref);
                  },
                );
              },
              loading:
                  () => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: const Color(0xFFFF5C00),
                      ),
                    ),
                  ),
              error:
                  (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'error_loading_services'.tr(),
                            style: AppTheme.serviceDescriptionStyle,
                          ),
                          SizedBox(height: 10.h),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(
                                    workshopServicesProvider(
                                      workshop.userId!,
                                    ).notifier,
                                  )
                                  .refreshServices();
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
    );
  }

  // FIXED: Handle chat button pressed with proper validation and error handling
  Future<void> _handleChatButtonPressed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Validate workshop user ID
    if (workshop.userId == null || workshop.userId!.isEmpty) {
      _showErrorSnackBar(context, 'Workshop information is incomplete');
      return;
    }

    // Validate UUID format
    if (!_isValidUUID(workshop.userId!)) {
      _showErrorSnackBar(context, 'Invalid workshop ID format');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showErrorSnackBar(context, 'Please login to start a chat');
      return;
    }

    // Check if user is trying to chat with themselves
    if (currentUser.id == workshop.userId) {
      _showErrorSnackBar(context, 'You cannot start a chat with yourself');
      return;
    }

    try {
      final chatController = ref.read(chatControllerProvider.notifier);
      final repository = ref.read(chatRepositoryProvider);

      // Use getOrCreateChatBetweenUsers instead of getOrCreateChatForAppointment
      // since you want to chat directly with the workshop owner, not based on an appointment
      final chat = await repository.getOrCreateChatBetweenUsers(
        currentUserId: currentUser.id,
        otherUserId: workshop.userId!,
        isCurrentUserAdmin:
            false, // Current user is customer, workshop owner is admin
      );

      // Navigate to the chat
      _navigateToChat(context, chat);
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to start chat: ${e.toString()}');
    }
  }

  bool _isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(uuid);
  }

  // Navigate to chat screen
  void _navigateToChat(BuildContext context, Chat chat) {
    context.push(
      AppRoutes.workshopMessages,
      extra: {
        'chatId': chat.id,
        'chatName': workshop.workshopName ?? 'Workshop',
        'otherUserImage': workshop.profileImageUrl,
      },
    );
  }

  // Show error message
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    ServiceModel service,
    WidgetRef ref,
  ) {
    return GestureDetector(
      onTap: () {
        if (service.price == 0.0) {
          context.push(
            AppRoutes.offerServiceDetail,
            extra: {'service': service, 'workshop': workshop},
          );
        } else {
          context.push(
            AppRoutes.serviceDetail,
            extra: {'service': service, 'workshop': workshop},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              service.price == 0.0
                  ? AppTheme.YELLOW_COLOR
                  : AppTheme.BROWN_ORANGE_COLOR,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              service.serviceName ?? 'Unknown Service',
                              style: AppTheme.serviceNameStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description ??
                            'workshop_service_description'.tr(),
                        style: AppTheme.serviceDescriptionStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            service.price == 0.0
                                ? ''
                                : formatPrice(service.price),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (service.price == 0.0) {
                                context.push(
                                  AppRoutes.offerNewAppointment,
                                  extra: {
                                    'service': service,
                                    'workshop': workshop,
                                  },
                                );
                              } else {
                                context.push(
                                  AppRoutes.newAppointment,
                                  extra: {
                                    'service': service,
                                    'workshop': workshop,
                                  },
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 20,
                              ),
                              decoration: AppTheme.bookButtonDecoration,
                              child: Center(
                                child: Text(
                                  'workshop_book_button'.tr(),
                                  style: AppTheme.bookButtonTextStyle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
