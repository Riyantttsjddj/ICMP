#!/bin/bash
set -euo pipefail

# > Konfigurasi
PT_DIR="/opt/pingtunnel"
PT_KEY="rahasia-freenet123"
GIT_URL="https://github.com/esrrhs/pingtunnel.git"

# 1. Install dependency + Go
apt update
apt install -y git golang unzip wget curl

# 2. Cleanup old install
systemctl stop pingtunnel 2>/dev/null || true
systemctl disable pingtunnel 2>/dev/null || true
rm -rf "$PT_DIR"
rm -f /etc/systemd/system/pingtunnel.service

# 3. Clone repo terbaru & build
mkdir -p "$PT_DIR"
git clone "$GIT_URL" "$PT_DIR"
cd "$PT_DIR"
go build -o pingtunnel .  # build binary

# 4. Setup systemd service
cat <<EOF >/etc/systemd/system/pingtunnel.service
[Unit]
Description=ICMP Tunnel Server - pingtunnel (built from source)
After=network.target

[Service]
ExecStart=$PT_DIR/pingtunnel -type server -key $PT_KEY
Restart=always
RestartSec=5
User=root
WorkingDirectory=$PT_DIR

[Install]
WantedBy=multi-user.target
EOF

# 5. Enable service
systemctl daemon-reload
systemctl enable pingtunnel
systemctl restart pingtunnel

# 6. Tampilkan IP publik & instruksi client
PUBLIC_IP=$(curl -s ifconfig.me || echo "IP TIDAK TERDETEKSI")
echo ""
echo "✅ PingTunnel (source) berhasil berjalan!"
echo "🌐 IP VPS     : $PUBLIC_IP"
echo "🔑 Key Tunnel : $PT_KEY"
echo ""
echo "📌 Jalankan client seperti ini:"
echo "./pingtunnel -type client -s $PUBLIC_IP -l 1080 -key $PT_KEY -sock5 1"
echo ""
echo "📋 Cek status dengan: systemctl status pingtunnel"
