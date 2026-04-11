# Scoring Module Gotchas

## ScoringVerifier.cs — CCP Section Must Be EXCLUDED, Not ZEROED

- **Problem:** When a CCP criterion has a fault, setting `sectionRatio = 0` but leaving the section's weight in `participatingWeight` produces a different weighted average than Flutter's engine. Flutter uses `continue` to skip the entire section from both numerator AND denominator.
- **Symptom:** `POST /submissions` returns 400 with "Score verification failed". Client sends `0`, server calculates a non-zero value.
- **Fix:** Use `if (ccpTriggered) continue;` before computing `sectionAfter`. This excludes the section from `sectionResults` entirely, so `participatingWeight` naturally excludes it.
- **Rule:** The server `ScoringVerifier` must be a STRICT mirror of Flutter's `ScoringEngine`. Any behavioral change in Flutter's penalty calculation MUST be ported to C# simultaneously. Use integration tests to enforce this.
