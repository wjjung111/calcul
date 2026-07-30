@echo off
rem CalcNote launcher: run the record-file helper (it opens the app window itself)
set "PS1=%~dp0server.ps1"
set "APP=%~dp0calc.html"
if exist "%PS1%" (
  where powershell >nul 2>nul
  if not errorlevel 1 (
    start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS1%"
    exit /b
  )
)
rem Fallback: open the app directly (records stay in browser storage only)
set "APPURL=file:///%APP:\=/%"
set "BROWSER=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%BROWSER%" set "BROWSER=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not exist "%BROWSER%" set "BROWSER=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if not exist "%BROWSER%" set "BROWSER=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if exist "%BROWSER%" (
  start "" "%BROWSER%" --app="%APPURL%"
) else (
  start "" "%APP%"
)
