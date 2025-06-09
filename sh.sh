#!/bin/bash

set -euo pipefail

# === Konfigurasi ===
PT_DIR="/opt/pingtunnel"
PT_VERSION="0.0.5"
PT_KEY="rahasia-freenet123"
PT_BINARY_URL="https://github.com/esrrhs/pingtunnel/releases/download/0.0.5/pingtunnel_linux_amd64"
PT_BINARY_NAME="pingtunnel"

# === Install dependensi ===
echo "[*] Update & install unzip curl wget..."
apt update && apt install -y curl wget unzip || {
  echo "Gagal install dependencies."
  exit 1
}

# === Bersihkan instalasi lama ===
echo "[*] Membersihkan instalasi pingtunnel sebelumnya..."
systemctl stop pingtunnel 2>/dev/null || true
systemctl disable pingtunnel 2>/dev/null || true
rm -rf "$PT_DIR"
rm -f /etc/systemd/system/pingtunnel.service

# === Setup folder baru ===
echo "[*] Membuat direktori baru di: $PT_DIR"
mkdir -p "$PT_DIR"
cd "$PT_DIR"

# === Download dan izinkan eksekusi ===
echo "[*] Download binary pingtunnel dari GitHub..."
wget -O "$PT_BINARY_NAME" "$PT_BINARY_URL" || {
  echo "Gagal download binary pingtunnel."
  exit 1
}
chmod +x "$PT_BINARY_NAME"

# === Setup systemd service ===
echo "[*] Membuat systemd service..."
cat <<EOF >/etc/systemd/system/pingtunnel.service
[Unit]
Description=ICMP Tunnel Server - pingtunnel
After=network.target

[Service]
ExecStart=$PT_DIR/$PT_BINARY_NAME -type server -key $PT_KEY
Restart=always
RestartSec=5
User=root
WorkingDirectory=$PT_DIR

[Install]
WantedBy=multi-user.target
EOF

# === Jalankan service ===
echo "[*] Mengaktifkan service pingtunnel..."
systemctl daemon-reload
systemctl enable pingtunnel
systemctl restart pingtunnel || {
  echo "❌ Gagal menjalankan pingtunnel, cek dengan: journalctl -u pingtunnel"
  exit 1
}

# === Tampilkan IP publik VPS ===
echo "[*] Mendeteksi IP publik..."
PUBLIC_IP=$(curl -s ifconfig.me || wget -qO- ifconfig.me || echo "Tidak terdeteksi")

# === Ringkasan ===
echo ""
echo "✅ Setup pingtunnel selesai!"
echo "🌐 IP VPS: $PUBLIC_IP"
echo "🔑 Key: $PT_KEY"
echo ""
echo "📌 Contoh jalankan client:"
echo "./pingtunnel -type client -s $PUBLIC_IP -l 1080 -key $PT_KEY -sockss5 1080"
echo ""
echo "🔍 Cek status: systemctl status pingtunnel"
