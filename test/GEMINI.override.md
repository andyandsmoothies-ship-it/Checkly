

## Parity Shield Governance Rule (MANDATORY)

**Rule**: You CANNOT fix a scoring bug by modifying production code alone.

**Required sequence:**
1. Open `test/scoring_test_vectors.json`
2. Add a new vector that reproduces the bug
3. Run `flutter test test/scoring_engine_test.dart` -> must be RED
4. Run `dotnet test` filtering `ScoringVerifierJsonTests` -> must be RED
5. Fix production code (`scoring_engine.dart` and/or `ScoringVerifier.cs`)
6. Both must be GREEN before the fix is considered complete

**Violation**: Adding a test ONLY in ScoringVerifierTests.cs manual section or ONLY in Dart inline is a governance violation.
