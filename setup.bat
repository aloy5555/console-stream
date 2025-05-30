@echo off
:: Install Arduino IDE
echo Installing Arduino IDE...
start /wait https://downloads.arduino.cc/arduino-1.8.19-windows.exe

:: Install ESP32 Board Support
echo Installing ESP32 Board Support...
start /wait https://dl.espressif.com/dl/package_esp32_index.json

:: Install Bluepad32 Library
echo Installing Bluepad32 Library...
start /wait https://github.com/ricardoquesada/bluepad32/releases/download/v3.7.0/bluepad32-3.7.0.zip

:: Install Sunshine
echo Installing Sunshine...
start /wait https://github.com/LizardByte/Sunshine/releases/download/v0.15.0/Sunshine-0.15.0-Setup.exe

:: Configure Sunshine
echo Configuring Sunshine...
start /wait "" "C:\Program Files\Sunshine\Sunshine.exe" --configure

:: Upload ESP32 Firmware
echo Uploading ESP32 Firmware...
start /wait "" "C:\Program Files\Arduino\arduino.exe" --upload "C:\path\to\your\firmware\Bluepad32.ino"

:: Done
echo Setup Complete!
pause
