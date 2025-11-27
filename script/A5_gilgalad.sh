#!/bin/bash

# ==========================================================
# KONFIGURASI GILGALAD (CLIENT 100 HOST) - MODUL 5
# Subnet A5: 10.66.0.128/25
# ==========================================================

echo "Mulai konfigurasi Gilgalad (Client 100 Host)..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi Awal (IP Static untuk Uji Routing)
# ----------------------------------------------------------------
echo "--- 1. Misi 1: Konfigurasi IP Static Awal ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Switch 5 (A5). Gilgalad IP: 10.66.0.131
auto eth0
iface eth0 inet static
    address 10.66.0.131
    netmask 255.255.255.128
    gateway 10.66.0.129 # Gateway adalah AnduinBanks
EOF
/etc/init.d/networking restart
sleep 2

# Konfigurasi DNS Server (Menggunakan IP NAT/Internet Host: 192.168.122.1)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "Konfigurasi IP Static Awal selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# B. Konfirmasi Routing (Setelah semua Router dikonfigurasi IP Static)
# ----------------------------------------------------------------
echo "--- 2. Konfirmasi Routing Awal (IP Static) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS STATIC ==="
ip a | grep 'eth0'

echo -e "\n=== UJI PING KE GATEWAY (AnduinBanks 10.66.0.129) ==="
ping -c 3 10.66.0.129

echo -e "\n=== UJI PING LINTAS JARINGAN (Contoh ke Osgiliath 10.66.0.1) ==="
ping -c 3 10.66.0.1

echo -e "\n=== UJI PING KE INTERNET (Contoh ke 8.8.8.8) ==="
ping -c 3 8.8.8.8

echo "Pengujian Routing Awal selesai. Lanjutkan ke DHCP."
echo "========================================"


# ----------------------------------------------------------------
# C. Misi 1 No. 4: Konfigurasi Final (Mengubah ke DHCP)
# ----------------------------------------------------------------
echo "--- 3. Misi 1: Konfigurasi Final (Ubah ke DHCP) ---"

# Mengubah /etc/network/interfaces ke DHCP
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

## Ganti ke DHCP
auto eth0
iface eth0 inet dhcp
EOF

/etc/init.d/networking restart

# Menjalankan dhclient secara eksplisit untuk mempercepat proses mendapatkan IP baru
echo "Meminta IP Address baru melalui DHCP..."
dhclient -v

echo "Konfigurasi DHCP selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# D. Perintah Konfirmasi Final (DHCP)
# ----------------------------------------------------------------
echo "--- 4. Konfirmasi Final (DHCP) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS FINAL (DHCP) ==="
ip a | grep 'eth0'
echo "Pastikan eth0 mendapatkan IP 10.66.0.130 ke atas dan gateway 10.66.0.129."

echo -e "\n=== UJI KONEKTIVITAS KE VILYA (DHCP Server 10.66.0.43) ==="
ping -c 3 10.66.0.43

echo -e "\n=== UJI PING KE INTERNET (8.8.8.8) ==="
ping -c 3 8.8.8.8

echo -e "\n!!! KONFIGURASI GILGALAD SELESAI !!!"