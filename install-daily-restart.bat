@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Daily Windows Restart - Installer

REM --- Admin-Check ---
>nul 2>&1 net session
if not "%errorlevel%"=="0" (
  echo [ERROR] Bitte als Administrator ausfuehren (Rechtsklick -> Als Administrator ausfuehren).
  pause
  exit /b 1
)

set "TASK_NAME=Daily Windows Restart"
set "DEFAULT_TIME=03:30"
set "DEFAULT_DELAY=60"

echo.
echo === TAEGLICHER SERVER-NEUSTART (Task Scheduler) ===
echo Leere Eingabe = Standard.
echo.

set /p RUN_TIME=Uhrzeit HH:MM fuer den taeglichen Neustart (Standard: %DEFAULT_TIME%): 
if not defined RUN_TIME set "RUN_TIME=%DEFAULT_TIME%"

set /p DELAY_SEC=Verzoegerung in Sekunden vor Neustart (0..315360000, Standard: %DEFAULT_DELAY%): 
if not defined DELAY_SEC set "DELAY_SEC=%DEFAULT_DELAY%"

set /p FORCE=Programme erzwingen schliessen? (Y/N, Standard: Y): 
if /I not "%FORCE%"=="N" ( set "FORCE=/f" ) else ( set "FORCE=" )

set /p COMMENT=Kommentar fuer Ereignisanzeige (optional): 
if not defined COMMENT set "COMMENT=Daily scheduled restart"

echo.
echo === Zusammenfassung ===
echo Task-Name : %TASK_NAME%
echo Uhrzeit   : %RUN_TIME%
echo Delay     : %DELAY_SEC% s vor Neustart
echo Erzwingen : %FORCE%
echo Kommentar : %COMMENT%
echo.
pause

REM --- vorhandenen Task entfernen (falls exists) ---
schtasks /Query /TN "%TASK_NAME%" >nul 2>&1
if "%errorlevel%"=="0" schtasks /Delete /TN "%TASK_NAME%" /F >nul

REM --- Task anlegen (als SYSTEM, hoechste Rechte) ---
REM shutdown /r = Neustart, /t <sek>, /f = erzwingen, /c "Kommentar"
set "CMD=shutdown.exe /r /t %DELAY_SEC% %FORCE% /c "%COMMENT%""

schtasks /Create ^
  /SC DAILY ^
  /ST %RUN_TIME% ^
  /RU "SYSTEM" ^
  /RL HIGHEST ^
  /TN "%TASK_NAME%" ^
  /TR "cmd /c %CMD%" >nul

if not "%errorlevel%"=="0" (
  echo [ERROR] Konnte geplante Aufgabe nicht erstellen.
  exit /b 2
)

echo [OK] Aufgabe "%TASK_NAME%" wurde erstellt und laeuft taeglich um %RUN_TIME%.
echo.
set /p RUNNOW=Jetzt einmalig testen? (Y/N, Standard: N): 
if /I "%RUNNOW%"=="Y" (
  echo Starte Task einmalig...
  schtasks /Run /TN "%TASK_NAME%" >nul
  echo Task wurde gestartet (es kann je nach Delay %DELAY_SEC% s dauern).
) else (
  echo Alles bereit. Der Neustart erfolgt taeglich automatisch.
)
exit /b 0
