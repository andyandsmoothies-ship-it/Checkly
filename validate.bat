@echo off
echo ====================================================
echo  Running Checkly Project-Wide Validation Pipeline
echo ====================================================

echo.
echo [1/4] Running Formatting and Linting on Flutter (Dart)...
cd lib
call flutter format --set-exit-if-changed .
if %errorlevel% neq 0 (
    echo [ERROR] Flutter formatting checks failed!
    exit /b %errorlevel%
)
call flutter analyze
if %errorlevel% neq 0 (
    echo [ERROR] Flutter analysis/linting failed!
    exit /b %errorlevel%
)
cd ..

echo.
echo [2/4] Running Formatting and Linting on Server (.NET)...
cd server
call dotnet format --verify-no-changes
if %errorlevel% neq 0 (
    echo [ERROR] Server formatting/style check failed!
    exit /b %errorlevel%
)
cd ..

echo.
echo [3/4] Running Backend (.NET) Integration Tests...
cd server
call rtk dotnet test
if %errorlevel% neq 0 (
    echo [ERROR] Server tests failed!
    exit /b %errorlevel%
)
cd ..

echo.
echo [4/4] Running Frontend (Flutter) Tests...
cd lib
call flutter test
if %errorlevel% neq 0 (
    echo [ERROR] Flutter tests failed!
    exit /b %errorlevel%
)
cd ..

echo.
echo ====================================================
echo  SUCCESS: All formatting, linting, and tests passed!
echo ====================================================
