#!/bin/bash

# ==========================================================
# KONFIGURASI IRONHILLS (WEB SERVER 1) - MODUL 5
# Subnet A8: 10.66.0.20/30
# Misi 2: Firewall berbasis waktu (Sabtu/Minggu) & Batas koneksi
# ==========================================================

echo "Mulai konfigurasi IronHills..."

# --- 1. Misi 1: Konfigurasi IP Static dan Web Server ---
echo "--- 1. Konfigurasi IP Static ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Switch 2 (A8). IronHills IP: 10.66.0.22
auto eth0
iface eth0 inet static
    address 10.66.0.22
    netmask 255.255.255.252
    gateway 10.66.0.21 # Gateway adalah Moria
EOF
/etc/init.d/networking restart
sleep 2

# Konfigurasi DNS Server (Menggunakan IP NAT/Internet Host: 192.168.122.1)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "--- 2. Misi 1: Instalasi Web Server (Apache) dan index.html ---"
apt update
apt install -y apache2 iptables
service apache2 start

# Buat index.html berisikan: "Welcome to {hostname}". (Misi 1 No. 4)
echo "<h1>Welcome to Ironhills</h1>" > /var/www/html/index.html
service apache2 restart

echo "Jaringan dan Web Server selesai dikonfigurasi."
echo "----------------------------------------"


# ----------------------------------------------------------------
# B. Misi 2 No. 4 & 7: Konfigurasi Firewall Iptables
# ----------------------------------------------------------------
echo "--- 3. Misi 2: Konfigurasi Firewall ---"

# Reset semua aturan lama
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# 1. Izinkan Loopback dan trafik balasan yang sudah established/related
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT


# ----------------------------------------------------------------
# Misi 2 No. 7: Batas Koneksi (3 koneksi aktif per IP)
# ----------------------------------------------------------------
echo "Mengimplementasikan Batas Koneksi (Misi 2 No. 7)..."
# Buat rantai (chain) baru untuk batas koneksi
iptables -N LIMIT_CONN

# Jika koneksi dari satu IP melebihi 3, langsung DROP
iptables -A LIMIT_CONN -p tcp --dport 80 -m connlimit --connlimit-above 3 --connlimit-mask 32 -j DROP
# Izinkan koneksi di bawah batas (lompat kembali ke INPUT)
iptables -A LIMIT_CONN -j ACCEPT

# Arahkan semua koneksi TCP port 80 (Web) ke rantai LIMIT_CONN
iptables -A INPUT -p tcp --dport 80 -j LIMIT_CONN


# ----------------------------------------------------------------
# Misi 2 No. 4: Akses Web Server Berbasis Waktu (Sabtu & Minggu)
# ----------------------------------------------------------------
echo "Mengimplementasikan Akses Berbasis Waktu (Misi 2 No. 4)..."
# Faksi yang diizinkan: Durin (A10), Khamul (A11), Elendil/Isildur (A6)

# Aturan ACCEPT (HANYA pada hari Sabtu dan Minggu)
# Durin (A10: 10.66.0.64/26)
iptables -A INPUT -p tcp --dport 80 -s 10.66.0.64/26 -m time --weekdays Sat,Sun -j ACCEPT

# Khamul (A11: 10.66.0.32/29)
iptables -A INPUT -p tcp --dport 80 -s 10.66.0.32/29 -m time --weekdays Sat,Sun -j ACCEPT

# Faksi Manusia: Elendil & Isildur (A6: 10.66.1.0/24)
iptables -A INPUT -p tcp --dport 80 -s 10.66.1.0/24 -m time --weekdays Sat,Sun -j ACCEPT

# Aturan DROP (Jika hari ini Rabu - Skenario Waktu Server)
# Jika diakses pada hari selain Sabtu/Minggu (misal Rabu), trafik ini akan DROP karena tidak di-ACCEPT oleh aturan di atas.
# Kita tidak perlu membuat aturan DROP eksplisit untuk subnet tersebut di sini,
# karena trafik yang tidak di-ACCEPT akan jatuh ke DROP default di akhir.


# ----------------------------------------------------------------
# DROP Default
# ----------------------------------------------------------------

# DROP semua yang tersisa (termasuk PING/Akses Web di luar jam/dari IP lain)
iptables -A INPUT -j DROP

echo "Firewall Iptables selesai dikonfigurasi."
echo "========================================"


# ----------------------------------------------------------------
# C. Perintah Konfirmasi
# ----------------------------------------------------------------
echo "--- 4. Perintah Konfirmasi (Wajib Dijalankan) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS ==="
ip a | grep 'eth0'

echo -e "\n=== KONFIRMASI STATUS APACHE ==="
service apache2 status | grep 'Active'

echo -e "\n=== KONFIRMASI ATURAN IPTABLES (TIME dan LIMIT) ==="
iptables -L INPUT -v -n
iptables -L LIMIT_CONN -v -n

echo -e "\n=== UJI KONEKTIVITAS KE GATEWAY (Moria) ==="
ping -c 3 10.66.0.21

echo -e "\n=== UJI AKSES WEB LOKAL ==="
curl http://127.0.0.1/

echo -e "\n!!! KONFIGURASI IRONHILLS SELESAI !!!"
echo "Silakan uji akses Web (curl) dari Client A6, A10, dan A11 untuk membuktikan blokir waktu."