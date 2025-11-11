import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart'; // Add this dependency
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/features/auth/domain/workshop_registration_model.dart';
import 'package:repairando_web/src/features/auth/presentation/controllers/workshop_profile_controller.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/widgets/primary_button.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WorkshopProfileSetupScreen extends HookConsumerWidget {
  const WorkshopProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workshopNameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final phoneController = useTextEditingController();
    final emailController = useTextEditingController();
    final streetController = useTextEditingController();
    final numberController = useTextEditingController();
    final postalCodeController = useTextEditingController();
    final cityController = useTextEditingController();
    final companyNameController = useTextEditingController();
    final commercialRegisterNumberController = useTextEditingController();
    final registerCourtController = useTextEditingController();
    final vatIdController = useTextEditingController();

    final profileImage = useState<Uint8List?>(null);
    final legalDocument = useState<Uint8List?>(null);
    final currentStep = useState(1);
    final authState = ref.watch(workshopProfileControllerProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Location states
    final latitude = useState<double?>(null);
    final longitude = useState<double?>(null);
    final isGettingLocation = useState(false);
    final locationStatus = useState<String>('');

    ref.listen<AsyncValue<void>>(workshopProfileControllerProvider, (
      prev,
      next,
    ) {
      if (next is AsyncData) {
        context.go(AppRoutes.home);
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    // Location permission and getting current location
    Future<void> getCurrentLocation() async {
      isGettingLocation.value = true;
      locationStatus.value = 'getting_location'.tr();

      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          locationStatus.value = 'location_service_disabled'.tr();
          _showLocationServiceDialog(context, getCurrentLocation);
          isGettingLocation.value = false;
          return;
        }

        // Check location permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            locationStatus.value = 'location_permission_denied'.tr();
            _showPermissionDialog(context, getCurrentLocation);
            isGettingLocation.value = false;
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          locationStatus.value = 'location_permission_permanently_denied'.tr();
          _showOpenSettingsDialog(context);
          isGettingLocation.value = false;
          return;
        }

        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );

        latitude.value = position.latitude;
        longitude.value = position.longitude;
        locationStatus.value = 'location_obtained'.tr();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('location_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        locationStatus.value = 'location_error'.tr();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'location_error'.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        isGettingLocation.value = false;
      }
    }

    // Call getCurrentLocation when the screen is first built
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        getCurrentLocation();
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: AppTheme.LITE_PRIMARY_COLOR,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              context.pop();
            },
            child: Image.asset(AppImages.APP_LOGO, height: 40),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Form(
              key: formKey,
              child: ListView(
                children: [
                  Center(
                    child: Text(
                      'workshop_profile_setup'.tr(),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 31,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          currentStep.value == 1
                              ? Icon(
                                Icons.radio_button_checked,
                                color: AppTheme.PRIMARY_COLOR,
                              )
                              : Image.asset(AppImages.DONE_CIRCLE),
                          const SizedBox(height: 4),
                          Text(
                            'step1'.tr(),
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'workshop_info'.tr(),
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Divider(color: Colors.grey, thickness: 2),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        children: [
                          currentStep.value == 1
                              ? Icon(
                                Icons.radio_button_unchecked,
                                color: AppTheme.PRIMARY_COLOR,
                              )
                              : Icon(
                                Icons.radio_button_checked,
                                color: AppTheme.PRIMARY_COLOR,
                              ),
                          const SizedBox(height: 4),
                          Text(
                            'step2'.tr(),
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'legal_info'.tr(),
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (currentStep.value == 1) ...[
                    Text(
                      'profile_picture_upload'.tr(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.black12,
                          backgroundImage:
                              profileImage.value != null
                                  ? MemoryImage(profileImage.value!)
                                  : null,
                          child:
                              profileImage.value == null
                                  ? Image.asset(AppImages.UPLOAD_IMAGE)
                                  : null,
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
                                  profileImage.value =
                                      result.files.single.bytes!;
                                }
                              } else {}
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2F3D52),
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            'select'.tr(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      'gewerbeanmeldung'.tr(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 80,
                          width: 150,
                          child:
                              legalDocument.value == null
                                  ? Image.asset(AppImages.UPLOAD_DOCUMENT)
                                  : const Icon(
                                    Icons.insert_drive_file,
                                    size: 36,
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
                                  legalDocument.value =
                                      result.files.single.bytes!;
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2F3D52),
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            'select_documents'.tr(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],

                  currentStep.value == 1
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('workshop_name'.tr()),
                          TextFormField(
                            controller: workshopNameController,
                            validator: _requiredValidator,
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'workshop_name_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildLabel('short_description'.tr()),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 4,
                            validator: _requiredValidator,
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'short_description_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildLabel('phone_number'.tr()),
                          TextFormField(
                            controller: phoneController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'phone_required'.tr();
                              }
                              if (!RegExp(r'^[\d +]+$').hasMatch(value)) {
                                return 'phone_invalid'.tr();
                              }
                              return null;
                            },
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'phone_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildLabel('email_address'.tr()),
                          TextFormField(
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'email_required'.tr();
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value)) {
                                return 'email_invalid'.tr();
                              }
                              return null;
                            },
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: "e.g., info@example.com",
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('business_address'.tr()),
                          TextFormField(
                            controller: streetController,
                            validator: _requiredValidator,
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'street_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: numberController,
                                  validator: _requiredValidator,
                                  decoration: AppTheme.textFieldDecoration
                                      .copyWith(hintText: 'number_hint'.tr()),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextFormField(
                                  controller: postalCodeController,
                                  validator: _requiredValidator,
                                  decoration: AppTheme.textFieldDecoration
                                      .copyWith(
                                        hintText: 'postal_code_hint'.tr(),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: cityController,
                            validator: _requiredValidator,
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'city_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildLabel('company_name'.tr()),
                          TextFormField(
                            controller: companyNameController,
                            validator: _requiredValidator,
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'full_legal_name_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildLabel('commercial_register_number'.tr()),
                          TextFormField(
                            controller: commercialRegisterNumberController,
                            validator: _requiredValidator,
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'commercial_register_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildLabel('register_court'.tr()),
                          TextFormField(
                            controller: registerCourtController,
                            validator: _requiredValidator,
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'register_court_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildLabel('vat_id_ust'.tr()),
                          TextFormField(
                            controller: vatIdController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'vat_required'.tr();
                              }
                              // You can add the VAT format validation if needed
                              // if (!RegExp(r'^DE\d{9}$').hasMatch(value)) {
                              //   return 'vat_invalid'.tr();
                              // }
                              return null;
                            },
                            decoration: AppTheme.textFieldDecoration.copyWith(
                              hintText: 'vat_id_hint'.tr(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                  currentStep.value == 1
                      ? PrimaryButton(
                        text: 'next'.tr(),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            if (latitude.value == null ||
                                longitude.value == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('location_required'.tr()),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              // Call getCurrentLocation again to make it compulsory
                              getCurrentLocation();
                              return;
                            }
                            currentStep.value = 2;
                          }
                        },
                      )
                      : PrimaryButton(
                        text: authState.isLoading ? null : 'register_shop'.tr(),
                        onPressed:
                            authState.isLoading
                                ? null
                                : () {
                                  if (!formKey.currentState!.validate()) return;

                                  if (profileImage.value == null ||
                                      legalDocument.value == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('missing_files'.tr()),
                                      ),
                                    );
                                    return;
                                  }

                                  if (latitude.value == null ||
                                      longitude.value == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('location_required'.tr()),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  final model = WorkshopRegistrationModel(
                                    profileImage: profileImage.value,
                                    legalDocument: legalDocument.value,
                                    workshopName:
                                        workshopNameController.text.trim(),
                                    shortDescription:
                                        descriptionController.text.trim(),
                                    phoneNumber: phoneController.text.trim(),
                                    email: emailController.text.trim(),
                                    street: streetController.text.trim(),
                                    number: numberController.text.trim(),
                                    postalCode:
                                        postalCodeController.text.trim(),
                                    city: cityController.text.trim(),
                                    companyName:
                                        companyNameController.text.trim(),
                                    commercialRegisterNumber:
                                        commercialRegisterNumberController.text
                                            .trim(),
                                    registerCourt:
                                        registerCourtController.text.trim(),
                                    vatId: vatIdController.text.trim(),
                                    lat: latitude.value!.toString(),
                                    lng: longitude.value!.toString(),
                                  );

                                  ref
                                      .read(
                                        workshopProfileControllerProvider
                                            .notifier,
                                      )
                                      .completeWorkshopProfile(model);
                                },
                        child:
                            authState.isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : null,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'this_field_required'.tr();
    }
    return null;
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  // Dialog for when location service is disabled
  void _showLocationServiceDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('location_service_required'.tr()),
          content: Text('location_service_message'.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text('retry'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                onRetry();
              },
              child: Text('open_settings'.tr()),
            ),
          ],
        );
      },
    );
  }

  // Dialog for when permission is denied
  void _showPermissionDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('location_permission_required'.tr()),
          content: Text('location_permission_message'.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text('allow_permission'.tr()),
            ),
          ],
        );
      },
    );
  }

  // Dialog for when permission is permanently denied
  void _showOpenSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('location_permission_permanently_denied'.tr()),
          content: Text('location_permission_settings_message'.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: Text('open_settings'.tr()),
            ),
          ],
        );
      },
    );
  }
}
