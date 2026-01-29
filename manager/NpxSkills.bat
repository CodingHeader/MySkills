@echo off
REM Wrapper to run the LocalSkills installer
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-LocalSkills.ps1" %*
