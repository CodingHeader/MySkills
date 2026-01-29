@echo off
echo Syncing to GitHub...
cd /d "%~dp0.."
git pull
git add .
git commit -m "Update skills and manager scripts"
git push
echo Sync complete.
pause
