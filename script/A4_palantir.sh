#!/bin/bash

# ==========================================================
# KONFIGURASI PALANTIR (WEB SERVER 2) - MODUL 5
# Subnet A4: 10.66.0.12/30
# Misi 1: IP Static, Web Server
# Misi 2: Firewall berbasis waktu & Port Scan Prevention
# ==========================================================

echo "Mulai konfigurasi Palantir..."

# --- 1. Misi 1: Konfigurasi IP Static dan Web Server ---
echo "--- 1. Konfigurasi IP Static ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Pelargir (A4: 10.66.0.12/30). Palantir IP: 10.66.0.14
auto eth0
iface eth0 inet static
    address 10.66.0.14
    netmask 255.255.255.252
    gateway 10.66.0.13 # Gateway adalah Pelargir
EOF

# Restart networking agar konfigurasi diterapkan
systemctl restart networking
sleep 5 # Beri jeda agar DHCP eth0 mendapat IP

# Konfigurasi DNS Server (Menggunakan IP NAT/Internet Host: 192.168.122.1)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "--- 2. Misi 1: Instalasi Web Server (Apache) dan index.html ---"
apt update
apt install -y apache2 iptables
service apache2 start

# Buat index.html berisikan: "Welcome to {hostname}". (Misi 1 No. 4)
echo "<h1>Welcome to Palantir</h1>" > /var/www/html/index.html
service apache2 restart

echo "Jaringan dan Web Server selesai dikonfigurasi."
echo "----------------------------------------"


# ----------------------------------------------------------------
# B. Misi 2 No. 5 & 6: Konfigurasi Firewall Iptables
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
# Misi 2 No. 6: Pencegahan Port Scan (a, b, c)
# ----------------------------------------------------------------

# c. Catat log iptables dengan prefix "PORT_SCAN_DETECTED".
# Buat rantai (chain) baru untuk penyerang
iptables -N PORTSCAN

# Tambahkan aturan ke rantai PORTSCAN: Log, lalu DROP (memblokir semua trafik)
iptables -A PORTSCAN -m limit --limit 2/min -j LOG --log-prefix "PORT_SCAN_DETECTED: "
iptables -A PORTSCAN -j DROP

# Aturan 1: Set/Catat IP baru yang mencoba koneksi
iptables -A INPUT -m state --state NEW -m recent --set --name PORTSCAN

# Aturan 2: Jika IP mencoba > 15 koneksi baru dalam 20 detik, lompat ke rantai PORTSCAN (BLOCK)
# a. Web server harus memblokir scan port yang melebihi 15 port dalam waktu 20 detik.
# b. Penyerang yang terblokir tidak dapat melakukan ping, nc, atau curl ke Palantir.
iptables -A INPUT -p tcp -m state --state NEW -m recent --update --seconds 20 --hitcount 15 --name PORTSCAN -j PORTSCAN

# Aturan 3: Block secara absolut IP yang sudah masuk list PORTSCAN (Memastikan b. berlaku untuk semua protokol)
iptables -A INPUT -m recent --rcheck --name PORTSCAN -j DROP

# ----------------------------------------------------------------
# Misi 2 No. 5: Akses Web Server Berbasis Waktu
# ----------------------------------------------------------------

# Faksi Elf (Gilgalad & Cirdan: Subnet A5) - Boleh akses jam 07.00 - 15.00.
# Subnet A5: 10.66.0.128/25
iptables -A INPUT -p tcp --dport 80 -s 10.66.0.128/25 -m time --timestart 07:00 --timestop 15:00 -j ACCEPT

# Faksi Manusia (Elendil & Isildur: Subnet A6) - Boleh akses jam 17.00 - 23.00.
# Subnet A6: 10.66.1.0/24
iptables -A INPUT -p tcp --dport 80 -s 10.66.1.0/24 -m time --timestart 17:00 --timestop 23:00 -j ACCEPT


# ----------------------------------------------------------------
# DROP Default
# ----------------------------------------------------------------

# DROP semua yang tersisa (termasuk PING/SSH/Akses Web di luar jam/dari IP lain)
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

echo -e "\n=== KONFIRMASI ATURAN IPTABLES (TIME dan PORTSCAN) ==="
iptables -L INPUT -v -n

echo -e "\n=== UJI KONEKTIVITAS KE GATEWAY (Pelargir) ==="
ping -c 3 10.66.0.13

echo -e "\n=== UJI AKSES WEB LOKAL ==="
curl http://127.0.0.1/

echo -e "\n!!! KONFIGURASI PALANTIR SELESAI !!!"
echo "Silakan uji akses Web (curl) dan Port Scan dari Client A5 dan A6 pada waktu yang berbeda."