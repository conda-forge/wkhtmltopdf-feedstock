@echo off
setlocal EnableDelayedExpansion

:: Extract the NSIS installer using 7z
7z x "%SRC_DIR%\wkhtmltox-*.exe" -o"%SRC_DIR%\extracted" -y
if errorlevel 1 exit 1

:: Copy binaries (exe + dll) to LIBRARY_BIN
xcopy /E /Y "%SRC_DIR%\extracted\bin\*" "%LIBRARY_BIN%\"
if errorlevel 1 exit 1

:: Copy headers to LIBRARY_INC
xcopy /E /Y "%SRC_DIR%\extracted\include\*" "%LIBRARY_INC%\"
if errorlevel 1 exit 1

:: Copy import/static libraries to LIBRARY_LIB
xcopy /E /Y "%SRC_DIR%\extracted\lib\*" "%LIBRARY_LIB%\"
if errorlevel 1 exit 1
