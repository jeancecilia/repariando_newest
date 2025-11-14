# Hotfix: Supabase Parameter Compatibility

## Issue
Compilation error when running the web application:

```
lib/src/infra/supabase_provider.dart:20:9: Error: No named parameter with the name 'persistSession'.
```

## Root Cause
The `persistSession` parameter does not exist in Supabase Flutter version 2.9.1. This parameter was added in our authentication route guards implementation but is not available in the current version of the package.

## Solution
**File:** `repariando_web/lib/src/infra/supabase_provider.dart`

**Change:** Removed the `persistSession: true` parameter

**Before:**
```dart
await Supabase.initialize(
  url: url,
  anonKey: anonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
    autoRefreshToken: true,
    persistSession: true,  // ← This parameter doesn't exist
  ),
);
```

**After:**
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

## Important Note
**Session persistence is ENABLED BY DEFAULT** in Supabase Flutter. Removing this parameter does NOT disable session persistence.

Sessions are automatically persisted to:
- **Web:** localStorage
- **Mobile:** Secure storage

The authentication route guards will still work correctly because:
1. ✅ PKCE flow is still enabled
2. ✅ Auto token refresh is still enabled
3. ✅ Session persistence happens automatically
4. ✅ Auth state changes are still monitored

## Impact
- ✅ **No functionality lost** - sessions still persist
- ✅ **No code changes needed** elsewhere
- ✅ **Compilation error resolved**
- ✅ **All features work as intended**

## Testing
After this fix:
- [x] Application compiles without errors
- [x] Login persists after page refresh
- [x] Route guards work correctly
- [x] Auth state changes are detected
- [x] Token auto-refresh works

## Compatibility
This fix is compatible with:
- Supabase Flutter 2.9.1
- Supabase Flutter 2.x (most versions)

If you upgrade to a newer version of Supabase Flutter in the future, check if the `persistSession` parameter has been added and can be explicitly set.

## Status
✅ **FIXED** - Application now runs without errors
✅ **TESTED** - Authentication and session persistence confirmed working
✅ **DOCUMENTED** - Updated AUTH_ROUTE_GUARDS_IMPLEMENTATION.md

## Date
2024-01-XX

## Related Files
- `repariando_web/lib/src/infra/supabase_provider.dart` (fixed)
- `AUTH_ROUTE_GUARDS_IMPLEMENTATION.md` (updated documentation)