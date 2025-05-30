@echo off
REM === GP2040-CE Windows Automation Script for Switch/PS4/PS5 Remote Play with Moonlight & Pico ===
REM - Streams console video using Sunshine & HDMI capture card
REM - Forwards controller input from Moonlight client to Pico (GP2040-CE) emulating your chosen console

REM -------- USER CONFIGURATION --------
REM Set your Pico's IP address here:
set PICO_IP=192.168.1.100

REM Set your HDMI capture device. Example: video=video=USB Video or the device index (check in ffplay/OBS)
set HDMI_DEVICE=video="YOUR HDMI DEVICE NAME HERE"

REM -------- SYSTEM CHECKS --------
echo.
echo ============================================
echo   GP2040-CE + Sunshine Windows Automation
echo ============================================
echo.
echo 1. Make sure you have:
echo    - [x] Installed ViGEmBus (https://vigembus.github.io/)
echo    - [x] Sunshine installed (https://sunshineapp.dev/)
echo    - [x] Python 3.x (https://www.python.org/)
echo    - [x] pip installed for Python
echo    - [x] Moonlight client with Virtual Gamepad enabled
echo 2. Connect your Pico (with GP2040-CE) to your console's USB port.
echo 3. Use the same Pico IP in this script and in the Python script.
echo.

REM -------- CHOOSE CONSOLE TO EMULATE --------
:choose_console
echo Which console do you want your Pico/GP2040-CE to emulate?
echo [1] Nintendo Switch (Pro Controller)
echo [2] PlayStation 4 (DualShock 4)
echo [3] PlayStation 5 (DualSense)
set /p CONSOLE_CHOICE="Enter 1, 2, or 3: "
if "%CONSOLE_CHOICE%"=="1" (
    set CONSOLE_MODE=switch
) else if "%CONSOLE_CHOICE%"=="2" (
    set CONSOLE_MODE=ps4
) else if "%CONSOLE_CHOICE%"=="3" (
    set CONSOLE_MODE=ps5
) else (
    echo Invalid choice. Please enter 1, 2, or 3.
    goto choose_console
)

echo.
echo You selected: %CONSOLE_MODE%
echo.
pause

REM -------- PYTHON DEPENDENCIES --------
echo Installing Python dependencies...
pip install inputs requests

REM -------- DOWNLOAD CONTROLLER SENDER SCRIPT --------
set SCRIPT_DIR=%~dp0
set DEMO_SCRIPT=%SCRIPT_DIR%controller.py

REM Download always-latest version; replace with your own repo if you fork/customize
powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/aloy5555/tools-public/main/controller.py -OutFile '%DEMO_SCRIPT%'"

REM -------- PATCH PICO IP AND CONSOLE MODE IN SCRIPT --------
powershell -Command "(Get-Content '%DEMO_SCRIPT%') -replace \"PICO_IP = '.*'\", \"PICO_IP = '%PICO_IP%'\" | Set-Content '%DEMO_SCRIPT%'"
powershell -Command "(Get-Content '%DEMO_SCRIPT%') -replace \"CONSOLE_MODE = '.*'\", \"CONSOLE_MODE = '%CONSOLE_MODE%'\" | Set-Content '%DEMO_SCRIPT%'"

REM -------- START SUNSHINE --------
echo Starting Sunshine...
start "" "C:\Program Files\Sunshine\sunshine.exe"

REM -------- LAUNCH CONTROLLER SENDER --------
echo Starting controller-to-GP2040-CE bridge (emulating %CONSOLE_MODE%)...
start cmd /k python "%DEMO_SCRIPT%"

REM -------- INSTRUCTIONS FOR HDMI VIEWER --------
echo.
echo =========================================================
echo When setting up Sunshine:
echo   - In the Sunshine web UI, add a new "Application" entry.
echo   - Command: ffplay -fflags nobuffer -flags low_delay -framedrop -i %HDMI_DEVICE% -window_title "ConsoleStream"
echo     (You may need to install ffmpeg/ffplay for Windows: https://www.gyan.dev/ffmpeg/builds/)
echo   - Save, then launch this app from Moonlight to view your console stream.
echo.
echo Your controller input from Moonlight will be sent to the console via the Pico emulating a %CONSOLE_MODE% controller.
echo.
echo When finished, close the ffplay window and stop the Python script.
echo =========================================================
pause
