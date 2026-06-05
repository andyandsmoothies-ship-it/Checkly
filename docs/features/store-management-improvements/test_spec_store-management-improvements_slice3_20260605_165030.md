# Test Spec: Geocoding Client Service (Slice 3)

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\store-management-improvements\implementation_plan_store-management-improvements_20260605_133000.md`

## Overview
The QA Agent (@Sentinel) has prepared the Unit Tests for the `GeocodingService` in Dart using TDD. The tests are verifying Nominatim API queries to ensure they comply with OpenStreetMap's usage policies (User-Agent header, rate limits, offline state, and throttles).

**Target File**: `lib/_shared/services/geocoding_service.dart`
**Test File**: `test/_shared/services/geocoding_service_test.dart`

## Test Cases Covered
1. **Happy Path (`geocode`)**: Checks that given a valid address, it successfully queries the API and returns a `LatLng` object.
2. **Happy Path (`reverseGeocode`)**: Checks that given a coordinate, it successfully queries the API and returns a parsed `GeocodedAddress` object.
3. **Empty/Not Found (`reverseGeocode`)**: Checks that tapping in water or an unaddressable area returns `null`.
4. **Offline State**: Checks that attempting to query when `ConnectivityService` is offline throws a `GeocodingException` containing "offline" without triggering a Dio network request.
5. **Rate Limited (HTTP 429)**: Checks that receiving a `429` status code throws a `GeocodingException` with `isRateLimited` set to `true`.
6. **Throttle/Debounce**: Checks that rapid successive calls block the second call and throw a throttle exception with a specific message.
7. **Request Headers**: Checks that all Dio requests include the custom `User-Agent` containing "Checkly".

## Decision Log
- Decided to create empty stubs inside `lib/_shared/services/geocoding_service.dart` because TDD tests in Dart require compilation, otherwise they throw syntax/compiler errors instead of test failures.
- Set up MockDio and MockConnectivityService for strict testing of the interactions with external endpoints.

## Verification Handoff
The Builder can run these tests to verify their implementation:

```powershell
cmd /c flutter test test/_shared/services/geocoding_service_test.dart
```

Keep implementing `RealGeocodingService` until all 7 tests in this suite pass!

<test_trace>
{"success":false,"type":"done","time":2609}
</test_trace>

<forensic_evidence>
Ran `cmd /c flutter test --machine test/_shared/services/geocoding_service_test.dart`
</forensic_evidence>
