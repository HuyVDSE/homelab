#!/bin/bash

# Auto Mount NAS Script
# Kiểm tra tính khả dụng của NAS và tự động mount

# Cấu hình
NAS_IP="192.168.31.165"
SMB_SHARE="smb-share"                 # Tên SMB share
SMB_USERNAME="huyvd"                  # Username SMB
LOCAL_MOUNT_POINT="/mnt/data"         # Điểm mount local
CIFS_OPTIONS="username=${SMB_USERNAME},uid=1000,gid=1000,iocharset=utf8"
MAX_RETRY=30        # Số lần thử tối đa
RETRY_INTERVAL=10   # Khoảng thời gian giữa các lần thử (giây)
LOG_FILE="/var/log/auto-mount-nas.log"

# Hàm ghi log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Hàm kiểm tra NAS có khả dụng không
check_nas_availability() {
    # Kiểm tra ping
    if ! ping -c 1 -W 5 "$NAS_IP" > /dev/null 2>&1; then
        return 1
    fi
    
    # Kiểm tra SMB service (port 445)
    if ! nc -z -w5 "$NAS_IP" 445 > /dev/null 2>&1; then
        return 1
    fi
    
    # Kiểm tra SMB share có accessible không
    if ! smbclient -L "$NAS_IP" -U "$SMB_USERNAME%%" -N > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# Hàm kiểm tra đã mount chưa
is_mounted() {
    mount | grep -q "$LOCAL_MOUNT_POINT"
    return $?
}

# Hàm mount NAS
mount_nas() {
    # Tạo mount point nếu chưa có
    if [ ! -d "$LOCAL_MOUNT_POINT" ]; then
        mkdir -p "$LOCAL_MOUNT_POINT"
        log_message "Created mount point: $LOCAL_MOUNT_POINT"
    fi
    
    # Thực hiện mount SMB/CIFS
    if mount -t cifs -o "$CIFS_OPTIONS" "//$NAS_IP/$SMB_SHARE" "$LOCAL_MOUNT_POINT"; then
        log_message "Successfully mounted SMB: //$NAS_IP/$SMB_SHARE to $LOCAL_MOUNT_POINT"
        return 0
    else
        log_message "Failed to mount SMB: //$NAS_IP/$SMB_SHARE"
        return 1
    fi
}

# Hàm chính
main() {
    log_message "Starting auto-mount NAS script"
    
    # Kiểm tra nếu đã mount rồi
    if is_mounted; then
        log_message "NAS already mounted at $LOCAL_MOUNT_POINT"
        exit 0
    fi
    
    retry_count=0
    
    while [ $retry_count -lt $MAX_RETRY ]; do
        log_message "Attempt $((retry_count + 1))/$MAX_RETRY - Checking NAS availability..."
        
        if check_nas_availability; then
            log_message "NAS is available, attempting to mount..."
            
            if mount_nas; then
                log_message "NAS mounted successfully"
                exit 0
            else
                log_message "Mount failed, will retry..."
            fi
        else
            log_message "NAS not available yet (IP: $NAS_IP)"
        fi
        
        retry_count=$((retry_count + 1))
        
        if [ $retry_count -lt $MAX_RETRY ]; then
            log_message "Waiting $RETRY_INTERVAL seconds before next attempt..."
            sleep $RETRY_INTERVAL
        fi
    done
    
    log_message "Failed to mount SMB after $MAX_RETRY attempts"
    exit 1
}

# Chạy script
main "$@"