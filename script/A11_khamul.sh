#!/bin/bash

# ==========================================================
# KONFIGURASI KHAMUL (CLIENT 5 HOST) - MODUL 5
# Subnet A11: 10.66.0.32/29
# Misi 2 No. 8: Redirect traffic Vilya -> IronHills
# Misi 3 No. 1: Blokir semua lalu lintas (Isolasi)
# ==========================================================

echo "Mulai konfigurasi Khamul..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static dan Forwarding
# ----------------------------------------------------------------
echo "--- 1. Konfigurasi IP Static Awal ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Switch 3 (A11). Khamul IP: 10.66.0.34
auto eth0
iface eth0 inet static
    address 10.66.0.34
    netmask 255.255.255.248
    gateway 10.66.0.33 # Gateway adalah Wilderland
EOF
/etc/init.d/networking restart
sleep 2

# Konfigurasi DNS Server
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Pasang IPTABLES dan aktifkan IP Forwarding
apt update
apt install -y iptables
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "IP Configuration dan Forwarding selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# B. Misi 2 No. 8: Redirect Trafik Vilya -> IronHills (Sihir Hitam)
# ----------------------------------------------------------------
echo "--- 2. Misi 2: Konfigurasi Redirect (DNAT/PREROUTING) ---"

# Reset aturan Iptables NAT/Filter
iptables -t nat -F
iptables -F
iptables -X

# Vilya (DHCP Server) IP: 10.66.0.43
# IronHills (Web Server 1) IP: 10.66.0.22
# Khamul (Client) IP: 10.66.0.34 (Target Awal)

# 1. Aturan DNAT di PREROUTING (membelokkan tujuan)
# Source (Vilya) ke Destinasi (Khamul), belokkan Destinasi ke IronHills.
iptables -t nat -A PREROUTING -s 10.66.0.43 -d 10.66.0.34 -j DNAT --to-destination 10.66.0.22

# 2. Aturan FORWARD untuk mengizinkan paket yang sudah di-DNAT lewat (State NEW)
iptables -A FORWARD -s 10.66.0.43 -d 10.66.0.22 -j ACCEPT

# 3. Aturan FORWARD untuk mengizinkan balasan dari IronHills
iptables -A FORWARD -s 10.66.0.22 -d 10.66.0.43 -j ACCEPT

echo "Trafik Redirect (Sihir Hitam) selesai dikonfigurasi."
echo "----------------------------------------"


# ----------------------------------------------------------------
# C. Misi 3 No. 1: Isolasi Sang Nazgûl (Blokir Total)
# ----------------------------------------------------------------
echo "--- 3. Misi 3: Isolasi Sang Nazgûl (Blokir Total) ---"

# Set default policy ke ACCEPT dulu untuk menghindari pemblokiran sebelum aturan dibuat
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 1. Izinkan Loopback (penting agar OS stabil)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# 2. Blokir semua lalu lintas masuk ke Khamul
iptables -A INPUT -j DROP

# 3. Blokir semua lalu lintas keluar dari Khamul
iptables -A OUTPUT -j DROP

echo "Isolasi Khamul selesai. Khamul sekarang terblokir total."
echo "----------------------------------------"


# ----------------------------------------------------------------
# D. Perintah Konfirmasi
# ----------------------------------------------------------------
echo "--- 4. Perintah Konfirmasi (Wajib Dijalankan) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS STATIC ==="
ip a | grep 'eth0'

echo -e "\n=== KONFIRMASI ATURAN IPTABLES (NAT & FORWARD) ==="
iptables -t nat -L PREROUTING -v -n
iptables -L FORWARD -v -n

echo -e "\n=== KONFIRMASI ISOLASI (INPUT & OUTPUT) ==="
iptables -L INPUT -v -n
iptables -L OUTPUT -v -n

echo -e "\n=== UJI REDIRECT (Misi 2 No. 8) ==="
echo "Perhatian: Uji koneksi normal (ping/curl) ke/dari Khamul PASTI GAGAL karena Misi 3 aktif."
echo "Uji Redirection harus dilakukan dengan nc dari Vilya:"
echo "# Jalankan di Vilya:"
nc 10.66.0.34 80
echo "# Seharusnya terhubung ke IronHills (10.66.0.22), bukan ke Khamul."

echo -e "\n!!! KONFIGURASI KHAMUL SELESAI !!!"