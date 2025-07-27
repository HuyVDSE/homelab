# Auto Mount SMB/CIFS Script

Script tự động mount SMB share từ OpenMediaVault NAS khi VM boot, với health check và retry logic.

## 🎯 Mục đích

Giải quyết vấn đề VM lab không thể mount SMB share tự động khi Proxmox reboot vì VM NAS khởi động chậm hơn VM lab.

## 📋 Yêu cầu hệ thống

### Packages cần thiết:
```bash
sudo apt update
sudo apt install cifs-utils smbclient netcat-openbsd -y
```

### Thông tin cấu hình:
- **NAS IP**: `192.168.31.165`
- **SMB Share**: `smb-share`
- **Username**: `huyvd`
- **Mount Point**: `/mnt/data`

## 🔧 Cài đặt

### 1. Tạo credentials file (bảo mật)
```bash
sudo nano /etc/cifs-credentials
```
Nội dung:
```
username=huyvd
password=your_actual_password
domain=workgroup
```

Bảo mật file:
```bash
sudo chmod 600 /etc/cifs-credentials
sudo chown root:root /etc/cifs-credentials
```

### 2. Copy script
```bash
sudo cp auto-mount-smb.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/auto-mount-smb.sh
```

### 3. Tạo systemd service
```bash
sudo cp auto-mount-smb.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable auto-mount-smb.service
```

## ✅ Testing Checklist

### Pre-flight checks:
- [ ] Packages đã cài đặt: `cifs-utils`, `smbclient`, `netcat-openbsd`
- [ ] Credentials file tồn tại: `/etc/cifs-credentials`
- [ ] Credentials file có permissions đúng: `600`
- [ ] Script có executable permission: `/usr/local/bin/auto-mount-smb.sh`
- [ ] Mount point tồn tại hoặc có thể tạo: `/mnt/data`

### Manual testing:
```bash
# 1. Test script thủ công
sudo /usr/local/bin/auto-mount-smb.sh

# 2. Kiểm tra mount thành công
mount | grep cifs
df -h | grep /mnt/data

# 3. Test unmount
sudo umount /mnt/data

# 4. Kiểm tra log
tail -f /var/log/auto-mount-smb.log
```

### Service testing:
```bash
# 1. Service syntax validation
sudo systemd-analyze verify /etc/systemd/system/auto-mount-smb.service

# 2. Service enabled check
sudo systemctl is-enabled auto-mount-smb.service

# 3. Manual service start
sudo systemctl start auto-mount-smb.service

# 4. Service status
sudo systemctl status auto-mount-smb.service

# 5. Service logs
journalctl -u auto-mount-smb.service --no-pager
```

### Network connectivity testing:
```bash
# 1. Ping NAS
ping -c 3 192.168.31.165

# 2. SMB port check
nc -z -w5 192.168.31.165 445

# 3. SMB shares list
smbclient -L 192.168.31.165 -A /etc/cifs-credentials

# 4. Manual mount test
sudo mount -t cifs -o credentials=/etc/cifs-credentials,uid=1000,gid=1000 //192.168.31.165/smb-share /mnt/data
```

### Boot testing:
- [ ] Service enabled: `systemctl is-enabled auto-mount-smb.service`
- [ ] Reboot VM và kiểm tra tự động mount
- [ ] Kiểm tra logs sau reboot: `journalctl -u auto-mount-smb.service`
- [ ] Verify mount persist: `mount | grep cifs`

## 🔍 Troubleshooting

### Common Issues:

#### 1. **Service không start**
```bash
# Check service status
sudo systemctl status auto-mount-smb.service -l

# Check script permissions
ls -la /usr/local/bin/auto-mount-smb.sh

# Test script manually
sudo /usr/local/bin/auto-mount-smb.sh
```

#### 2. **Mount failed**
```bash
# Check network connectivity
ping 192.168.31.165
nc -z 192.168.31.165 445

# Check credentials
sudo cat /etc/cifs-credentials
ls -la /etc/cifs-credentials

# Test SMB connection
smbclient -L 192.168.31.165 -A /etc/cifs-credentials
```

#### 3. **Permission denied**
```bash
# Check mount point ownership
ls -la /mnt/data
sudo chown $USER:$USER /mnt/data

# Check CIFS options
# Add to script: file_mode=0777,dir_mode=0777
```

#### 4. **Service lỗi "Assignment outside of section"**
```bash
# Recreate service file
sudo rm /etc/systemd/system/auto-mount-smb.service
# Copy lại service file
sudo systemctl daemon-reload
```

### Log Files:
- **Script log**: `/var/log/auto-mount-smb.log`
- **SystemD log**: `journalctl -u auto-mount-smb.service`
- **System log**: `/var/log/syslog`

## 📝 Configuration

### Script variables cần điều chỉnh:
```bash
NAS_IP="192.168.31.165"                    # IP của NAS
SMB_SHARE="smb-share"                       # Tên SMB share
LOCAL_MOUNT_POINT="/mnt/data"               # Mount point trên VM
CREDENTIALS_FILE="/etc/cifs-credentials"    # File chứa credentials
MAX_RETRY=30                                # Số lần thử tối đa
RETRY_INTERVAL=10                           # Thời gian chờ giữa các lần thử
```

### CIFS Mount Options:
```bash
# Basic options
credentials=/etc/cifs-credentials,uid=1000,gid=1000

# With file permissions
credentials=/etc/cifs-credentials,uid=1000,gid=1000,file_mode=0777,dir_mode=0777

# With SMB version
credentials=/etc/cifs-credentials,uid=1000,gid=1000,vers=3.0

# With charset
credentials=/etc/cifs-credentials,uid=1000,gid=1000,iocharset=utf8
```

## 🚀 Usage

### Start/Stop service:
```bash
sudo systemctl start auto-mount-smb.service
sudo systemctl stop auto-mount-smb.service
sudo systemctl restart auto-mount-smb.service
```

### View logs:
```bash
# Script logs
tail -f /var/log/auto-mount-smb.log

# Service logs
journalctl -u auto-mount-smb.service -f

# All logs since boot
journalctl -u auto-mount-smb.service --since "today"
```

### Manual mount/unmount:
```bash
# Manual mount
sudo /usr/local/bin/auto-mount-smb.sh

# Unmount
sudo umount /mnt/data

# Force unmount if busy
sudo umount -fl /mnt/data
```

## 📂 File Structure

```
/usr/local/bin/
└── auto-mount-smb.sh              # Main script

/etc/systemd/system/
└── auto-mount-smb.service         # SystemD service

/etc/
└── cifs-credentials               # SMB credentials (secure)

/var/log/
└── auto-mount-smb.log            # Script logs

/mnt/data/
└── (SMB share content)           # Mount point
```

## 🔒 Security Notes

- Credentials file có permission `600` (chỉ root đọc được)
- Script chạy với root privileges
- Log file có thể chứa debug info, cần review định kỳ
- Nên sử dụng strong password cho SMB account

## 📈 Monitoring

### Health check commands:
```bash
# Service status
systemctl is-active auto-mount-smb.service

# Mount status
mount | grep cifs || echo "Not mounted"

# Last mount attempt
tail -5 /var/log/auto-mount-smb.log

# Disk usage
df -h /mnt/data
```

### Log rotation setup:
```bash
sudo nano /etc/logrotate.d/auto-mount-smb
```
Content:
```
/var/log/auto-mount-smb.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
```

---

**Author**: HuyVD
**Version**: 1.0  
**Last Update**: July 2025