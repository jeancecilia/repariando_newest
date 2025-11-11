import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/home/data/location_respository.dart';
import 'package:repairando_mobile/src/features/home/presentation/controllers/location_controller.dart';
import 'package:repairando_mobile/src/features/home/presentation/controllers/workshop_controller.dart';
import 'package:repairando_mobile/src/features/profile/presentation/controllers/profile_controller.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workshopAsyncValue = ref.watch(workshopsProvider);
    final showSuggestions = ref.watch(showSuggestionsProvider);
    final searchSuggestions = ref.watch(searchSuggestionsProvider);
    final filteredWorkshops = ref.watch(filteredWorkshopsProvider);
    final profileState = ref.watch(profileControllerProvider);

    // Location-related providers
    final userLocation = ref.watch(userLocationProvider);
    final radius = ref.watch(radiusProvider);
    final isLocationEnabled = ref.watch(isLocationFilterEnabledProvider);
    final locationFilteredWorkshops = ref.watch(
      locationFilteredWorkshopsProvider,
    );
    final locationStatus = ref.watch(locationStatusProvider);
    final workshopCount = ref.watch(workshopCountProvider);
    final viewAll = useState(false);

    // Determine which workshops to display
    final displayedWorkshops = useMemoized(
      () {
        if (showSuggestions) {
          return filteredWorkshops
              .map(
                (w) => WorkshopWithDistance(
                  workshop: w,
                  distance: 0,
                  location: null,
                ),
              )
              .toList();
        } else if (isLocationEnabled) {
          return locationFilteredWorkshops.value ?? [];
        } else {
          return (workshopAsyncValue.value ?? [])
              .map(
                (w) => WorkshopWithDistance(
                  workshop: w,
                  distance: 0,
                  location: null,
                ),
              )
              .toList();
        }
      },
      [
        showSuggestions,
        filteredWorkshops,
        isLocationEnabled,
        locationFilteredWorkshops,
        workshopAsyncValue,
      ],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting and notifications
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                profileState.when(
                  loading:
                      () => Text(
                        "home_welcome".tr(),
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.TEXT_COLOR,
                        ),
                      ),
                  error:
                      (err, stack) => Text(
                        "${'home_error_prefix'.tr()}${err.toString()}",
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      ),
                  data: (customer) {
                    return Text(
                      "${'home_welcome_user'.tr()} ${customer!.name}",
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.TEXT_COLOR,
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.notification);
                  },
                  child: Image.asset(AppImages.NOTIFICATION_ICON, height: 30.h),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Status and Control Panel
            if (!viewAll.value) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isLocationEnabled
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isLocationEnabled
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    // Status row
                    Row(
                      children: [
                        Icon(
                          isLocationEnabled
                              ? Icons.location_on
                              : Icons.location_off,
                          color:
                              isLocationEnabled ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationStatus,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isLocationEnabled
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                            ),
                          ),
                        ),
                        // Location control button
                        userLocation.when(
                          data:
                              (location) => ElevatedButton(
                                onPressed:
                                    location == null
                                        ? () =>
                                            ref
                                                .read(
                                                  userLocationProvider.notifier,
                                                )
                                                .getCurrentLocation()
                                        : () =>
                                            ref
                                                .read(
                                                  userLocationProvider.notifier,
                                                )
                                                .clearLocation(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      location == null
                                          ? Colors.blue
                                          : Colors.red,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 32),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                child: Text(
                                  location == null ? 'Enable' : 'Disable',
                                  style: GoogleFonts.manrope(fontSize: 12),
                                ),
                              ),
                          loading:
                              () => const SizedBox(
                                width: 80,
                                height: 32,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          error:
                              (err, _) => ElevatedButton(
                                onPressed:
                                    () =>
                                        ref
                                            .read(userLocationProvider.notifier)
                                            .getCurrentLocation(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 32),
                                ),
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.manrope(fontSize: 12),
                                ),
                              ),
                        ),
                      ],
                    ),

                    // Radius slider (only show when location is enabled and not searching)
                    if (isLocationEnabled && !showSuggestions) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Search Radius",
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              "${radius.toInt()} km",
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.green,
                          inactiveTrackColor: Colors.green.shade200,
                          thumbColor: Colors.green.shade700,
                          overlayColor: Colors.green.withOpacity(0.2),
                          valueIndicatorColor: Colors.green.shade700,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: radius,
                          min: 1,
                          max: 400,
                          onChanged: (value) {
                            ref
                                .read(radiusProvider.notifier)
                                .updateRadius(value);
                          },
                          label: "${radius.toInt()} km",
                        ),
                      ),
                      if (isLocationEnabled) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Found: $workshopCount workshops",
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: Colors.green.shade600,
                              ),
                            ),
                            GestureDetector(
                              onTap:
                                  () =>
                                      ref
                                          .read(userLocationProvider.notifier)
                                          .refreshLocation(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 14,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Refresh",
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: Colors.green.shade600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Search Box
            if (!viewAll.value) ...[
              Column(
                children: [
                  TextField(
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9äöüÄÖÜß]'),
                      ),
                    ],
                    decoration: AppTheme.outlineTextFieldDecoration.copyWith(
                      hintText: 'home_search_hint'.tr(),
                      prefixIcon: const Icon(Icons.search, size: 20),
                    ),
                    onChanged: (value) {
                      ref.read(searchInputProvider.notifier).state = value;
                      ref.read(showSuggestionsBoxProvider.notifier).state =
                          true;
                    },
                  ),
                  if (searchSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: searchSuggestions.length,
                        separatorBuilder:
                            (context, index) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final suggestion = searchSuggestions[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              suggestion,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            onTap: () {
                              ref.read(searchInputProvider.notifier).state =
                                  suggestion;
                              ref
                                  .read(showSuggestionsBoxProvider.notifier)
                                  .state = false;
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Section Heading
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  showSuggestions
                      ? "home_search_results".tr()
                      : isLocationEnabled
                      ? "Nearby Workshops"
                      : "home_popular_workshops".tr(),
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!showSuggestions && !isLocationEnabled)
                  GestureDetector(
                    onTap: () {
                      if (viewAll.value) {
                        viewAll.value = false;
                      } else {
                        viewAll.value = true;
                      }
                    },
                    child: Text(
                      viewAll.value ? "show less" : "home_view_all".tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Workshop List
            Expanded(
              child: workshopAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (err, st) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${'home_error_prefix'.tr()}$err',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                data:
                    (_) =>
                        displayedWorkshops.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isLocationEnabled
                                        ? Icons.location_off
                                        : Icons.store,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isLocationEnabled
                                        ? 'No workshops found in ${radius.toInt()}km radius'
                                        : showSuggestions
                                        ? 'No workshops match your search'
                                        : 'No workshops available',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (isLocationEnabled) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try increasing the search radius or refreshing your location',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh: () async {
                                if (isLocationEnabled) {
                                  await ref
                                      .read(userLocationProvider.notifier)
                                      .refreshLocation();
                                }
                                ref.invalidate(workshopsProvider);
                              },
                              child: ListView.builder(
                                itemCount:
                                    (viewAll.value && isLocationEnabled)
                                        ? displayedWorkshops.length
                                        : (displayedWorkshops.length > 5
                                            ? 5
                                            : displayedWorkshops.length),
                                itemBuilder: (context, index) {
                                  final workshopWithDistance =
                                      displayedWorkshops[index];
                                  final workshop =
                                      workshopWithDistance.workshop;

                                  return GestureDetector(
                                    onTap: () {
                                      context.push(
                                        AppRoutes.workshopProfile,
                                        extra: workshop,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundImage: NetworkImage(
                                                  workshop.profileImageUrl ??
                                                      'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png',
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            workshop.workshopName ??
                                                                'home_unnamed_workshop'
                                                                    .tr(),
                                                            style:
                                                                GoogleFonts.manrope(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        if (isLocationEnabled &&
                                                            workshopWithDistance
                                                                    .distance >
                                                                0)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Colors
                                                                      .blue
                                                                      .shade100,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              workshopWithDistance
                                                                  .distanceString,
                                                              style: GoogleFonts.manrope(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors
                                                                        .blue
                                                                        .shade800,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      workshop.shortDescription ??
                                                          '',
                                                      style:
                                                          GoogleFonts.manrope(
                                                            fontSize: 12,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  workshopWithDistance
                                                      .addressString,
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (workshop.lat != null &&
                                                  workshop.lng != null)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'GPS',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.green.shade700,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
