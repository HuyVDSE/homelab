@echo off
REM Kiểm tra xem VPN có kết nối chưa
REM Đảm bảo bạn thay đổi tên adapter nếu khác

setlocal

REM Tên adapter VPN có thể khác, bạn dùng 'ipconfig' để kiểm tra chính xác
set VPN_INTERFACE_NAME=mongo_prod

REM Đặt IP đích và gateway
set DEST_IPS=172.168.4.5 172.168.4.111 172.168.4.112
set GATEWAY=172.30.11.64

REM Kiểm tra kết nối VPN (nếu chưa kết nối thì không làm gì)
ipconfig | findstr /I %VPN_INTERFACE_NAME% >nul
if errorlevel 1 (
    echo VPN %VPN_INTERFACE_NAME% not connected. Exiting...
    exit /b 1
)

REM === Thêm route cho từng IP ===
for %%D in (%DEST_IPS%) do (
    echo Adding route for %%D ...
    route add %%D mask 255.255.255.255 %GATEWAY% metric 1
)

echo Route added successfully.
endlocal
