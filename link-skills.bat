@echo off
setlocal EnableExtensions

set "SOURCE_ROOT=%~1"
if not defined SOURCE_ROOT set "SOURCE_ROOT=%CD%"

if not defined TARGET_DIR_1 set "TARGET_DIR_1=%USERPROFILE%\.codex\skills"
if not defined TARGET_DIR_2 set "TARGET_DIR_2=%USERPROFILE%\.claude\skills"
if not defined TARGET_DIR_3 set "TARGET_DIR_3=%USERPROFILE%\.gemini\skills"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0link-skills.ps1" -SourceRoot "%SOURCE_ROOT%"
exit /b %ERRORLEVEL%
