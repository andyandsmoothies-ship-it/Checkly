# Walkthrough: SL-2 TDD Province Benchmark

## Overview
I executed the `/tdd` workflow for Slice 2 of the Area Deprecation epic. I translated the acceptance criteria into two test classes covering the backend calculator and endpoint logic.

## Steps Taken
1. **Reviewed Testing Strategy**: Loaded the `.agents/skills/testing-strategy/SKILL.md` to ensure compliance with the Detroit-school TDD style, AAA pattern, and xUnit best practices.
2. **Created `ProvinceBenchmarkCalculatorTests.cs`**:
   - Covers TC-SL2-01 to TC-SL2-03.
   - Built a comprehensive test data seeding method (`SeedTestDataAsync`) covering multiple provinces (Hồ Chí Minh, Hà Nội, and null) to verify calculation rules, threshold skipping (min 3 audits), and null safeguards.
   - Tested against the non-existent `ProvinceBenchmarkCalculator.RunForAllProvincesAsync` method (expected compilation failure).
3. **Created `ProvinceLeaderboardEndpointTests.cs`**:
   - Covers TC-SL2-04 to TC-SL2-06.
   - Written integration tests using `TestWebApplicationFactory` for `GET /api/analytics/area-leaderboard?province=X` and `GET /api/analytics?storeId={id}`.
   - Tested against the non-existent `ProvinceBenchmarkSnapshot` entity (expected compilation failure).
4. **Verified AAA Pattern**:
   - Executed `verify_aaa_pattern.py` script. The new test classes are 100% compliant with exactly one `// Act` comment per test.
5. **Confirmed RED State**:
   - The test suite properly fails to compile because the builder has not yet created the necessary entities, DB configuration, or calculator class, confirming a "RED for the right reason" state.

## Next Steps for Builder
The testing gate is clear. The user may now switch roles to the Builder (using `/implement` or manual mode) to start Phase B1: Data Layer & PBAC.
