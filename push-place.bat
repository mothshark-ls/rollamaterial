@echo off
rem Pushes the place file to GitHub so Claude can read it.
rem Save in Studio first (Ctrl+S), then double-click this file.

cd /d "%~dp0"

git add feedgubbyorelse.rbxl
git diff --cached --quiet
if not errorlevel 1 (
    echo No changes to the place file. Did you press Ctrl+S in Studio?
    goto :done
)

git commit -m "Update place file"
if errorlevel 1 goto :failed

git pull --no-edit
if errorlevel 1 goto :failed

git push
if errorlevel 1 goto :failed

echo.
echo Done. The place file is on GitHub.
goto :done

:failed
echo.
echo Something went wrong. Copy the messages above and send them to Claude.

:done
echo.
pause
