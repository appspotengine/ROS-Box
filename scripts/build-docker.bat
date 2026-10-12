@echo off
REM 构建 ROS-Box Docker 镜像 (Windows 批处理)
set IMAGE_NAME=%1
if "%IMAGE_NAME%"=="" set IMAGE_NAME=ros-box:latest

echo ==========================================================
echo   Building ROS-Box Container Image
echo   Tag: %IMAGE_NAME%
echo ==========================================================

docker build -t %IMAGE_NAME% .

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Build completed successfully: %IMAGE_NAME%
) else (
    echo.
    echo Build failed!
)
