#!/bin/bash

# Konfigurasi
PT_VERSION="0.0.5"
PT_BINARY_URL="https://github.com/esrrhs/pingtunnel/releases/download/${PT_VERSION}/pingtunnel_${PT_VERSION}_linux_amd64.zip"
PT_DIR="/opt/pingtunnel"
PT_KEY="rahasiatunnel123"  # Ganti sesuai keinginan

echo "[+] Memasang dependensi..."
apt update && apt install -y unzip curl wget

echo "[+] Membuat direktori: $PT_DIR"
mkdir -p $PT_DIR && cd $PT_DIR

echo "[+] Mengunduh pingtunnel..."
curl -L -o pt.zip "$PT_BINARY_URL"

echo "[+] Mengekstrak..."
unzip -o pt.zip
chmod +x pingtunnel
rm pt.zip

echo "[+] Membuat layanan systemd..."
cat > /etc/systemd/system/pingtunnel.service <<EOF
[Unit]
Description=ICMP Tunnel Server - pingtunnel
After=network.target

[Service]
ExecStart=$PT_DIR/pingtunnel -type server -key $PT_KEY
Restart=always
RestartSec=3
User=root
WorkingDirectory=$PT_DIR

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Mengaktifkan layanan..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable pingtunnel
systemctl start pingtunnel

# Deteksi IP publik VPS
echo "[+] Mendeteksi IP publik VPS..."
PUBLIC_IP=$(curl -s ifconfig.me || wget -qO- ifconfig.me)

echo ""
echo "✅ Sukses! ICMP Tunnel Server telah berjalan."
echo "🔑 Kunci Tunnel: $PT_KEY"
echo "🌐 IP Publik VPS: $PUBLIC_IP"
echo ""
echo "📌 Gunakan IP dan kunci ini di sisi client Android:"
echo "Contoh:"
echo "./pingtunnel -type client -s $PUBLIC_IP -l 1080 -key $PT_KEY -sockss5 1080"
echo ""
echo "📡 Lihat status layanan dengan:"
echo "sudo systemctl status pingtunnel -n 20"
