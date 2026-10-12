@echo off
REM 打包 ROS-Box 镜像为 RouterOS 离线导入专用的 .tar 文件
set ARCH=%1
if "%ARCH%"=="" set ARCH=amd64

echo ==========================================================
echo   Exporting ROS-Box Container to RouterOS .tar
echo   Architecture: %ARCH% (amd64 / arm64)
echo ==========================================================

if "%ARCH%"=="amd64" (
    echo [+] Building and exporting linux/amd64...
    docker buildx build --platform linux/amd64 -t ros-box:amd64 --output type=docker,dest=ROS-Box-amd64.tar .
) else if "%ARCH%"=="arm64" (
    echo [+] Building and exporting linux/arm64...
    docker buildx build --platform linux/arm64 -t ros-box:arm64 --output type=docker,dest=ROS-Box-arm64.tar .
) else if "%ARCH%"=="all" (
    echo [+] Building and exporting both amd64 and arm64...
    docker buildx build --platform linux/amd64 -t ros-box:amd64 --output type=docker,dest=ROS-Box-amd64.tar .
    docker buildx build --platform linux/arm64 -t ros-box:arm64 --output type=docker,dest=ROS-Box-arm64.tar .
) else (
    echo [!] Unknown architecture: %ARCH%. Please specify amd64, arm64 or all.
    exit /b 1
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [OK] Export succeeded!
    echo Upload the generated .tar file to your RouterOS storage via WinBox Files!
) else (
    echo.
    echo [ERROR] Export failed!
)
