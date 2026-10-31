@echo off
REM Khoi dong ung dung tuyen dung (MIS3047 - Nhom 8)
REM Khong can cai dat them runtime: chi can Windows + PowerShell 5.1

cd /d "%~dp0.."
echo Dang khoi dong may chu tai http://localhost:8090/ ...
start "" "http://localhost:8090/"
powershell -NoProfile -ExecutionPolicy Bypass -File "app\server.ps1" -Port 8090
