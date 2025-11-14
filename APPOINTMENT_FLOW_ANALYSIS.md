# Appointment Flow Analysis

## Executive Summary

The app **PARTIALLY** implements the described two-type appointment system. The infrastructure exists, but **critical functionality is missing** on the mobile app side for customers to accept/reject offers.

---

## Current Implementation Status

### ✅ IMPLEMENTED: Two Types of Services

The system correctly distinguishes between two service types:

#### 1. **Fixed Price Services** (`service.price > 0`)
- Has predefined price and duration
- Displayed with **brown/orange background** in mobile app
- Customer can book directly with time selection

#### 2. **Offer-Based Services** (`service.price == 0.0`)
- No predefined price (price stored as 0.0 in database)
- Duration may or may not be set
- Displayed with **yellow background** in mobile app
- Customer requests appointment, workshop sends offer

**Location:** `repariando_mobile/lib/src/features/home/presentation/screens/workshop_profile_screen.dart` (Lines 375-396)

```dart
if (service.price == 0.0) {
  // Navigate to offer-based flow
  context.push(AppRoutes.offerServiceDetail, ...);
} else {
  // Navigate to fixed-price flow
  context.push(AppRoutes.serviceDetail, ...);
}
```

---

## Workflow Analysis

### 🟢 Fixed Price Services - **FULLY WORKING**

**Customer Flow (Mobile App):**
1. ✅ Customer views workshop profile
2. ✅ Selects fixed-price service (price > 0)
3. ✅ Books appointment with date/time selection
4. ✅ Appointment created with status: `pending`

**Workshop Flow (Admin Panel):**
1. ✅ Workshop sees appointment in "Pending Requests"
2. ✅ Can view appointment details
3. ✅ Can **Accept** appointment → Status: `accepted`
4. ✅ Can **Reject** appointment → Status: `rejected`

**Implementation Files:**
- Mobile: `fixed_price/service_detail_screen.dart`
- Mobile: `fixed_price/schedule_time_screen.dart`
- Mobile: `fixed_price/new_appointment_screen.dart`
- Web: `home_screen.dart` (Accept/Reject buttons)
- Web: `request_detail_screen.dart` (Accept/Reject actions)

---

### 🟡 Offer-Based Services - **PARTIALLY WORKING**

**Customer Flow (Mobile App):**
1. ✅ Customer views workshop profile
2. ✅ Selects offer-based service (price = 0)
3. ✅ Requests appointment (no time selection required)
4. ✅ Appointment created with status: `pending`
5. ✅ Customer can view pending request in "Waiting for Response" section
6. ✅ After workshop sends offer, status changes to: `awaiting_offer`
7. ✅ Offer appears in "Offers Available" section with price displayed
8. ❌ **MISSING:** Customer cannot accept/reject the offer
9. ❌ **MISSING:** No buttons or actions available in booking summary

**Workshop Flow (Admin Panel):**
1. ✅ Workshop sees request in "Pending Requests"
2. ✅ Can view request details
3. ✅ Can click "Make an Offer" button
4. ✅ Dialog opens to enter price and work units
5. ✅ Sends offer → Status: `awaiting_offer`, price updated
6. ❌ **ISSUE:** After sending offer, workshop has no way to know if customer accepted

**Implementation Files:**
- Mobile: `offer_price/offer_service_detail_screen.dart`
- Mobile: `offer_price/offer_new_appointment_screen.dart`
- Mobile: `pending_appointment_screen.dart` (Shows offers but no action)
- Mobile: `booking_summary_screen.dart` (No accept/reject buttons)
- Web: `make_offer_dialog.dart` (Fully functional)
- Web: `appointment_repository.dart` → `sendOffer()` method

---

## Database Schema

### Services Table
```sql
- id (uuid)
- category (text)
- service (text)
- description (text)
- price (text)  -- Stores "0" for offer-based, actual value for fixed
- duration (text)
- workUnit (text)
```

### Admin Services Table (Junction Table)
```sql
- id (int)
- admin_id (uuid)
- service_id (uuid)
- is_available (boolean)
- price (double) -- 0.0 for offer-based services
- duration_minutes (text)
```

### Appointments Table
```sql
- id (uuid)
- workshop_id (uuid)
- vehicle_id (uuid)
- service_id (uuid)
- customer_id (uuid)
- appointment_time (text)
- appointment_date (text)
- appointment_status (text) -- 'pending', 'awaiting_offer', 'accepted', 'rejected', 'completed', 'cancelled'
- issue_note (text, nullable)
- price (text) -- Updated when workshop sends offer
- needed_work_unit (text, nullable) -- Set by workshop when sending offer
```

---

## Appointment Status Flow

### Fixed Price Services
```
Customer Books
     ↓
[pending] ← Workshop sees in "Pending Requests"
     ↓
Workshop Accept/Reject
     ↓
[accepted] or [rejected] ← Final status
     ↓
[completed] ← After service done
```

