# Tailscale Mesh VPN Installation Scripts

Scripts tự động cài đặt và kết nối Tailscale cho Linux và Windows. Các script này có thể chạy trực tiếp từ GitHub URL thông qua one-liner.

## Tính năng

- Tự động phát hiện và cài đặt Tailscale client nếu chưa có
- Hỗ trợ nhiều Linux distributions (Ubuntu/Debian, RHEL/CentOS/Fedora, Arch Linux)
- Tự động enable service để khởi động khi reboot
- Kết nối tự động với Tailscale auth key
- Xử lý lỗi và logging rõ ràng

## Yêu cầu

### Linux
- Quyền root hoặc sudo
- Hỗ trợ các distribution: Ubuntu, Debian, RHEL, CentOS, Fedora, Rocky Linux, AlmaLinux, Arch Linux

### Windows
- Quyền Administrator
- PowerShell 5.1 hoặc cao hơn
- Windows 10/11 hoặc Windows Server

## Cài đặt Auth Key

**Quan trọng**: Trước khi sử dụng, bạn cần thay thế `YOUR_AUTH_KEY_HERE` trong các script bằng auth key thực tế của bạn.

1. Tạo auth key từ [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Mở file script tương ứng
3. Tìm và thay thế `YOUR_AUTH_KEY_HERE` bằng auth key của bạn

## Sử dụng

### Linux

Chạy script trực tiếp từ GitHub (sau khi đã cập nhật auth key và push lên GitHub):

```bash
curl -LsSf https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install-tailscale.sh | sh
```

Hoặc chạy local:

```bash
chmod +x install-tailscale.sh
sudo ./install-tailscale.sh
```

### Windows

Chạy script trực tiếp từ GitHub (sau khi đã cập nhật auth key và push lên GitHub):

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install-tailscale.ps1 | iex
```

Hoặc chạy local (với quyền Administrator):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\install-tailscale.ps1
```

## Chi tiết Scripts

### `install-tailscale.sh` (Linux)

Script bash thực hiện các bước sau:

1. Kiểm tra quyền root/sudo
2. Phát hiện Linux distribution
3. Kiểm tra Tailscale đã cài đặt chưa
4. Cài đặt Tailscale nếu chưa có (sử dụng official install script)
5. Enable `tailscaled` service để tự động khởi động khi reboot
6. Start `tailscaled` service
7. Kết nối với Tailscale sử dụng auth key
8. Hiển thị trạng thái kết nối

**Hỗ trợ package managers:**
- Ubuntu/Debian: `apt`
- RHEL/CentOS/Fedora: `yum` hoặc `dnf`
- Arch Linux: `pacman`

### `install-tailscale.ps1` (Windows)

Script PowerShell thực hiện các bước sau:

1. Kiểm tra PowerShell version
2. Kiểm tra quyền Administrator
3. Kiểm tra Tailscale đã cài đặt chưa
4. Cài đặt Tailscale nếu chưa có:
   - Ưu tiên sử dụng `winget` (Windows 10+)
   - Fallback: Download installer từ tailscale.com
5. Đảm bảo Tailscale service được enable và running
6. Kết nối với Tailscale sử dụng auth key
7. Hiển thị trạng thái kết nối

## Bảo mật

**Lưu ý quan trọng về bảo mật:**

- Hiện tại auth key được hardcode trong script (placeholder)
- **Không commit auth key thực tế lên GitHub public repository**
- Trong tương lai sẽ có giải pháp bảo mật tốt hơn (env variables, secure key distribution)

## Troubleshooting

### Linux

**Lỗi: "This script must be run as root or with sudo"**
- Chạy script với `sudo`

**Lỗi: "Unsupported distribution"**
- Script hiện hỗ trợ Ubuntu/Debian, RHEL/CentOS/Fedora, Arch Linux
- Với distro khác, cài đặt Tailscale thủ công từ [tailscale.com/download](https://tailscale.com/download)

**Service không khởi động:**
```bash
sudo systemctl status tailscaled
sudo journalctl -u tailscaled -n 50
```

### Windows

**Lỗi: "This script must be run as Administrator"**
- Click chuột phải PowerShell và chọn "Run as Administrator"

**Lỗi: "Execution policy"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Tailscale không kết nối:**
- Kiểm tra service: `Get-Service Tailscale`
- Xem logs: Event Viewer > Windows Logs > Application

## Cấu trúc Project

```
tailscale_meshvpn/
├── install-tailscale.sh      # Linux installation script
├── install-tailscale.ps1     # Windows installation script
├── README.md                 # This file
└── ...
```

## License

MIT

## Liên kết

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale Admin Console](https://login.tailscale.com/admin)
- [Create Auth Keys](https://login.tailscale.com/admin/settings/keys)
