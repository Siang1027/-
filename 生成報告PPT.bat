@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "PYTHON=C:\Users\samho\AppData\Local\Programs\Python\Python314\python.exe"

if not exist "%PYTHON%" (
  echo Python was not found at: %PYTHON%
  pause
  exit /b 1
)

cd /d "%PROJECT_DIR%"
"%PYTHON%" ".\Scripts\create_report_ppt.py"

if errorlevel 1 (
  echo Failed to create PPT.
  pause
  exit /b 1
)

echo PPT created under Reports.
pause
endlocal