### Offer-Based Services (Current)
```
Customer Requests
     ↓
[pending] ← Workshop sees in "Pending Requests"
     ↓
Workshop Sends Offer (price + work units)
     ↓
[awaiting_offer] ← Customer sees in "Offers Available"
     ↓
❌ STUCK HERE - No way to proceed
     ↓
SHOULD BE: Customer Accept/Reject
     ↓
[accepted] or [rejected] ← Final status
```

---

## Critical Gaps

### 🚨 Missing Functionality

#### 1. **Customer Cannot Accept/Reject Offers (Mobile App)**

**Current State:**
- `booking_summary_screen.dart` only displays information
- No buttons for accept/reject actions
- No API calls to update appointment status

**What's Needed:**
- Add "Accept Offer" button
- Add "Decline Offer" button
- Implement API call to update status from `awaiting_offer` to `accepted` or `rejected`
- Update UI to reflect status change

**Expected Behavior:**
```dart
// In booking_summary_screen.dart - MISSING
if (appointment.appointmentStatus == 'awaiting_offer') {
  // Show Accept & Decline buttons
  Row(
    children: [
      ElevatedButton(
        onPressed: () => acceptOffer(appointment.id),
        child: Text('Accept Offer'),
      ),
      OutlinedButton(
        onPressed: () => rejectOffer(appointment.id),
        child: Text('Decline'),
      ),
    ],
  )
}
```

#### 2. **No API Endpoints for Customer Actions**

**Repository:** `repariando_mobile/lib/src/features/appointment/data/appointment_repository.dart`

**Missing Methods:**
```dart
// MISSING: Method to accept offer
Future<bool> acceptOffer(String appointmentId) async {
  // Update status to 'accepted'
}

// MISSING: Method to reject offer
Future<bool> rejectOffer(String appointmentId) async {
  // Update status to 'rejected'
}
```

**Note:** The web admin panel already has these methods:
- `acceptAppointment()` - Line 575
- `rejectAppointment()` - Line 583

But these are workshop-side actions, not customer actions.

#### 3. **Notification System**

**Missing:**
- No notification to customer when offer is sent
- No notification to workshop when customer accepts/rejects
- Both parties need real-time updates

---

## Code References

### Mobile App (Customer Side)

#### Service Type Detection
**File:** `workshop_profile_screen.dart` (Line 375)
```dart
if (service.price == 0.0) {
  // Offer-based service
  context.push(AppRoutes.offerServiceDetail, ...);
} else {
  // Fixed-price service
  context.push(AppRoutes.serviceDetail, ...);
}
```

#### Pending Appointments View
**File:** `pending_appointment_screen.dart` (Line 50-55)
```dart
// Separates waiting vs offer-available appointments
final waitingAppointments = pendingAppointmentsState.appointments
    .where((appointment) => 
        appointment.appointmentStatus.toLowerCase() == 'pending' ||
        appointment.price == '0.0')
    .toList();

final offerAppointments = offerAvailableAppointmentsState.appointments;
```

#### Offer Fetching
**File:** `appointment_repository.dart` (Line 306-336)
```dart
Future<List<AppointmentModel>> getOfferAvailableAppointments(
  String customerId,
) async {
  final response = await _client
      .from('appointments')
      .select('''...''')
      .eq('customer_id', customerId)
      .eq('appointment_status', 'awaiting_offer')
      .order('created_at', ascending: false);
}
```

### Web Admin Panel (Workshop Side)

#### Send Offer Dialog
**File:** `make_offer_dialog.dart` (Line 109)
```dart
final success = await appointmentRepository.sendOffer(
  appointmentId: appointment.id,
  price: price,
  neededWorkUnit: workUnits,
);
```

#### Send Offer Implementation
**File:** `appointment_repository.dart` (Line 739-777)
```dart
Future<bool> sendOffer({
  required String appointmentId,
  required double price,
  required String neededWorkUnit,
}) async {
  final updates = {
    'price': price,
    'needed_work_unit': neededWorkUnit,
    'appointment_status': 'awaiting_offer', // ← Status change
  };
  
  await _client
      .from('appointments')
      .update(updates)
      .eq('id', appointmentId)
      .eq('workshop_id', userId);
}
```

#### Accept/Reject Appointments (Workshop Side)
**File:** `appointment_repository.dart` (Line 575-588)
```dart
// Workshop accepts fixed-price appointment
Future<bool> acceptAppointment(String appointmentId) async {
  return await updateAppointmentStatus(
    appointmentId: appointmentId,
    newStatus: 'accepted',
  );
}

// Workshop rejects appointment
Future<bool> rejectAppointment(String appointmentId) async {
  return await updateAppointmentStatus(
    appointmentId: appointmentId,
    newStatus: 'rejected',
  );
}
```

---

## Recommendations

### Priority 1: Complete Offer Acceptance Flow

#### Step 1: Add Customer Accept/Reject Methods
**File:** `repariando_mobile/lib/src/features/appointment/data/appointment_repository.dart`

