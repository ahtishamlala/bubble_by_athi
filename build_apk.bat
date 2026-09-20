@echo off
echo =======================================================
echo     IKRAM GAMING HUB - RELEASE BUILD AUTOMATION
echo =======================================================
echo.

echo [1/4] Cleaning project cache...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter clean failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/4] Pulling dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter pub get failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [3/4] Building Release APK for manual testing...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Release APK build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [4/4] Building Release App Bundle (.aab) for Google Play Store upload...
call flutter build appbundle --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Release App Bundle build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo =======================================================
echo     SUCCESS! BUILD COMPLETED
echo =======================================================
echo Release APK: build\app\outputs\flutter-apk\app-release.apk
echo Release AAB: build\app\outputs\bundle\release\app-release.aab
echo =======================================================
echo.
pause
