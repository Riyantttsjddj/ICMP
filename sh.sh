#!/bin/bash

set -e

# Konfigurasi
PT_DIR="/opt/pingtunnel"
PT_VERSION="0.0.5"
PT_KEY="riyan200324"  # Ganti sesuai keinginan
PT_BINARY_URL="https://github.com/esrrhs/pingtunnel/releases/download/${PT_VERSION}/pingtunnel_${PT_VERSION}_linux_amd64.zip"

echo "[*] Update dan install dependencies..."
apt update && apt install -y unzip curl wget

echo "[*] Hapus instalasi lama jika ada..."
systemctl stop pingtunnel 2>/dev/null || true
systemctl disable pingtunnel 2>/dev/null || true
rm -rf $PT_DIR
rm -f /etc/systemd/system/pingtunnel.service

echo "[*] Buat direktori baru: $PT_DIR"
mkdir -p $PT_DIR
cd $PT_DIR

echo "[*] Download pingtunnel versi $PT_VERSION"
wget -q --show-progress "$PT_BINARY_URL" -O pingtunnel.zip

echo "[*] Ekstrak pingtunnel..."
unzip -o pingtunnel.zip
chmod +x pingtunnel
rm pingtunnel.zip

echo "[*] Buat service systemd untuk pingtunnel..."
cat <<EOF >/etc/systemd/system/pingtunnel.service
[Unit]
Description=ICMP Tunnel Server - pingtunnel
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

echo "[*] Reload systemd dan aktifkan service pingtunnel..."
systemctl daemon-reload
systemctl enable pingtunnel
systemctl start pingtunnel

echo "[*] Mendeteksi IP publik VPS..."
PUBLIC_IP=$(curl -s ifconfig.me || wget -qO- ifconfig.me)

echo ""
echo "✅ Setup selesai! pingtunnel server berjalan."
echo "🌐 IP Publik VPS: $PUBLIC_IP"
echo "🔑 Tunnel key: $PT_KEY"
echo ""
echo "📌 Jalankan client dengan contoh:"
echo "./pingtunnel -type client -s $PUBLIC_IP -l 1080 -key $PT_KEY -sockss5 1080"
echo ""
echo "Cek status service dengan:"
echo "systemctl status pingtunnel"
