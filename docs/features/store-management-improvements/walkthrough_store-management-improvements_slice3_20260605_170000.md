---
ConversationID: 43a6d3be-90b3-4a93-b845-d4413b14705f
---

# Walkthrough: Store Management Improvements - Slice 3

This walkthrough details the changes made in Slice 3 (Geocoding Client Service (Nominatim)).

## 1. Technical Changes

### Geocoding Client Service
File: `lib/_shared/services/geocoding_service.dart`
- Completed the implementation of `RealGeocodingService` utilizing Nominatim endpoints (`https://nominatim.openstreetmap.org/search` and `/reverse`).
- Added a custom `User-Agent` (`Checkly-Mobile-App/1.0 (contact@checkly.com)`) in the headers of all Nominatim network requests.
- Integrated a client-side throttle check (`_checkThrottle`) which throws a `GeocodingException` containing `"Too many requests"` if a call is initiated less than 1.5 seconds after the previous call.
- Incorporated offline detection via `ConnectivityService.isOnline` check before launching any HTTP queries, failing fast with a `GeocodingException` containing `"offline"`.
- Implemented robust parsing for geocoding search results and reverse geocoding addresses, handling invalid/empty responses, missing province/district elements, and water zones.
- Mapped HTTP 429 status code responses to `GeocodingException` with `isRateLimited` set to `true` to allow the presentation layer to render appropriate alerts.

## 2. Test Verification

Run the Flutter unit tests to verify proper client service behaviour:
```powershell
cmd /c "rtk proxy flutter test ../test/_shared/services/geocoding_service_test.dart"
```

All 7 test cases passed successfully, confirming:
- Happy paths (`geocode` and `reverseGeocode`).
- Graceful null fallback for water/empty regions.
- Fast failure when device is offline.
- Custom User-Agent header transmission.
- Client-side 1.5-second debounce/throttle block.
- Error code 429 map translation.
