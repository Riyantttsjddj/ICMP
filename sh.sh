#!/bin/bash
set -euo pipefail

# Konfigurasi
REPO_URL="https://github.com/Riyantttsjddj/pingtunnel-2.8.git"
INSTALL_DIR="/opt/pingtunnel"
PT_BIN="/usr/local/bin/pingtunnel"
PT_KEY="12345678"

echo "[*] Update & install dependensi..."
apt update && apt install -y git unzip curl wget

echo "[*] Hapus instalasi lama jika ada..."
systemctl stop pingtunnel 2>/dev/null || true
systemctl disable pingtunnel 2>/dev/null || true
rm -rf "$INSTALL_DIR"
rm -f "$PT_BIN" /etc/systemd/system/pingtunnel.service

echo "[*] Clone repo dari GitHub..."
git clone "$REPO_URL" "$INSTALL_DIR"

echo "[*] Ekstrak binary pingtunnel (amd64)..."
cd "$INSTALL_DIR"
unzip -o pingtunnel_linux_amd64.zip

echo "[*] Pindahkan binary ke /usr/local/bin..."
mv -f pingtunnel "$PT_BIN"
chmod +x "$PT_BIN"

echo "[*] Buat service systemd..."
cat <<EOF > /etc/systemd/system/pingtunnel.service
[Unit]
Description=ICMP Tunnel Server - pingtunnel
After=network.target

[Service]
ExecStart=$PT_BIN -type server -key $PT_KEY
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Reload systemd dan mulai service..."
systemctl daemon-reload
systemctl enable pingtunnel
systemctl restart pingtunnel

IP_PUBLIC=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)
echo ""
echo "✅ Pingtunnel berhasil disetup!"
echo "🌐 IP VPS      : $IP_PUBLIC"
echo "🔑 Kunci Tunnel: $PT_KEY"
echo ""
echo "📋 Cek status  : systemctl status pingtunnel"
echo "📥 Contoh klien: ./pingtunnel -type client -l :1080 -s $IP_PUBLIC -sock5 1 -key $PT_KEY"
