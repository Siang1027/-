@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "DASHBOARD_URL=http://127.0.0.1:3838"
set "R_SCRIPT=C:\Program Files\R\R-4.6.0\bin\x64\Rscript.exe"

if not exist "%R_SCRIPT%" (
  echo Rscript was not found at: %R_SCRIPT%
  echo Please install R for Windows or update R_SCRIPT in this file.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing '%DASHBOARD_URL%' -TimeoutSec 2 -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }"

if errorlevel 1 (
  echo Starting wage and CPI dashboard...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%R_SCRIPT%' -WorkingDirectory '%PROJECT_DIR%' -ArgumentList '.\App\run_dashboard.R' -RedirectStandardOutput '%PROJECT_DIR%shiny.out.log' -RedirectStandardError '%PROJECT_DIR%shiny.err.log' -WindowStyle Hidden"
  timeout /t 4 /nobreak >nul
) else (
  echo Dashboard is already running.
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing '%DASHBOARD_URL%' -TimeoutSec 5 -ErrorAction Stop | Out-Null; Start-Process '%DASHBOARD_URL%'; exit 0 } catch { exit 1 }"

if errorlevel 1 (
  echo Dashboard failed to start. Review shiny.err.log for details.
  pause
  exit /b 1
)

echo Opened: %DASHBOARD_URL%
endlocal
