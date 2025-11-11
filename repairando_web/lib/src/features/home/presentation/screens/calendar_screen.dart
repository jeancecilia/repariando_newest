// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:repairando_web/src/features/home/domain/manual_appointment_model.dart'
//     show ManualAppointment;
// import 'package:repairando_web/src/features/home/presentation/screens/base_layout.dart';
// import 'package:repairando_web/src/router/app_router.dart';
// import 'package:repairando_web/src/theme/theme.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:repairando_web/src/features/home/presentation/controllers/manual_appointment_controller.dart';

// class CalendarScreen extends HookConsumerWidget {
//   const CalendarScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // UPDATED: Using autoDispose provider for real-time updates
//     final manualAppointmentsAsync = ref.watch(manualAppointmentsProvider);
//     final deleteState = ref.watch(deleteManualAppointmentControllerProvider);

//     // Listen to delete state changes
//     ref.listen(deleteManualAppointmentControllerProvider, (previous, next) {
//       next.whenOrNull(
//         error: (err, _) {
//           ScaffoldMessenger.of(context).clearSnackBars();
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 '${'error_deleting_appointment'.tr()}: ${err.toString()}',
//               ),
//               backgroundColor: Colors.red,
//               duration: const Duration(seconds: 4),
//             ),
//           );
//           // Reset state after showing error
//           ref
//               .read(deleteManualAppointmentControllerProvider.notifier)
//               .resetState();
//         },
//         data: (success) {
//           if (success != null && success.isNotEmpty) {
//             ScaffoldMessenger.of(
//               context,
//             ).clearSnackBars(); // Clear existing snackbars
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(success),
//                 backgroundColor: Colors.green,
//                 duration: const Duration(seconds: 2),
//               ),
//             );
//             // Reset state after success
//             ref
//                 .read(deleteManualAppointmentControllerProvider.notifier)
//                 .resetState();
//           }
//         },
//       );
//     });

//     // UPDATED: Auto-refresh every 30 seconds for real-time updates
//     useEffect(() {
//       final timer = Stream.periodic(const Duration(seconds: 30)).listen((_) {
//         ref.invalidate(manualAppointmentsProvider);
//       });
//       return timer.cancel;
//     }, []);