```dart
// Add these methods
Future<bool> acceptOffer(String appointmentId) async {
  try {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    await _client
        .from('appointments')
        .update({'appointment_status': 'accepted'})
        .eq('id', appointmentId)
        .eq('customer_id', userId);

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> declineOffer(String appointmentId) async {
  try {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    await _client
        .from('appointments')
        .update({'appointment_status': 'rejected'})
        .eq('id', appointmentId)
        .eq('customer_id', userId);

    return true;
  } catch (e) {
    return false;
  }
}
```

#### Step 2: Update Booking Summary Screen
**File:** `booking_summary_screen.dart`

Add conditional buttons at the bottom:

```dart
// After displaying all info, before closing Column
if (appointmentModel.appointmentStatus == 'awaiting_offer') {
  SizedBox(height: 30.h),
  Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Decline Offer'),
                content: Text('Are you sure you want to decline this offer?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Decline'),
                  ),
                ],
              ),
            );
            
            if (confirmed == true) {
              final success = await ref
                  .read(appointmentRepositoryProvider)
                  .declineOffer(appointmentModel.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Offer declined')),
                );
                context.pop(); // Go back to pending appointments
              }
            }
          },
          child: Text('Decline Offer'),
        ),
      ),
      SizedBox(width: 16),
      Expanded(
        child: ElevatedButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Accept Offer'),
                content: Text('Accept this offer and proceed with booking?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Accept'),
                  ),
                ],
              ),
            );
            
            if (confirmed == true) {
              final success = await ref
                  .read(appointmentRepositoryProvider)
                  .acceptOffer(appointmentModel.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Offer accepted!')),
                );
                context.pop(); // Go back to appointments
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.PRIMARY_COLOR,
          ),
          child: Text('Accept Offer'),
        ),
      ),
    ],
  ),
}
```

#### Step 3: Add State Management
**File:** `appointment_controller.dart`

```dart
final offerActionProvider = StateNotifierProvider<OfferActionController, AsyncValue<bool>>((ref) {
  final repository = ref.read(appointmentRepositoryProvider);
  return OfferActionController(repository);
});

class OfferActionController extends StateNotifier<AsyncValue<bool>> {
  final AppointmentRepository _repository;

  OfferActionController(this._repository) : super(const AsyncData(false));

  Future<void> acceptOffer(String appointmentId) async {
    state = const AsyncLoading();
    try {
      final success = await _repository.acceptOffer(appointmentId);
      state = AsyncData(success);
      
      if (success) {
        // Refresh appointment lists
        // ref.invalidate(pendingAppointmentsControllerProvider);
        // ref.invalidate(offerAvailableAppointmentsControllerProvider);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> declineOffer(String appointmentId) async {
    state = const AsyncLoading();
    try {
      final success = await _repository.declineOffer(appointmentId);
      state = AsyncData(success);
      
      if (success) {
        // Refresh appointment lists
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
```

### Priority 2: Add Notifications

1. **Push Notifications:** Use Firebase Cloud Messaging
2. **In-App Notifications:** Add notification icon badge
3. **Email Notifications:** Send confirmation emails

### Priority 3: Add Time Selection for Offer-Based

Currently, offer-based appointments skip time selection. Consider adding:
- Optional time selection in offer request
- Workshop can suggest times when sending offer
- Customer selects time when accepting offer

---

## Testing Checklist

### Fixed Price Services (Currently Working)
- [ ] Customer can view fixed-price service
- [ ] Customer can book with time selection
- [ ] Appointment appears in workshop pending requests
- [ ] Workshop can accept appointment
- [ ] Workshop can reject appointment
- [ ] Status updates correctly

### Offer-Based Services (Needs Implementation)
- [ ] Customer can view offer-based service (different color)
- [ ] Customer can request appointment
- [ ] Request appears in workshop pending requests
- [ ] Workshop can send offer with price
- [ ] Offer appears in customer "Offers Available" with price displayed
- [ ] **Customer can accept offer** ← MISSING
- [ ] **Customer can decline offer** ← MISSING
- [ ] Status updates to 'accepted' or 'rejected'
- [ ] Workshop can see accepted/rejected status

---

## Conclusion

**Current Status:** 🟡 **PARTIALLY IMPLEMENTED**

**What Works:**
- ✅ Service type distinction (price-based logic)
- ✅ Different booking flows for each type
- ✅ Workshop can send offers
- ✅ Customer can view offers

**What's Missing:**
- ❌ Customer cannot accept/reject offers
- ❌ No API methods for customer offer actions
- ❌ No UI buttons in booking summary screen
- ❌ No notification system

**Effort to Complete:**
- **Backend:** Low (methods similar to workshop accept/reject)
- **Frontend:** Medium (UI updates, state management)
- **Testing:** Medium (need to test full flow)
- **Estimated Time:** 4-6 hours for a developer familiar with the codebase

The infrastructure is solid, but the critical "customer decision" step is missing, making the offer-based system incomplete.