@echo off
title Wantok Services - Android Emulator
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Wantok-Emulator.ps1"
if errorlevel 1 (
    echo.
    echo The emulator start-up script reported an error.
    pause
)
