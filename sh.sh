#!/bin/bash

# === Konfigurasi Dasar ===
PT_VERSION="2.8"
PT_KEY="rahasia-freenet123"
PT_DIR="/opt/pingtunnel"
PT_BINARY="pingtunnel"
PT_ZIP="pingtunnel_linux64.zip"
PT_URL="https://github.com/esrrhs/pingtunnel/releases/download/${PT_VERSION}/${PT_ZIP}"

# === Update dan Install dependensi ===
echo "[*] Update sistem dan install unzip, wget, curl..."
apt update && apt install -y unzip wget curl || {
    echo "[!] Gagal install dependensi."; exit 1;
}

# === Bersihkan Instalasi Lama ===
echo "[*] Membersihkan instalasi pingtunnel sebelumnya..."
systemctl stop pingtunnel 2>/dev/null || true
systemctl disable pingtunnel 2>/dev/null || true
rm -rf "$PT_DIR"
rm -f /etc/systemd/system/pingtunnel.service

# === Buat Folder Instalasi ===
echo "[*] Membuat direktori instalasi: $PT_DIR"
mkdir -p "$PT_DIR"
cd "$PT_DIR"

# === Download & Ekstrak Binary ===
echo "[*] Mengunduh pingtunnel dari GitHub..."
wget -q --show-progress "$PT_URL" -O "$PT_ZIP" || {
    echo "[!] Gagal mengunduh pingtunnel."; exit 1;
}

echo "[*] Mengekstrak file..."
unzip -o "$PT_ZIP"
chmod +x "$PT_BINARY"
rm -f "$PT_ZIP"

# === Setup Systemd Service ===
echo "[*] Membuat service pingtunnel..."
cat <<EOF > /etc/systemd/system/pingtunnel.service
[Unit]
Description=ICMP Tunnel Server - pingtunnel
After=network.target

[Service]
ExecStart=$PT_DIR/$PT_BINARY -type server -key $PT_KEY
Restart=always
RestartSec=5
User=root
WorkingDirectory=$PT_DIR

[Install]
WantedBy=multi-user.target
EOF

# === Reload Systemd dan Mulai Service ===
echo "[*] Mengaktifkan service pingtunnel..."
systemctl daemon-reload
systemctl enable pingtunnel
systemctl restart pingtunnel || {
    echo "[!] Gagal menjalankan pingtunnel. Cek: journalctl -u pingtunnel"; exit 1;
}

# === Deteksi IP Publik ===
PUBLIC_IP=$(curl -s ifconfig.me || wget -qO- ifconfig.me)
echo ""
echo "✅ pingtunnel berhasil dijalankan!"
echo "🌐 IP VPS     : $PUBLIC_IP"
echo "🔑 Key Tunnel : $PT_KEY"
echo ""
echo "📌 Contoh client command:"
echo "./pingtunnel -type client -s $PUBLIC_IP -l 1080 -key $PT_KEY -sock5 1"
echo ""
echo "📋 Cek status service: systemctl status pingtunnel"
