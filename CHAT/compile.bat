@echo off
setlocal
cd /d "%~dp0"

if not exist out mkdir out

echo Compilare...
javac -encoding UTF-8 -cp "lib/*" -d out src\*.java
if errorlevel 1 (
  echo.
  echo COMPILARE ESUATA.
  pause
  exit /b 1
)

echo.
echo OK: clasele sunt in folderul out\
pause
