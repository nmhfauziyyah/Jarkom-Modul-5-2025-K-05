#!/bin/bash

# ==========================================================
# KONFIGURASI ELENDIL (CLIENT 200 HOST) - MODUL 5
# Subnet A6: 10.66.1.0/24
# ==========================================================

echo "Mulai konfigurasi Elendil (Client 200 Host)..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi Awal (IP Static untuk Uji Routing)
# ----------------------------------------------------------------
echo "--- 1. Misi 1: Konfigurasi IP Static Awal ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Switch 4 (A6). Elendil IP: 10.66.1.2
auto eth0
iface eth0 inet static
    address 10.66.1.2
    netmask 255.255.255.0
    gateway 10.66.1.1 # Gateway adalah Minastir (via Switch 4)
EOF

# Restart networking agar konfigurasi diterapkan
systemctl restart networking
sleep 5 # Beri jeda agar DHCP eth0 mendapat IP

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

echo -e "\n=== UJI PING KE GATEWAY (Minastir 10.66.1.1) ==="
ping -c 3 10.66.1.1

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

systemctl restart networking
sleep 5 # Beri jeda agar DHCP eth0 mendapat IP

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
echo "Pastikan eth0 mendapatkan IP 10.66.1.x dan gateway 10.66.1.1."

echo -e "\n=== UJI KONEKTIVITAS KE VILYA (DHCP Server 10.66.0.43) ==="
ping -c 3 10.66.0.43

echo -e "\n=== UJI PING KE INTERNET (8.8.8.8) ==="
ping -c 3 8.8.8.8

echo -e "\n!!! KONFIGURASI ELENDIL SELESAI !!!"