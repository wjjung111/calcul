@echo off
rem Launch CalcNote as a standalone app window (Chrome or Edge --app mode)
set "APP=%~dp0calc.html"
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
