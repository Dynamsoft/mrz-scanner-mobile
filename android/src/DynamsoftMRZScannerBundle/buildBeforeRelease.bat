@echo off
setlocal

set "ROOT=%~dp0"
set "SETTINGS=%ROOT%settings.gradle"
set "MODULE_DIR=%ROOT%mrzbundlejni"

call "%ROOT%gradlew.bat" :mrzbundlejni:buildAndCopyNativeLibsRelease
if errorlevel 1 (
    echo Gradle build failed. Skip removing mrzbundlejni.
    exit /b %errorlevel%
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$settings = '%SETTINGS%';" ^
  "$moduleDir = '%MODULE_DIR%';" ^
  "if (Test-Path $settings) {" ^
  "  $raw = Get-Content -LiteralPath $settings -Raw;" ^
  "  $raw = [regex]::Replace($raw, '(?m)^\s*include\s+'':mrzbundlejni''\r?\n?', '');" ^
  "  $utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
  "  [System.IO.File]::WriteAllText($settings, $raw, $utf8NoBom);" ^
  "}" ^
  "if (Test-Path $moduleDir) {" ^
  "  Remove-Item -LiteralPath $moduleDir -Recurse -Force;" ^
  "}"

if errorlevel 1 (
    echo Cleanup failed.
    exit /b %errorlevel%
)

echo mrzbundlejni has been removed from settings.gradle and deleted from disk.
exit /b 0