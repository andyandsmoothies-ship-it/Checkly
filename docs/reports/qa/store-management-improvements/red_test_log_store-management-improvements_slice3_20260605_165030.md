# Red Test Log: Geocoding Client Service (Slice 3)

## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\features\store-management-improvements\implementation_plan_store-management-improvements_20260605_133000.md`

## Terminal Output (Flutter Test JSON Summary)
<test_trace>
{"testID":4,"error":"UnimplementedError","stackTrace":"package:checkly/_shared/services/geocoding_service.dart 47:5  RealGeocodingService.geocode\ntest\\_shared\\services\\geocoding_service_test.dart 58:36       main.<fn>.<fn>\n","isFailure":false,"type":"error","time":2511}
{"testID":5,"error":"UnimplementedError","stackTrace":"package:checkly/_shared/services/geocoding_service.dart 52:5  RealGeocodingService.reverseGeocode\ntest\\_shared\\services\\geocoding_service_test.dart 88:36       main.<fn>.<fn>\n","isFailure":false,"type":"error","time":2520}
{"testID":6,"error":"UnimplementedError","stackTrace":"package:checkly/_shared/services/geocoding_service.dart 52:5  RealGeocodingService.reverseGeocode\ntest\\_shared\\services\\geocoding_service_test.dart 116:36      main.<fn>.<fn>\n","isFailure":false,"type":"error","time":2527}
{"testID":7,"error":"Expected: throws <Instance of 'GeocodingException'> with `message`: contains 'offline'\n  Actual: <Closure: () => Future<LatLng?>>\n   Which: threw UnimplementedError:<UnimplementedError>\n          which is not an instance of 'GeocodingException'\n","isFailure":true,"type":"error","time":2550}
{"testID":8,"error":"Expected: throws <Instance of 'GeocodingException'> with `isRateLimited`: <true>\n  Actual: <Closure: () => Future<LatLng?>>\n   Which: threw UnimplementedError:<UnimplementedError>\n          which is not an instance of 'GeocodingException'\n","isFailure":true,"type":"error","time":2561}
{"testID":9,"error":"UnimplementedError","stackTrace":"package:checkly/_shared/services/geocoding_service.dart 47:5  RealGeocodingService.geocode\ntest\\_shared\\services\\geocoding_service_test.dart 171:31      main.<fn>.<fn>\n","isFailure":false,"type":"error","time":2568}
{"testID":10,"error":"UnimplementedError","stackTrace":"package:checkly/_shared/services/geocoding_service.dart 47:5  RealGeocodingService.geocode\ntest\\_shared\\services\\geocoding_service_test.dart 204:21      main.<fn>.<fn>\n","isFailure":false,"type":"error","time":2573}
{"success":false,"type":"done","time":2609}
</test_trace>

<forensic_evidence>
Ran `cmd /c flutter test --machine test/_shared/services/geocoding_service_test.dart`
</forensic_evidence>
