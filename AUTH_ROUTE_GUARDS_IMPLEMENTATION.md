# Authentication Route Guards Implementation

## Overview
This document describes the authentication route guards implementation to prevent users from being locked out when refreshing the browser in the web application.

## Problem
When users refreshed the browser, the authentication state was not properly checked, causing them to be redirected to the login screen even though they had valid sessions.

## Solution Implemented

### 1. Enhanced Router Configuration (`app_router.dart`)

#### Added Authentication State Listener
```dart
refreshListenable: GoRouterRefreshStream(
  authRepository.client.auth.onAuthStateChange,
)
```
This ensures the router automatically updates when the authentication state changes (login, logout, session refresh).

#### Implemented Route Guards
Added comprehensive redirect logic that:
- **Protects authenticated routes**: Redirects unauthenticated users trying to access protected routes to login
- **Prevents duplicate login**: Redirects authenticated users trying to access auth pages back to home
- **Allows splash screen**: Special handling for the splash screen during app initialization

```dart
redirect: (context, state) {
  final isAuthenticated = authRepository.isAuthenticated;
  final isGoingToAuth = _isAuthRoute(state.matchedLocation);
  final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

  // If not authenticated and trying to access protected route, redirect to login
  if (!isAuthenticated && !isGoingToAuth && !isGoingToSplash) {
    return AppRoutes.login;
  }

  // If authenticated and trying to access auth routes, redirect to home
  if (isAuthenticated && isGoingToAuth) {
    return AppRoutes.home;
  }

  // No redirect needed
  return null;
}
```

#### Created GoRouterRefreshStream
A custom `ChangeNotifier` that listens to Supabase auth state changes and notifies the router to re-evaluate routes:

```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (AuthState _) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

### Enhanced Supabase Configuration (`supabase_provider.dart`)

Added proper session persistence configuration:

```dart
await Supabase.initialize(
  url: url,
  anonKey: anonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
    autoRefreshToken: true,
  ),
);
```

**Key features:**
- **PKCE Flow**: Uses Proof Key for Code Exchange for enhanced security
- **Auto Refresh**: Automatically refreshes tokens before expiration
- **Persist Session**: Enabled by default - saves session to local storage (localStorage on web, secure storage on mobile)

**Note:** Session persistence is enabled by default in Supabase Flutter. The `persistSession` parameter is not available in version 2.9.1 but sessions are automatically persisted.

### 3. Fixed Null Safety Issue (`request_detail_screen.dart`)

Fixed a null-pointer exception:
```dart
// Before (incorrect):
text: appointment.issueNote! ?? '',

// After (correct):
text: appointment.issueNote ?? '',
```

## Authentication Flow

### On App Start
1. App initializes Supabase with session persistence
2. Router checks for existing session via `authRepository.isAuthenticated`
3. Splash screen displays while authentication state is determined
4. Router redirects to appropriate screen:
   - **Has valid session** → Home screen
   - **No session** → Login screen

### On Page Refresh
1. Supabase automatically restores session from localStorage
2. Router's `refreshListenable` triggers re-evaluation
3. Route guards check authentication and redirect if needed
4. User stays on the current page (if authorized) or redirects to login

### On Login
1. User authenticates via Supabase
2. Session is stored in localStorage
3. Auth state change triggers router refresh
4. Route guard redirects to home screen

### On Logout
1. Supabase session is cleared
2. Auth state change triggers router refresh
3. Route guard redirects to login screen

## Protected Routes

The following routes require authentication:
- `/home` - Home screen
- `/upcoming-appointments` - Upcoming appointments
- `/service-management` - Service management
- `/messages` - Messages
- `/request-detail` - Request details
- `/workshop-settings` - Workshop settings
- `/add-manual-appointment` - Add manual appointment

## Public Routes

The following routes are accessible without authentication:
- `/` - Splash screen
- `/login` - Login screen
- `/registration` - Registration screen
- `/forgetPassword` - Forgot password
- `/otpVerification` - OTP verification
- `/workshopProfileSetup` - Workshop profile setup

## Testing

### Manual Testing Scenarios

1. **Refresh while logged in**
   - Login to the app
   - Navigate to any protected page
   - Refresh the browser (F5 or Ctrl+R)
   - ✅ Should stay on the same page

2. **Refresh while logged out**
   - Ensure you're logged out
   - Try to access a protected route directly via URL
   - ✅ Should redirect to login

3. **Direct URL access while authenticated**
   - Login to the app
   - Try to navigate to `/login` via URL
   - ✅ Should redirect to home

4. **Session expiration**
   - Login to the app
   - Wait for session to expire (or manually clear localStorage)
   - Try to navigate
   - ✅ Should redirect to login

5. **Cross-tab synchronization**
   - Login in one browser tab
   - Open another tab with the app
   - ✅ Should be logged in both tabs
   - Logout in one tab
   - ✅ Other tab should also logout

## Benefits

1. **Persistent Sessions**: Users stay logged in across page refreshes
2. **Automatic Token Refresh**: Sessions are automatically renewed before expiration
3. **Secure Authentication**: Uses PKCE flow for enhanced security
4. **Better UX**: No unexpected logouts or redirects
5. **Cross-tab Sync**: Auth state is synchronized across browser tabs
6. **Mobile Compatibility**: Same logic works for mobile app

## Security Considerations

- Sessions are stored securely using browser's localStorage (encrypted by Supabase SDK)
- PKCE flow prevents authorization code interception attacks
- Auto-refresh ensures tokens are always valid
- Route guards prevent unauthorized access to protected routes
- Auth state is validated server-side by Supabase

## Maintenance Notes

- Auth routes are defined in `_isAuthRoute()` function - update this list when adding new auth pages
- Session timeout is controlled by Supabase JWT settings (default: 1 hour access token, 7 days refresh token)
- To customize session duration, update Supabase project settings in the dashboard

## Troubleshooting

### Issue: Still getting logged out on refresh
**Solution**: Clear browser cache and localStorage, then login again

### Issue: Infinite redirect loop
**Solution**: Check that the route is properly categorized in `_isAuthRoute()` function

### Issue: Session not persisting
**Solution**: Verify that `persistSession: true` is set in Supabase initialization

### Issue: Mobile app not syncing with web
**Solution**: Ensure both apps use the same Supabase project and have identical auth configuration

## Future Enhancements

Potential improvements for the future:
- Add role-based access control (RBAC) for different user types
- Implement biometric authentication for mobile
- Add session activity timeout (logout after X minutes of inactivity)
- Implement remember me functionality with extended session duration
- Add multi-factor authentication (MFA) support