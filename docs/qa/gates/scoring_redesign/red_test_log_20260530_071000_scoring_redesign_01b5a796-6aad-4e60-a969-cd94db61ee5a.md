# Red Test Log: Slice 2 Backend Parser & Dispatch

## 1. Execution Summary

- **Run Timestamp**: 2026-05-30 00:07:00 UTC
- **Target Suite**: `Checkly.Api.Tests`
- **Result**: **RED (COMPILATION FAILURES)** - 25 errors detected as expected under the RED phase due to signature changes.

## 2. Compilation Errors (Proof of Red Phase)

```
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringDesignSlice2Tests.cs(189,13): error CS0117: 'Template' does not contain a definition for 'IsWeighted'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringDesignSlice2Tests.cs(238,41): error CS1061: 'Submission' does not contain a definition for 'Score'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringDesignSlice2Tests.cs(260,13): error CS0117: 'Template' does not contain a definition for 'ScoreDirection'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringDesignSlice2Tests.cs(261,13): error CS0117: 'Template' does not contain a definition for 'IsWeighted'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringDesignSlice2Tests.cs(306,32): error CS1061: 'Submission' does not contain a definition for 'Score'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(11,9): error CS8132: Cannot deconstruct a tuple of '2' elements into '3' variables.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(11,35): error CS8130: Cannot infer the type of implicitly-typed deconstruction variable 'progressive'.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(20,9): error CS8132: Cannot deconstruct a tuple of '2' elements into '3' variables.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(20,35): error CS8130: Cannot infer the type of implicitly-typed deconstruction variable 'progressive'.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(30,9): error CS8132: Cannot deconstruct a tuple of '2' elements into '3' variables.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(30,35): error CS8130: Cannot infer the type of implicitly-typed deconstruction variable 'progressive'.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(40,9): error CS8132: Cannot deconstruct a tuple of '2' elements into '3' variables.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(40,35): error CS8130: Cannot infer the type of implicitly-typed deconstruction variable 'progressive'.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(50,9): error CS8132: Cannot deconstruct a tuple of '2' elements into '3' variables.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(50,35): error CS8130: Cannot infer the type of implicitly-typed deconstruction variable 'progressive'.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(65,9): error CS8132: Cannot deconstruct a tuple of '2' elements into '3' variables.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(65,35): error CS8130: Cannot infer the type of implicitly-typed deconstruction variable 'progressive'.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(79,9): error CS8132: Cannot deconstruct a tuple of '2' elements into '3' variables.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringConfigParserTests.cs(79,35): error CS8130: Cannot infer the type of implicitly-typed deconstruction variable 'progressive'.
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringVerifierDispatchTests.cs(37,13): error CS1739: The best overload for 'Verify' does not have a parameter named 'scoreDirection'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringVerifierDispatchTests.cs(66,13): error CS1739: The best overload for 'Verify' does not have a parameter named 'scoreDirection'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringVerifierDispatchTests.cs(95,13): error CS1739: The best overload for 'Verify' does not have a parameter named 'scoreDirection'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringVerifierDispatchTests.cs(114,13): error CS1739: The best overload for 'Verify' does not have a parameter named 'scoreDirection'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringVerifierDispatchTests.cs(133,13): error CS1739: The best overload for 'Verify' does not have a parameter named 'scoreDirection'
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringVerifierDispatchTests.cs(162,13): error CS1739: The best overload for 'Verify' does not have a parameter named 'scoreDirection'
```

## 3. Analysis & Interpretation

These errors verify the TDD/ATDD Red state:
1. **ScoringConfigParser Mismatches**: Callers of the parser cannot deconstruct the new three-element tuple. This proves the compiler rejects compilation due to the missing deconstruct support.
2. **ScoringVerifierDispatch Mismatches**: Callers of `Verify()` fail because the method signature lacks `scoreDirection`.
3. **Template & Submission Properties Mismatches**: The fields `Template.IsWeighted`, `Template.ScoreDirection`, and `Submission.Score` do not yet exist on the entities.

## 4. Next Step

We are ready to transition to the **Builder (Implementation) Phase**. The tests are fully locked in and validated.