//     return BaseLayout(
//       title: 'calendar_view'.tr(),
//       actions: [
//         ElevatedButton(
//           onPressed: () {
//             context.push(AppRoutes.addManualAppointment);
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppTheme.PRIMARY_COLOR,
//             foregroundColor: Colors.white,
//           ),
//           child: Text('add_appointment'.tr()),
//         ),
//       ],
//       child: Column(
//         children: [
//           // Main Content
//           Expanded(
//             child: SingleChildScrollView(
//               child: Container(
//                 width: double.infinity,
//                 color: Colors.white,
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // UPDATED: Header with refresh button
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Manuelle Buchungen',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             // ADDED: Manual refresh button
//                             IconButton(
//                               onPressed: () {
//                                 ref.invalidate(manualAppointmentsProvider);
//                                 ScaffoldMessenger.of(context).clearSnackBars();
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text(
//                                       'appointments_refreshed'.tr(),
//                                     ),
//                                     backgroundColor: Colors.blue,
//                                     duration: const Duration(seconds: 1),
//                                   ),
//                                 );
//                               },
//                               icon: const Icon(Icons.refresh),
//                               tooltip: 'refresh_appointments'.tr(),
//                             ),
//                             const SizedBox(width: 8),
//                             ElevatedButton(
//                               onPressed: () {
//                                 context.push(AppRoutes.addManualAppointment);
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.white,
//                                 foregroundColor: Colors.orange,
//                                 side: const BorderSide(color: Colors.orange),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(6),
//                                 ),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 20,
//                                   vertical: 12,
//                                 ),
//                               ),
//                               child: Text('add_manual_booking'.tr()),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Divider(color: AppTheme.BORDER_COLOR, height: 1),
//                     const SizedBox(height: 10),

//                     // Manual Appointments Section
//                     manualAppointmentsAsync.when(
//                       data: (appointments) {
//                         if (appointments.isEmpty) {
//                           return SizedBox(
//                             height: 300,
//                             child: Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.calendar_today_outlined,
//                                     size: 64,
//                                     color: Colors.grey[400],
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Text(
//                                     'no_manual_appointments'.tr(),
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       context.push(
//                                         AppRoutes.addManualAppointment,
//                                       );
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: AppTheme.PRIMARY_COLOR,
//                                       foregroundColor: Colors.white,
//                                     ),
//                                     child: Text(
//                                       'create_first_appointment'.tr(),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }

//                         return _buildManualAppointmentsSection(
//                           appointments,
//                           context,
//                           ref,
//                           deleteState, // FIXED: Pass deleteState to the method
//                         );
//                       },
//                       loading:
//                           () => SizedBox(
//                             height: 300,
//                             child: const Center(
//                               child: CircularProgressIndicator(),
//                             ),
//                           ),
//                       error:
//                           (error, stack) => SizedBox(
//                             height: 300,
//                             child: Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.error_outline,
//                                     size: 64,
//                                     color: Colors.red[400],
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Text(
//                                     '${'error_loading_appointments_retry'.tr()}: ${error.toString()}',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       color: Colors.red[600],
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                   const SizedBox(height: 16),
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       ref.invalidate(
//                                         manualAppointmentsProvider,
//                                       );
//                                     },
//                                     child: Text('retry'.tr()),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildManualAppointmentsSection(
//     List<ManualAppointment> appointments,
//     BuildContext context,
//     WidgetRef ref,
//     AsyncValue<String?> deleteState, // FIXED: Added deleteState parameter
//   ) {
//     // UPDATED: Sort appointments by date and time for better organization
//     final sortedAppointments = List<ManualAppointment>.from(appointments);
//     sortedAppointments.sort((a, b) {
//       // First sort by date, then by time
//       final dateComparison = a.appointmentDate.compareTo(b.appointmentDate);
//       if (dateComparison != 0) return dateComparison;
//       return a.appointmentTime.compareTo(b.appointmentTime);
//     });

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: Column(
//             children: [
//               // Table Header
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: const BoxDecoration(
//                   color: AppTheme.LITE_PRIMARY_COLOR,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(8),
//                     topRight: Radius.circular(8),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       flex: 1,
//                       child: Text(
//                         'customer_name'.tr(),
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 2,
//                       child: Text(
//                         'service_name'.tr(),
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),

//                     Expanded(
//                       flex: 1,
//                       child: Text(
//                         'duration'.tr(),
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: Text(
//                         'time_slot'.tr(),
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: Text(
//                         'date'.tr(),
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                     SizedBox(
//                       width: 100,
//                       child: Text(
//                         'status'.tr(),
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 2,
//                       child: Text(
//                         'action'.tr(),
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Table Rows
//               ...sortedAppointments.map(
//                 (appointment) => Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     border: Border(
//                       bottom: BorderSide(color: Colors.grey[200]!),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         flex: 1,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               appointment.customerName,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Expanded(flex: 2, child: Text(appointment.serviceName)),

//                       Expanded(
//                         flex: 1,
//                         child: Text(appointment.durationDisplay),
//                       ),
//                       Expanded(
//                         flex: 1,
//                         child: Text(appointment.appointmentTime),
//                       ),
//                       Expanded(
//                         flex: 1,
//                         child: Text(
//                           appointment.appointmentDate,
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ),
//                       SizedBox(
//                         width: 100,
//                         child: _buildStatusChip(
//                           appointment.status,
//                         ), // ADDED: Status display
//                       ),
//                       Expanded(
//                         flex: 2,
//                         child: Row(
//                           children: [
//                             const SizedBox(width: 5),
//                             // UPDATED: Better loading state for delete button
//                             deleteState.isLoading
//                                 ? const SizedBox(
//                                   width: 80,
//                                   height: 32,
//                                   child: Center(
//                                     child: SizedBox(
//                                       width: 16,
//                                       height: 16,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                                 : ElevatedButton(
//                                   onPressed: () {
//                                     _showDeleteConfirmationDialog(
//                                       context,
//                                       appointment,
//                                       ref,
//                                     );
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.red,
//                                     foregroundColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 10,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(6),
//                                     ),
//                                     minimumSize: const Size(80, 32),
//                                   ),
//                                   child: Text(
//                                     'delete'.tr(),
//                                     style: GoogleFonts.manrope(fontSize: 12),
//                                   ),
//                                 ),
//                             const SizedBox(width: 5),
//                             OutlinedButton(
//                               onPressed: () {
//                                 _showAppointmentDetailsDialog(
//                                   context,
//                                   appointment,
//                                 );
//                               },
//                               style: OutlinedButton.styleFrom(
//                                 foregroundColor: AppTheme.PRIMARY_COLOR,
//                                 side: const BorderSide(
//                                   color: AppTheme.PRIMARY_COLOR,
//                                 ),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 10,
//                                   vertical: 10,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(6),
//                                 ),
//                                 minimumSize: const Size(60, 32),
//                               ),
//                               child: Text(
//                                 'details'.tr(),
//                                 style: GoogleFonts.manrope(fontSize: 12),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ADDED: Status chip widget
//   Widget _buildStatusChip(String? status) {
//     final statusText = status ?? 'pending';
//     Color chipColor;
//     Color textColor;

//     switch (statusText.toLowerCase()) {
//       case 'accepted':
//         chipColor = Colors.green[100]!;
//         textColor = Colors.green[800]!;
//         break;
//       case 'pending':
//         chipColor = Colors.orange[100]!;
//         textColor = Colors.orange[800]!;
//         break;
//       case 'cancelled':
//         chipColor = Colors.red[100]!;
//         textColor = Colors.red[800]!;
//         break;
//       default:
//         chipColor = Colors.grey[100]!;
//         textColor = Colors.grey[800]!;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: chipColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         statusText.toUpperCase(),
//         style: TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.w600,
//           color: textColor,
//         ),
//       ),
//     );
//   }

//   void _showDeleteConfirmationDialog(
//     BuildContext context,
//     ManualAppointment appointment,
//     WidgetRef ref,
//   ) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             backgroundColor: Colors.white,
//             title: Text('confirm_delete'.tr()),
//             content: Text(
//               '${'are_you_sure_delete_appointment'.tr()} ${appointment.customerName}?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: Text('cancel'.tr()),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   ref
//                       .read(deleteManualAppointmentControllerProvider.notifier)
//                       .deleteAppointment(appointment.id);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: Text('delete'.tr()),
//               ),
//             ],
//           ),
//     );
//   }

//   void _showAppointmentDetailsDialog(
//     BuildContext context,
//     ManualAppointment appointment,
//   ) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             backgroundColor: Colors.white,
//             title: Text('appointment_details'.tr()),
//             content: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildDetailRow('customer'.tr(), appointment.customerName),
//                   _buildDetailRow('service'.tr(), appointment.serviceName),
//                   _buildDetailRow(
//                     'vehicle'.tr(),
//                     '${appointment.vehicleMake} ${appointment.vehicleModel} (${appointment.vehicleYear})',
//                   ),
//                   _buildDetailRow('date'.tr(), appointment.appointmentDate),
//                   _buildDetailRow('time'.tr(), appointment.timeSlotDisplay),
//                   _buildDetailRow(
//                     'duration_display'.tr(),
//                     appointment.durationDisplay,
//                   ),
//                   _buildDetailRow('price'.tr(), '€${appointment.price}'),
//                   _buildDetailRow('email'.tr(), appointment.emailAddress),
//                   _buildDetailRow('phone'.tr(), appointment.phoneNumber),
//                   _buildDetailRow(
//                     'status'.tr(),
//                     appointment.status ?? 'pending',
//                   ), // ADDED: Status in details
//                   if (appointment.additionalNotes != null &&
//                       appointment.additionalNotes!.isNotEmpty)
//                     _buildDetailRow('notes'.tr(), appointment.additionalNotes!),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: Text('close'.tr()),
//               ),
//             ],
//           ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }
// }
